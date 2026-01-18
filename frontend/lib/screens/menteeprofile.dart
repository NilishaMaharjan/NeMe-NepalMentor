import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'conf_ip.dart';

class MenteeProfilePage extends StatefulWidget {
  final String userId;

  const MenteeProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _MenteeProfilePageState createState() => _MenteeProfilePageState();
}

class _MenteeProfilePageState extends State<MenteeProfilePage> {
  Map<String, dynamic>? menteeProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMenteeProfile();
  }

  Future<void> fetchMenteeProfile() async {
    final url =
        Uri.parse('$baseUrl/api/mentees/${widget.userId}');
    print('Fetching mentee profile from: $url'); // Debug log
    try {
      final response = await http.get(url);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          menteeProfile = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load profile. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching mentee profile: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('Mentee Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : menteeProfile == null
              ? const Center(child: Text('Failed to load profile'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            menteeProfile!['firstName'] != null
                                ? menteeProfile!['firstName'][0]
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${menteeProfile!['firstName'] ?? 'No first name'} ${menteeProfile!['lastName'] ?? 'No last name'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Mentee',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Divider(
                        height: 32,
                        thickness: 1,
                        color: Colors.teal,
                      ),
                      InfoRow(
                        label: 'Email',
                        value: menteeProfile!['email'] ?? 'No email',
                      ),
                      InfoRow(
                        label: 'Age',
                        value: menteeProfile!['age']?.toString() ?? 'No age',
                      ),
                      InfoRow(
                        label: 'Institution',
                        value:
                            menteeProfile!['institution'] ?? 'No institution',
                      ),
                      InfoRow(
                        label: 'Location',
                        value: menteeProfile!['location'] ?? 'No location',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
