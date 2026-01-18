import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';


class MentorDetailScreen extends StatefulWidget {
  final dynamic mentor;
  final Function refreshMentorList;

  MentorDetailScreen({required this.mentor, required this.refreshMentorList});

  @override
  _MentorDetailScreenState createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  bool _isVerifying = false;
  bool _isDeleting = false;
  final String baseUrl = 'http://192.168.0.103:3000/';

   // Get full URL for images and files
  String getFullUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150'; // Default placeholder
    }
    if (path.startsWith('http')) {
      return Uri.encodeFull(path); // Cloudinary URL
    }
    return Uri.encodeFull('$baseUrl$path'.replaceAll('\\', '/')); // Local storage
  }

  Future<void> confirmSelection(BuildContext context, String mentorId, String email) async {
  setState(() {
    _isVerifying = true;
  });

  // ✅ Fix API URL to remove duplicate slashes
  final String apiUrl = '${baseUrl}api/admin/verify-mentor/$mentorId';

  print("📡 Sending API request to: $apiUrl");
  print("📡 Mentor ID: $mentorId, Email: $email");

  try {
    final response = await http.put(Uri.parse(apiUrl));

    print("📡 Response Status Code: ${response.statusCode}");
    print("📡 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData.containsKey('user') && responseData['user']['verified'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentor verified successfully')),
        );

        // ✅ Update UI immediately
        setState(() {
          widget.mentor['verified'] = true;
        });

        widget.refreshMentorList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected response format')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify mentor: ${response.body}')),
      );
    }
  } catch (error) {
    print("❌ Error verifying mentor: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error, please try again later')),
    );
  }

  setState(() {
    _isVerifying = false;
  });
}


  //Delete Mentor
  Future<void> deleteMentor(String mentorId) async {
  setState(() {
    _isDeleting = true;
  });

  final String apiUrl = '${baseUrl}api/admin/users/$mentorId';
  print("🗑️ Sending Delete Request for Mentor ID: $mentorId");

  try {
    final response = await http.delete(Uri.parse(apiUrl));

    print("📡 Response Status Code: ${response.statusCode}");
    print("📡 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentor deleted successfully')));

      widget.refreshMentorList();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete mentor: ${response.body}')));
    }
  } catch (error) {
    print("❌ Error deleting mentor: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error, please try again later')),
    );
  }

  setState(() {
    _isDeleting = false;
  });
}

  
  Future<void> openUrl(String url) async {
    if (!url.startsWith('http')) {
      url = 'https://' + url;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentor = widget.mentor;
    bool isVerified = mentor['verified'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('${mentor['firstName']} ${mentor['lastName']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Image.network(
                getFullUrl(mentor['profilePicture']),
                errorBuilder: (context, error, stackTrace) {
                  return Text('Error loading profile image');
                },
              ),
              SizedBox(height: 16),
              Text('Full Name: ${mentor['firstName']} ${mentor['lastName']}', style: TextStyle(fontSize: 16)),
Text(
  'Email: ${mentor['email'] ?? 'No email available'}',
  style: TextStyle(fontSize: 16),
),

              Text('Location: ${mentor['location']}', style: TextStyle(fontSize: 16)),
              Text('Qualifications: ${mentor['qualifications']}', style: TextStyle(fontSize: 16)),
              Text('Skills: ${mentor['skills']}', style: TextStyle(fontSize: 16)),
              Text('Job Title: ${mentor['jobTitle']}', style: TextStyle(fontSize: 16)),
              Text('Category: ${mentor['category']}', style: TextStyle(fontSize: 16)),
              Text('Bio: ${mentor['bio']}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),

              
              if (mentor['fieldOfStudy'] != null)
                Text('Field of Study: ${mentor['fieldOfStudy']}', style: TextStyle(fontSize: 16)),

            
              if (mentor['subjects'] != null && mentor['subjects'] is List)
                Text('Subjects: ${mentor['subjects'].join(', ')}', style: TextStyle(fontSize: 16)),

              SizedBox(height: 10),

              
              if (mentor['socialLinks'] != null && mentor['socialLinks'] is List && mentor['socialLinks'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Social Links:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ...mentor['socialLinks'].map<Widget>((link) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Platform: ${link['platform']}', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          InkWell(
                            onTap: () => openUrl(link['link']),
                            child: Text(
                              link['link'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ],
                ),

              SizedBox(height: 20),

              
             
              if (mentor['certificates'] != null && mentor['certificates'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificates:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ...mentor['certificates'].map<Widget>((certPath) {
                      String fullUrl = getFullUrl(certPath);
                      String ext = certPath.split('.').last.toLowerCase();

                      if (['jpg', 'jpeg', 'png'].contains(ext)) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(fullUrl, errorBuilder: (context, error, stackTrace) {
                            return Text('Error loading certificate image');
                          }),
                        );
                      } else if (ext == 'pdf') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () => openUrl(fullUrl),
                            child: Text('View PDF Certificate'),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    }).toList(),
                  ],
                ),


              SizedBox(height: 20),

              if (!isVerified)
  Center(
    child: Column(
      children: [
        ElevatedButton(
  onPressed: _isVerifying
      ? null
      : () {
          final verifyId = mentor.containsKey('user') && mentor['user'] != null
              ? mentor['user']['_id']
              : mentor.containsKey('_id')
                  ? mentor['_id']
                  : null;

          final verifyEmail = mentor.containsKey('user') && mentor['user'] != null
              ? mentor['user']['email']
              : mentor.containsKey('email')
                  ? mentor['email']
                  : null;

          print("🔍 Sending Mentor ID: $verifyId, Email: $verifyEmail"); // Debugging

          if (verifyId != null && verifyEmail != null) {
            confirmSelection(context, verifyId, verifyEmail);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mentor ID or Email is missing')),
            );
          }
      },
  style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green, minimumSize: Size(220, 48)),
  child: _isVerifying
      ? CircularProgressIndicator(color: Colors.white)
      : Text('Confirm Selection', style: TextStyle(color: Colors.white, fontSize: 16)),
),

        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isDeleting
              ? null
              : () {
                  if (mentor != null) {
                    final deleteId = mentor.containsKey('user') && mentor['user'] != null
                        ? mentor['user']['_id']
                        : mentor.containsKey('_id')
                            ? mentor['_id']
                            : null;
                    
                    if (deleteId != null) {
                      deleteMentor(deleteId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mentor ID is missing')),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, minimumSize: Size(220, 48)),
          child: _isDeleting
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Delete Mentor',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    ),
  ),
if (isVerified)
  Center(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.green, borderRadius: BorderRadius.circular(12)),
      child: Text('Verified',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  ),

            ],
          ),
        ),
      ),
    );
  }
}
