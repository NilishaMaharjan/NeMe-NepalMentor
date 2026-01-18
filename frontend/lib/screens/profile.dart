import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'request.dart';
import 'conf_ip.dart';


class MentorProfilePage extends StatefulWidget {
  final String userId;

  const MentorProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _MentorProfilePageState createState() => _MentorProfilePageState();
}

class _MentorProfilePageState extends State<MentorProfilePage> {
  late Future<Map<String, dynamic>> mentorData;
  late Future<Map<String, dynamic>?> availabilityData;
  List<Map<String, dynamic>> reviews = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    mentorData = fetchMentorData(widget.userId); // Initialize mentorData
    availabilityData = fetchAvailabilityData(widget.userId); // Initialize availabilityData
    fetchReviews();
  }

  // Load current user ID from shared preferences
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
    });
  }

  Future<void> fetchReviews() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reviews/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        reviews = List<Map<String, dynamic>>.from(
          data['reviews'].map((review) {
            return {
              'review': review['review'],
              'rating': (review['rating'] as num).toDouble(),
              'userId': review['userId']?['_id'],
              'menteeName': review['userId'] != null
                  ? '${review['userId']['firstName']} ${review['userId']['lastName']}'
                  : 'Anonymous',
              '_id': review['_id'],
            };
          }),
        );
      });
    } else {
      print('Failed to fetch reviews: ${response.body}');
    }
  }

  // Fetch only verified mentors
  Future<Map<String, dynamic>> fetchMentorData(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/mentors/$userId'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> mentor = json.decode(response.body);

      if (mentor['verified'] != true) {
        return {};
      }
      return mentor;
    } else {
      throw Exception('Failed to load mentor data');
    }
  }

  // Submit review to backend
  Future<void> submitReview(String mentorId, String reviewText, double rating) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'mentorId': mentorId,
        'userId': currentUserId,
        'review': reviewText,
        'rating': rating,
      }),
    );

    if (response.statusCode == 201) {
      // After submitting the review, fetch the updated reviews.
      fetchReviews();
    } else {
      throw Exception('Failed to submit review');
    }
  }

  // Fetch availability data
  Future<Map<String, dynamic>?> fetchAvailabilityData(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/availability/$userId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> updateReview(String reviewId, String updatedText, double updatedRating) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken'); // Replace with your token key

    final url = '$baseUrl/api/reviews/$reviewId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'review': updatedText,
          'rating': updatedRating,
        }),
      );

      if (response.statusCode == 200) {
        print('Review updated successfully');
        await fetchReviews();
      } else {
        print('Failed to update review: ${response.body}');
      }
    } catch (e) {
      print('Error updating review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/reviews/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          reviews.removeWhere((review) => review['_id'] == reviewId);
        });
        print('Review deleted successfully');
      } else {
        print('Failed to delete review: ${response.body}');
      }
    } catch (e) {
      print('Error deleting review: $e');
    }
  }

  void _showReviewDialog(String mentorId, [Map<String, dynamic>? reviewToEdit]) {
    final TextEditingController reviewController =
        TextEditingController(text: reviewToEdit?['review'] ?? '');
    double dialogRating = reviewToEdit?['rating'] ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            reviewToEdit == null ? 'Submit Review' : 'Edit Review',
            style: const TextStyle(color: Colors.teal),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < dialogRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            dialogRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: 'Describe your experience (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final reviewText = reviewController.text;
                final reviewId = reviewToEdit?['_id'];

                if (reviewId != null) {
                  updateReview(reviewId, reviewText, dialogRating);
                } else {
                  submitReview(widget.userId, reviewText, dialogRating);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  double _calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double total = 0.0;
    for (var review in reviews) {
      total += (review['rating'] as double);
    }
    return total / reviews.length;
  }
  
  // Helper method to convert relative profile picture path to full URL
  String getProfileImageUrl(String? path) {
  if (path == null || path.isEmpty) {
    return 'https://via.placeholder.com/150'; // Placeholder if no image
  }
  String trimmedPath = path.trim();
  // Remove a leading slash if present
  if (trimmedPath.startsWith('/')) {
    trimmedPath = trimmedPath.substring(1);
  }
  if (trimmedPath.startsWith('http')) {
    return trimmedPath; // Use the external URL directly
  }
  return '$baseUrl/' + trimmedPath.replaceAll('\\', '/');
}


  @override
  Widget build(BuildContext context) {
    // Compute average rating and review count based on the reviews list
    double avgRating = _calculateAverageRating();
    int reviewCount = reviews.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Profile'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([mentorData, availabilityData]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          }

          final Map<String, dynamic> mentor = snapshot.data![0] as Map<String, dynamic>;
          final Map<String, dynamic>? availability = snapshot.data![1] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image and Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(getProfileImageUrl(mentor['profilePicture'])),
                      onBackgroundImageError: (_, __) {
                        print("❌ Error loading profile image");
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${mentor['firstName']} ${mentor['lastName'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mentor['jobTitle'] ?? 'No title',
                            style: const TextStyle(fontSize: 18, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text(
                                ' ${avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A'} ($reviewCount reviews)',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Skills Section
               const Text(
                  'Skills:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      (mentor['skills'] as List<dynamic>? ?? []).map((skill) {
                    final String skillText = (skill is Map)
                        ? (skill['name']?.toString() ?? '')
                        : skill.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.teal,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        skillText,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Qualifications Section
                if (mentor['qualifications'] != null ||
                    mentor['bio'] != null ||
                    mentor['location'] != null) ...[
                  const Text(
                    'Details:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 6),
                  if (mentor['qualifications'] != null)
                    RichText(
                      text: TextSpan(
                        text: 'Qualifications: ',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                          TextSpan(
                            text: mentor['qualifications'].toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  if (mentor['location'] != null) ...[
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        text: 'Location: ',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                          TextSpan(
                            text: mentor['location'].toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (mentor['bio'] != null) ...[
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        text: 'Bio: ',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                          TextSpan(
                            text: mentor['bio'].toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
                // Timetable Section
                if (availability != null &&
                    (availability['slots'] as List).isNotEmpty) ...[
                  const Text(
                    'Timetable:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: [
                      for (int index = 0;
                          index < (availability['slots'] as List).length;
                          index++) ...[
                        Builder(builder: (context) {
                          final slot = (availability['slots'] as List)[index];
                          final String slotId = slot['_id']?.toString() ?? '';
                          final String slotTime =
                              slot['time']?.toString() ?? '';
                          final String slotPrice = slot['price'] != null
                              ? slot['price'].toString()
                              : '0';
                          // Extract the slot type
                          final String slotType = slot['type'] != null
                              ? slot['type'].toString()
                              : 'Unknown';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time: $slotTime',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Price: Rs. $slotPrice /month',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Type: $slotType',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RequestPage(
                                            slotId: slotId,
                                            slotTime: slotTime,
                                            mentorId: mentor['_id'].toString(),
                                            slotPrice: slotPrice,
                                            slotType: slotType,
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.teal,
                                    ),
                                    child: const Text('Available'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const Text(
                    'Timetable:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No availability information.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                ],
                // Reviews Section
                const Text(
                  'Reviews:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                const SizedBox(height: 10),
                if (reviews.isEmpty)
                  const Text(
                    'No reviews yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ...reviews.map((review) {
                  return ListTile(
                    subtitle: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review['menteeName']?.toString() ?? 'Anonymous'}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (review['rating'] ?? 0).toInt()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${review['review']?.toString() ?? 'No review available'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: review['userId'] == currentUserId
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.teal,
                                onPressed: () => _showReviewDialog(
                                    mentor['_id'].toString(), review),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () =>
                                    deleteReview(review['_id'].toString()),
                              ),
                            ],
                          )
                        : null,
                  );
                }),
                // Button to submit a new review
                ListTile(
                  title: TextButton(
                    onPressed: () =>
                        _showReviewDialog(mentor['_id'].toString()),
                    child: const Text(
                      'Submit a Review',
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}