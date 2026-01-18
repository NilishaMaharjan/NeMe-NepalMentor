import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'primary.dart';
import 'secondary.dart';
import 'diploma.dart';
import 'ctevt.dart';
import 'bachelor.dart';
import 'masters.dart';
import 'conf_ip.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Color themeColor = const Color.fromARGB(255, 47, 161, 150);
  String? firstName;
  String? email;

  @override
  void initState() {
    super.initState();
    fetchFirstName();
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> fetchFirstName() async {
    String? userId = await getUserId();
    if (userId == null) {
      print("No userId found.");
      return;
    }
    final url = Uri.parse('$baseUrl/api/mentees/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(response.body);
        setState(() {
          firstName = profileData['firstName'];
          email = profileData['email'];
        });
      } else {
        print(
            'Failed to fetch profile data. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching profile data: $error');
    }
  }

  Widget _buildLevelCard(String level, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: themeColor),
            const SizedBox(height: 10),
            Text(
              level,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile avatar and welcome message.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    (email != null && email!.isNotEmpty)
                        ? email![0].toUpperCase()
                        : "U",
                    style: TextStyle(fontSize: 35, color: themeColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${firstName ?? "User"}!',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '"Learning is a treasure that will follow its \nowner everywhere."',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dashboard image.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/dashboard.png',
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Choose your level',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          // Grid view of level options.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildLevelCard('Primary', Icons.school, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrimaryLevelPage(key: UniqueKey())),
                  );
                }),
                _buildLevelCard('Secondary', Icons.auto_stories, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SecondaryLevelPage(key: UniqueKey())),
                  );
                }),
                _buildLevelCard('Diploma', Icons.menu_book, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DiplomaLevelPage(key: UniqueKey())),
                  );
                }),
                _buildLevelCard('CTEVT', Icons.library_books, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CTEVTLevelPage(key: UniqueKey())),
                  );
                }),
                _buildLevelCard('Bachelor', Icons.school_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BachelorLevelPage(key: UniqueKey())),
                  );
                }),
                _buildLevelCard('Masters', Icons.workspace_premium, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MastersLevelPage(key: UniqueKey())),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}