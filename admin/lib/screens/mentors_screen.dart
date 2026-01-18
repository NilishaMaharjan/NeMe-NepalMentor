import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mentor_detail_screen.dart';
import 'dart:convert';

class MentorsScreen extends StatefulWidget {
  @override
  _MentorsScreenState createState() => _MentorsScreenState();
}

class _MentorsScreenState extends State<MentorsScreen> {
  late Future<List<dynamic>> mentors;

  @override
  void initState() {
    super.initState();
    mentors = fetchMentors(); 
  }

  void refreshMentorList() {
    setState(() {
      mentors = fetchMentors();
    });
  }

  // Fetch mentors from the API
  Future<List<dynamic>> fetchMentors() async {
    final response = await http.get(Uri.parse('http://192.168.0.103:3000/api/admin/mentors'));

    if (response.statusCode == 200) {
      print('Response Body: ${response.body}'); // Debugging
      return json.decode(response.body);
    } else {
      print('Failed to load mentors: ${response.body}'); // Debugging
      throw Exception('Failed to load mentors');
    }
  }

  // Handle delete mentor
  Future<void> confirmDeleteMentor(String mentorId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this mentor?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                deleteMentor(mentorId); // Proceed with deletion
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteMentor(String mentorId) async {
    final response = await http.delete(
      Uri.parse('http://192.168.0.103:3000/api/admin/users/$mentorId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Mentor deleted successfully')));
      refreshMentorList();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete mentor')));
    }
  }

  // Handle edit mentor by navigating to the full edit page
  Future<void> editMentor(String mentorId, Map<String, dynamic> mentorData) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMentorProfileEditPage(
          mentor: mentorData,
          refreshMentorList: refreshMentorList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mentors'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: mentors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final mentorList = snapshot.data!;
            return ListView.builder(
              itemCount: mentorList.length,
              itemBuilder: (context, index) {
                final mentor = mentorList[index];

                if (mentor is Map) {
                  String fullName = mentor['firstName'] != null && mentor['lastName'] != null
                      ? '${mentor['firstName']} ${mentor['lastName']}'
                      : 'No Name';
                  String email = mentor['email'] ?? 'No email';
                  String jobTitle = mentor['jobTitle'] ?? 'No job title';
                  String mentorId = mentor['_id'];
                  String profilePicture = mentor['profilePicture'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : AssetImage('assets/default.png') as ImageProvider,
                    ),
                    title: Text(
                      fullName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email),
                        Text(jobTitle),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            editMentor(mentorId, mentor as Map<String, dynamic>);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            confirmDeleteMentor(mentorId);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.visibility),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MentorDetailScreen(
                                  mentor: mentor as Map<String, dynamic>,
                                  refreshMentorList: refreshMentorList,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(child: Text('Invalid data format'));
                }
              },
            );
          } else {
            return Center(child: Text('No mentors available.'));
          }
        },
      ),
    );
  }
}

class AdminMentorProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final VoidCallback refreshMentorList;

  const AdminMentorProfileEditPage({
    Key? key,
    required this.mentor,
    required this.refreshMentorList,
  }) : super(key: key);

  @override
  _AdminMentorProfileEditPageState createState() => _AdminMentorProfileEditPageState();
}

class _AdminMentorProfileEditPageState extends State<AdminMentorProfileEditPage> {
  // Controllers for text fields
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController jobTitleController;
  late TextEditingController locationController;
  late TextEditingController qualificationsController;
  late TextEditingController bioController;
  late TextEditingController skillsController;

  // Added getFullUrl function to mimic mentor_detail_screen.dart
  String getFullUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    if (path.startsWith('http')) {
      return Uri.encodeFull(path);
    }
    return Uri.encodeFull('http://192.168.0.103:3000/$path'.replaceAll('\\', '/'));
  }

  @override
  void initState() {
    super.initState();
    final mentor = widget.mentor;
    firstNameController = TextEditingController(text: mentor['firstName'] ?? '');
    lastNameController = TextEditingController(text: mentor['lastName'] ?? '');
    jobTitleController = TextEditingController(text: mentor['jobTitle'] ?? '');
    locationController = TextEditingController(text: mentor['location'] ?? '');
    qualificationsController = TextEditingController(text: mentor['qualifications'] ?? '');
    bioController = TextEditingController(text: mentor['bio'] ?? '');
  
    var skillsData = mentor['skills'];
    String skillsText = '';
    if (skillsData is List) {
      skillsText = skillsData.join(', ');
    } else if (skillsData is String) {
      skillsText = skillsData;
    }
    skillsController = TextEditingController(text: skillsText);
  }

  Future<void> saveProfile() async {
    final updatedData = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'jobTitle': jobTitleController.text,
      'qualifications': qualificationsController.text,
      'bio': bioController.text,
      'location': locationController.text,
      'skills': skillsController.text,
    };

    final mentorId = widget.mentor['_id'];

    final response = await http.put(
      Uri.parse('http://192.168.0.103:3000/api/admin/users/$mentorId'),
      body: json.encode(updatedData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
      widget.refreshMentorList();
      Navigator.pop(context);
    } else {
      print("Update failed with status: ${response.statusCode}");
      print("Response body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save changes')));
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    jobTitleController.dispose();
    locationController.dispose();
    qualificationsController.dispose();
    bioController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Mentor Profile'),
        backgroundColor: Color(0xFFF4F6F9),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.mentor['profilePicture'] != null
                      ? NetworkImage(getFullUrl(widget.mentor['profilePicture']))
                      : AssetImage('assets/default.png') as ImageProvider,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      TextField(
                        controller: jobTitleController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Skills Section
            Text(
              'Skills:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            TextField(
              controller: skillsController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter skills separated by commas',
              ),
            ),
            SizedBox(height: 20),
            // Location Section
            Text(
              'Location:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 6),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            // Qualifications Section
            Text(
              'Qualifications:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 6),
            TextField(
              controller: qualificationsController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            // Bio Section
            Text(
              'Bio:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 6),
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            SizedBox(height: 24),
            // Save Button
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  width: 400,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: saveProfile,
                    child: Text(
                      'Update Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
