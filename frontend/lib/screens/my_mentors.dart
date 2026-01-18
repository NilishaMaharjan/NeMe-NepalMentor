import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'conf_ip.dart';

class MyMentorsPage extends StatefulWidget {
  const MyMentorsPage({Key? key}) : super(key: key);

  @override
  MyMentorsPageState createState() => MyMentorsPageState();
}

class MyMentorsPageState extends State<MyMentorsPage> {
  List<dynamic> mentors = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAcceptedMentors();
  }

  // Fetch accepted mentor IDs for the current mentee
  Future<List<String>> fetchAcceptedMentorIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) return [];

    final url = '$baseUrl/api/requests/mentee?userId=$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200 || response.statusCode == 404) {
      List<dynamic> requests =
          response.statusCode == 200 ? json.decode(response.body) : [];
      List<String> acceptedMentorIds = [];
      for (var req in requests) {
        if (req['status'] == 'accepted') {
          // Either mentor is an object with _id or just the id
          String mentorId = req['mentor']?['_id'] ?? req['mentor'];
          acceptedMentorIds.add(mentorId);
        }
      }
      return acceptedMentorIds.toSet().toList();
    } else {
      print("Error fetching mentee requests: ${response.body}");
      return [];
    }
  }

  // Fetch mentors and then filter to only those with accepted requests.
  Future<void> fetchAcceptedMentors() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<String> acceptedMentorIds = await fetchAcceptedMentorIds();
      if (acceptedMentorIds.isEmpty) {
        setState(() {
          mentors = [];
          isLoading = false;
        });
        return;
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String category = prefs.getString('category') ?? 'defaultCategory';

      final url = Uri.http(
          '$serverIP:$serverPort', '/api/mentors', {'category': category});
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Filter mentors to only those with accepted IDs.
        List<dynamic> filteredMentors = data.where((mentor) {
          String mentorId = mentor['user']?['_id'] ?? mentor['_id'];
          return acceptedMentorIds.contains(mentorId);
        }).toList();

        // For each mentor, compute review data and fetch availability for starting price.
        for (var mentor in filteredMentors) {
          String mentorId = mentor['user']?['_id'] ?? mentor['_id'];
          Map<String, dynamic> reviewData = await computeReviewData(mentorId);
          mentor['rating'] =
              (reviewData['avgRating'] as double).toStringAsFixed(1);
          mentor['reviewsCount'] = reviewData['reviewsCount'].toString();

          // Fetch availability to get the starting price
          try {
            final availabilityUri = Uri.http(
                '$serverIP:$serverPort', '/api/availability/$mentorId');
            final availabilityResponse = await http.get(availabilityUri);
            if (availabilityResponse.statusCode == 200) {
              final availabilityData = json.decode(availabilityResponse.body);
              if (availabilityData is Map<String, dynamic> &&
                  availabilityData.containsKey('slots') &&
                  availabilityData['slots'] is List &&
                  (availabilityData['slots'] as List).isNotEmpty) {
                mentor['minPrice'] = extractMinPrice(availabilityData['slots']);
              } else {
                mentor['minPrice'] = 0;
              }
            } else {
              mentor['minPrice'] = 0;
              print('Availability error: ${availabilityResponse.body}');
            }
          } catch (e) {
            print("Error fetching availability for mentor $mentorId: $e");
            mentor['minPrice'] = 0;
          }
        }
        setState(() {
          mentors = filteredMentors;
        });
      } else {
        setState(() {
          mentors = [];
        });
        print('Error fetching mentors: ${response.body}');
      }
    } catch (e) {
      print('Error fetching accepted mentors: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Compute review data for a mentor.
  Future<Map<String, dynamic>> computeReviewData(String mentorId) async {
    try {
      final uri = Uri.http('$serverIP:$serverPort', '/api/reviews/$mentorId');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> reviewsList = data['reviews'] ?? [];
        double totalRating = 0.0;
        for (var review in reviewsList) {
          totalRating += (review['rating'] as num).toDouble();
        }
        double avgRating =
            reviewsList.isNotEmpty ? totalRating / reviewsList.length : 0.0;
        return {
          'avgRating': avgRating,
          'reviewsCount': reviewsList.length,
        };
      }
    } catch (e) {
      print("Error computing reviews for mentor $mentorId: $e");
    }
    return {'avgRating': 0.0, 'reviewsCount': 0};
  }

  // Helper function to extract the minimum price from a list of slot maps.
  int extractMinPrice(List<dynamic>? slots) {
    if (slots == null || slots.isEmpty) {
      return 0;
    }
    int? minPrice;
    for (var slot in slots) {
      if (slot is Map && slot.containsKey('price')) {
        var priceValue = slot['price'];
        int? priceInt;
        if (priceValue is int) {
          priceInt = priceValue;
        } else if (priceValue is double) {
          priceInt = priceValue.toInt();
        } else if (priceValue is String) {
          String numericString = priceValue.replaceAll(RegExp(r'[^0-9]'), '');
          priceInt = int.tryParse(numericString);
        }
        if (priceInt != null) {
          if (minPrice == null || priceInt < minPrice) {
            minPrice = priceInt;
          }
        }
      }
    }
    return minPrice ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentors'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mentors.isEmpty
              ? const Center(child: Text('No accepted mentors found.'))
              : ListView.builder(
                  itemCount: mentors.length,
                  itemBuilder: (context, index) {
                    final mentor = mentors[index];
                    // Modified to check if profilePicture already starts with http.
                    final profileImageUrl = mentor['profilePicture'] != null
                        ? (mentor['profilePicture'].toString().startsWith('http')
                            ? mentor['profilePicture']
                            : '$baseUrl/${mentor['profilePicture']}')
                        : 'assets/default.png';
                    return MentorCard(
                      name:
                          '${mentor['firstName']} ${mentor['lastName'] ?? ''}',
                      role: mentor['jobTitle'] ?? 'No role',
                      skills: List<String>.from(mentor['subjects'] ?? []),
                      price: mentor['minPrice'] ?? 0,
                      rating: mentor['rating'] ?? '0.0',
                      reviewsCount: mentor['reviewsCount'] ?? '0',
                      imageUrl: profileImageUrl,
                      onViewProfile: () {
                        String mentorId =
                            mentor['user']?['_id'] ?? mentor['_id'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MentorProfilePage(userId: mentorId),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

// MentorCard widget using the same design as MentorSearchPage.
class MentorCard extends StatelessWidget {
  final String name;
  final String role;
  final List<String> skills;
  final int price;
  final String rating;
  final String reviewsCount;
  final String imageUrl;
  final VoidCallback onViewProfile;

  const MentorCard({
    Key? key,
    required this.name,
    required this.role,
    required this.skills,
    required this.price,
    required this.rating,
    required this.reviewsCount,
    required this.imageUrl,
    required this.onViewProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: imageUrl.startsWith('http')
                  ? NetworkImage(imageUrl)
                  : AssetImage(imageUrl) as ImageProvider,
              onBackgroundImageError: (_, __) {
                print("Error loading profile image: $imageUrl");
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: skills.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                        ' $rating ($reviewsCount reviews)',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Starting from: Rs. $price/month',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 13, 13, 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onViewProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('View Profile',
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
