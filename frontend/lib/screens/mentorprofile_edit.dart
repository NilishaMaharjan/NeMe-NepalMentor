import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'conf_ip.dart';

class MentorProfileEditPage extends StatefulWidget {
  const MentorProfileEditPage({Key? key}) : super(key: key);

  @override
  _MentorProfileEditPageState createState() => _MentorProfileEditPageState();
}

class _MentorProfileEditPageState extends State<MentorProfileEditPage> {
  late Future<Map<String, dynamic>> mentorData;
  List<Map<String, dynamic>> reviews = [];
  String? currentUserId;
  bool isEditing = false; // To toggle between edit and view mode

  // Controllers for text fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController qualificationsController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    mentorData = fetchMentorData();
    fetchReviews();
  }

  // Load current user ID from shared preferences
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
    });
  }

  // Fetch mentor data from backend
  Future<Map<String, dynamic>> fetchMentorData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final response = await http.get(
      Uri.parse('$baseUrl/api/mentors/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mentor data');
    }
  }

  // Fetch reviews from backend
  Future<void> fetchReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final response = await http.get(
      Uri.parse('$baseUrl/api/reviews/$userId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        reviews = List<Map<String, dynamic>>.from(data['reviews'].map((review) {
          return {
            'review': review['review'],
            'rating': (review['rating'] as num).toDouble(),
            'userId': review['userId']?['_id'],
            'menteeName': review['userId'] != null
                ? '${review['userId']['firstName']} ${review['userId']['lastName']}'
                : 'Anonymous',
            '_id': review['_id'],
          };
        }));
      });
    } else {
      print('Failed to fetch reviews: ${response.body}');
    }
  }

  // Save the edited profile
  Future<void> saveProfile() async {
    final updatedData = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'jobTitle': jobTitleController.text,
      'qualifications': qualificationsController.text,
      'bio': bioController.text,
      'location': locationController.text,
      'skills': skillsController.text.split(',').map((skill) => skill.trim()).toList(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/mentors/$currentUserId'),
      body: json.encode(updatedData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      mentorData = fetchMentorData(); // Refresh mentor data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes')),
      );
    }
  }

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double sum = reviews.fold(0, (prev, element) => prev + element['rating']);
    return sum / reviews.length;
  }

  // Helper method to convert relative profile picture path to a full URL
  String getProfileImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150'; // Placeholder if no image
    }
    String trimmedPath = path.trim();
    if (trimmedPath.startsWith('/')) {
      trimmedPath = trimmedPath.substring(1);
    }
    if (trimmedPath.startsWith('http')) {
      return trimmedPath;
    }
    return '$baseUrl/' + trimmedPath.replaceAll('\\', '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: mentorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          }

          final mentor = snapshot.data!;
          double averageRating = calculateAverageRating();
          int totalReviews = reviews.length;

          // Set the initial values of controllers for editing
          firstNameController.text = mentor['firstName'];
          lastNameController.text = mentor['lastName'] ?? '';
          jobTitleController.text = mentor['jobTitle'] ?? '';
          qualificationsController.text = mentor['qualifications'] ?? '';
          bioController.text = mentor['bio'] ?? '';
          locationController.text = mentor['location'] ?? '';
          skillsController.text = (mentor['skills'] as List<dynamic>?)
                  ?.join(', ') ??
              ''; // Joining skills with comma

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
                      backgroundImage: mentor['profilePicture'] != null
                          ? NetworkImage(getProfileImageUrl(mentor['profilePicture']))
                          : AssetImage('assets/default.png') as ImageProvider,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isEditing
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: firstNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'First Name',
                                          labelStyle: TextStyle(
                                            color: Colors.teal,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: lastNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Last Name',
                                          labelStyle: TextStyle(
                                            color: Colors.teal,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${mentor['firstName']} ${mentor['lastName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                          const SizedBox(height: 6),
                          isEditing
                              ? TextField(
                                  controller: jobTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Job Title',
                                    labelStyle: TextStyle(
                                      color: Colors.teal,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  mentor['jobTitle'] ?? 'No title',
                                  style: const TextStyle(fontSize: 18, color: Colors.black),
                                ),
                          const SizedBox(height: 6),
                          if (!isEditing)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                Text(
                                  ' ${averageRating.toStringAsFixed(1)} ($totalReviews reviews)',
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
                isEditing
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: skillsController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (mentor['skills'] as List<dynamic>? ?? [])
                            .map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
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
                              skill,
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 20),
                // Location Section
                if (mentor['location'] != null) ...[
                  const Text(
                    'Location:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 6),
                  isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        )
                      : Text(
                          mentor['location'],
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                  const SizedBox(height: 24),
                ],
                // Qualifications Section
                if (mentor['qualifications'] != null) ...[
                  const Text(
                    'Qualifications:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 6),
                  isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: qualificationsController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        )
                      : Text(
                          mentor['qualifications'],
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                  const SizedBox(height: 24),
                ],
                // Bio Section
                const Text(
                  'Bio:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                const SizedBox(height: 6),
                isEditing
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: bioController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                      )
                    : Text(
                        mentor['bio'],
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                const SizedBox(height: 24),
                if (isEditing)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        width: 400,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: saveProfile,
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Rating and Review Section
                if (!isEditing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${review['menteeName'] ?? 'Anonymous'}',
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
                                '${review['review'] ?? 'No review available'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
