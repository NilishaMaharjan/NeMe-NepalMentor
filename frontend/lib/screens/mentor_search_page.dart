import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'conf_ip.dart';
import 'profile.dart'; // For MentorProfilePage

class MentorSearchPage extends StatefulWidget {
  final String category;
  final String? fieldOfStudy; // For Bachelors/Masters
  final String classLevel;
  final String subject;

  const MentorSearchPage({
    Key? key,
    required this.category,
    this.fieldOfStudy,
    required this.classLevel,
    required this.subject,
  }) : super(key: key);

  @override
  _MentorSearchPageState createState() => _MentorSearchPageState();
}

class _MentorSearchPageState extends State<MentorSearchPage> {
  List<dynamic> mentors = [];
  bool isLoading = false;
  bool hasSearched = false;

  // Base URL for API endpoints and image paths.
  final String baseUrl = "http://192.168.0.102:3000/";

  // Helper function to extract the minimum price from a list of slot maps.
  int extractMinPrice(List<dynamic>? slots) {
    if (slots == null || slots.isEmpty) {
      return 0; // No slots available, return 0
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

  Future<void> fetchMentors() async {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    final queryParameters = {
      'category': widget.category,
      if (widget.category == 'Bachelors' || widget.category == 'Masters')
        'fieldOfStudy': widget.fieldOfStudy,
      'classLevel': widget.classLevel,
      'subject': widget.subject,
    };

    try {
      final uri = Uri.http('$serverIP:$serverPort', '/api/mentors', queryParameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // For each mentor, compute review data and fetch availability.
        for (var mentor in data) {
          String mentorId = mentor['user']?['_id'] ?? mentor['_id'];

          // Compute review data.
          Map<String, dynamic> reviewData = await computeReviewData(mentorId);
          mentor['rating'] = (reviewData['avgRating'] as double).toStringAsFixed(1);
          mentor['reviewsCount'] = reviewData['reviewsCount'].toString();

          // Fetch availability data.
          try {
            final availabilityUri =
                Uri.http('$serverIP:$serverPort', '/api/availability/$mentorId');
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
          mentors = data;
        });
      } else {
        setState(() {
          mentors = [];
        });
        print('Error: ${response.body}');
      }
    } catch (e) {
      setState(() {
        mentors = [];
      });
      print("Error fetching mentors: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Computes review data for a mentor.
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

  /// Convert a relative profile picture path to a full URL.
  String getProfileImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150'; // Placeholder if no image is provided.
    }
    if (path.startsWith('http')) {
      return path; // Use the provided URL directly.
    }
    return baseUrl + path.replaceAll('\\', '/'); // Append baseUrl for relative paths.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Mentors'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (!hasSearched || mentors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: OutlinedButton(
                onPressed: fetchMentors,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                child: const Text(
                  'Search Mentors',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (mentors.isEmpty && hasSearched)
                    ? const Center(child: Text('No mentors found.'))
                    : ListView.builder(
                        itemCount: mentors.length,
                        itemBuilder: (context, index) {
                          final mentor = mentors[index];
                          String mentorId = mentor['user']?['_id'] ?? mentor['_id'];
                          // Use the correct profile image logic.
                          String profileImageUrl =
                              getProfileImageUrl(mentor['profilePicture']);
                          return MentorCard(
                            name:
                                '${mentor['firstName']} ${mentor['lastName'] ?? ''}',
                            // Fallback: check multiple keys including mentor['user']?['role']
                            role: mentor['jobTitle'] ??
                                mentor['jobtitle'] ??
                                mentor['user']?['jobTitle'] ??
                                mentor['user']?['jobtitle'] ??
                                mentor['user']?['role'] ??
                                'No role',
                            skills: List<String>.from(mentor['subjects'] ?? []),
                            price: mentor['minPrice'] ?? 0,
                            rating: mentor['rating'],
                            reviewsCount: mentor['reviewsCount'],
                            imageUrl: profileImageUrl,
                            onViewProfile: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MentorProfilePage(userId: mentorId),
                                ),
                              );
                              fetchMentors();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display a mentor's information in a card.
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
              backgroundImage: NetworkImage(imageUrl),
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
                    child:
                        const Text('View Profile', style: TextStyle(fontSize: 16)),
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
