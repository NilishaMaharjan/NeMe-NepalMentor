import 'dart:convert';
import 'package:flutter/material.dart';
import 'mentee_detail_screen.dart';
import 'package:http/http.dart' as http;

class MenteeListPage extends StatefulWidget {
  @override
  _MenteeListPageState createState() => _MenteeListPageState();
}

class _MenteeListPageState extends State<MenteeListPage> {
  Future<List<Mentee>> fetchMentees() async {
    final response = await http.get(Uri.parse('http://192.168.0.103:3000/api/admin/mentees'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      
      // Optional: Only show verified mentees if needed
      // data = data.where((mentee) => mentee['verified'] == true).toList();
      
      return data.map((json) => Mentee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load mentees');
    }
  }

   void confirmDeleteMentee(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this mentee?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                deleteMentee(id); // Proceed with deletion
              },
              child: Text('Delete', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> deleteMentee(String id) async {
    final response = await http.delete(Uri.parse('http://192.168.0.103:3000/api/admin/users/$id'));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentee deleted successfully')));
      setState(() {
        fetchMentees();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete mentee')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mentee List')),
      body: FutureBuilder<List<Mentee>>(
        future: fetchMentees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No mentees found'));
          } else {
            final mentees = snapshot.data!;
            return ListView.builder(
              itemCount: mentees.length,
              itemBuilder: (context, index) {
                final mentee = mentees[index];
                String fullName = mentee.firstName.isNotEmpty
                    ? '${mentee.firstName} ${mentee.lastName}'
                    : 'No Name';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      mentee.email.isNotEmpty
                          ? mentee.email[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(fullName),
                  subtitle: Text(mentee.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMenteePage(mentee: mentee),
                            ),
                          );
                        },
                      ),
                     IconButton(
  icon: Icon(Icons.delete),
  onPressed: () {
    confirmDeleteMentee(mentee.id);
  },
),

                      IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenteeDetailScreen(mentee: mentee),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Mentee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String profilePicture;
  // final bool verified;  // Uncomment if verification is needed

  Mentee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePicture,
    // required this.verified,  // Uncomment if verification is needed
  });

  factory Mentee.fromJson(Map<String, dynamic> json) {
    return Mentee(
      id: json['_id'],
      firstName: json['firstName'] ?? 'No Name',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '/uploads/profilePictures/default.png',
      // verified: json['verified'] ?? false,  // Uncomment if verification is needed
    );
  }
}

// Edit Mentee Page with similar look to mentor edit page
class EditMenteePage extends StatefulWidget {
  final Mentee mentee;
  EditMenteePage({required this.mentee});

  @override
  _EditMenteePageState createState() => _EditMenteePageState();
}

class _EditMenteePageState extends State<EditMenteePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.mentee.firstName);
    _lastNameController = TextEditingController(text: widget.mentee.lastName);
    _emailController = TextEditingController(text: widget.mentee.email);
  }

  Future<void> updateMentee() async {
    final updatedData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
    };

    final response = await http.put(
      Uri.parse('http://192.168.0.103:3000/api/admin/users/${widget.mentee.id}'),
      body: json.encode(updatedData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Mentee updated successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update mentee')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Mentee Profile'),
        backgroundColor: Color(0xFFF4F6F9),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image and Name Row
            Row(
              children: [
               CircleAvatar(
  radius: 50,
  backgroundColor: Colors.teal, // Background color for the avatar
  child: Text(
    widget.mentee.email.isNotEmpty ? widget.mentee.email[0].toUpperCase() : 'U', // First letter of email
    style: TextStyle(
      fontSize: 40,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
),

                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First & Last Name Fields (without boxes)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _firstNameController,
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
                              controller: _lastNameController,
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
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Email Field
            Text(
              'Email:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 6),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter email',
              ),
            ),
            SizedBox(height: 24),
            // Save Button
            Center(
              child: SizedBox(
                width: 400,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: updateMentee,
                  child: Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
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
