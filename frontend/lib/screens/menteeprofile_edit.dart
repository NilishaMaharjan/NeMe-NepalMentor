import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'conf_ip.dart';


class ProfileEditPage extends StatefulWidget {
  final String userId;

  const ProfileEditPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  Map<String, dynamic>? menteeProfile;
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for each profile field.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMenteeProfile();
  }

  // Fetch the mentee profile from the backend.
  Future<void> fetchMenteeProfile() async {
    final url =
        Uri.parse('$baseUrl/api/mentees/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          menteeProfile = data;
          // Initialize text controllers with fetched data.
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _institutionController.text = data['institution'] ?? '';
          _locationController.text = data['location'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      // Optionally, show an error message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $error')),
      );
    }
  }

  // Update the mentee profile by sending a PUT request.
  Future<void> updateProfile() async {
    Map<String, dynamic> updatedProfile = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'institution': _institutionController.text,
      'location': _locationController.text,
    };

    final url =
        Uri.parse('$baseUrl/api/mentees/${widget.userId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedProfile),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Refresh the profile data.
        await fetchMenteeProfile();
        setState(() {
          isEditing = false;
        });
      } else {
        throw Exception('Failed to update profile.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        actions: [
          // Toggle edit mode.
          IconButton(
            icon: Icon(isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
                // If canceling edit mode, reset the fields to original data.
                if (!isEditing && menteeProfile != null) {
                  _firstNameController.text = menteeProfile!['firstName'] ?? '';
                  _lastNameController.text = menteeProfile!['lastName'] ?? '';
                  _emailController.text = menteeProfile!['email'] ?? '';
                  _phoneController.text =
                      menteeProfile!['phone']?.toString() ?? '';
                  _ageController.text = menteeProfile!['age']?.toString() ?? '';
                  _institutionController.text =
                      menteeProfile!['institution'] ?? '';
                  _locationController.text = menteeProfile!['location'] ?? '';
                }
              });
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (menteeProfile == null
              ? const Center(child: Text('Failed to load profile'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildInfoRow(
                        'First Name',
                        isEditing
                            ? _buildTextField(_firstNameController)
                            : Text(
                                menteeProfile!['firstName'] ?? 'No first name'),
                      ),
                      _buildInfoRow(
                        'Last Name',
                        isEditing
                            ? _buildTextField(_lastNameController)
                            : Text(
                                menteeProfile!['lastName'] ?? 'No last name'),
                      ),
                      _buildInfoRow(
                        'Email',
                        isEditing
                            ? _buildTextField(_emailController)
                            : Text(menteeProfile!['email'] ?? 'No email'),
                      ),
                      _buildInfoRow(
                        'Phone',
                        isEditing
                            ? _buildTextField(_phoneController)
                            : Text(menteeProfile!['phone']?.toString() ??
                                'No phone number'),
                      ),
                      _buildInfoRow(
                        'Age',
                        isEditing
                            ? _buildTextField(_ageController)
                            : Text(
                                menteeProfile!['age']?.toString() ?? 'No age'),
                      ),
                      _buildInfoRow(
                        'Institution',
                        isEditing
                            ? _buildTextField(_institutionController)
                            : Text(menteeProfile!['institution'] ??
                                'No institution'),
                      ),
                      _buildInfoRow(
                        'Location',
                        isEditing
                            ? _buildTextField(_locationController)
                            : Text(menteeProfile!['location'] ?? 'No location'),
                      ),
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical:
                                  12.0), // Reduced padding for a smaller button
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10), // Adjusted size
                              textStyle:
                                  const TextStyle(fontSize: 14), // Smaller text
                            ),
                            onPressed: updateProfile,
                            child: const Text(
                              'Update Profile',
                              style:
                                  TextStyle(color: Colors.white), // White text
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
    );
  }

  // Helper method to build an info row with a label and a widget value.
  Widget _buildInfoRow(String label, Widget valueWidget) {
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
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  // Helper method to build a TextField with the given controller.
  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}