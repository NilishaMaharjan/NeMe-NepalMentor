import 'package:flutter/material.dart';

class Mentee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String profilePicture;

  Mentee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePicture,
  });

  factory Mentee.fromJson(Map<String, dynamic> json) {
    return Mentee(
      id: json['_id'],
      firstName: json['firstName'] ?? 'No Name',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '/uploads/profilePictures/default.png',
    );
  }
}

class MenteeDetailScreen extends StatelessWidget {
  final  mentee;

  MenteeDetailScreen({required this.mentee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${mentee.firstName} ${mentee.lastName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          CircleAvatar(
  radius: 50,
  backgroundColor: Colors.teal, // You can change the background color as needed
  child: Text(
    mentee.email.isNotEmpty ? mentee.email[0].toUpperCase() : 'U', // Show the first letter of the email
    style: TextStyle(
      fontSize: 40,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
),

            SizedBox(height: 20),
            Text(
              'First Name: ${mentee.firstName}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Last Name: ${mentee.lastName}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Email: ${mentee.email}',
              style: TextStyle(fontSize: 18),
            ),
            // Add any other mentee details you want to display here
          ],
        ),
      ),
    );
  }
}
