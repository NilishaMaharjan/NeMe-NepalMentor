import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mentors_screen.dart';
import 'mentees_screen.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int mentorCount = 0;
  int menteeCount = 0;

  @override
  void initState() {
    super.initState();
    getUserCounts();
  }

  Future<void> getUserCounts() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.103:3000/api/admin/user-count'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          mentorCount = data['mentorCount'];
          menteeCount = data['menteeCount'];
        });
      } else {
        throw Exception('Failed to load user counts');
      }
    } catch (e) {
      print('Error fetching user counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: buildSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildDashboardOverview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSidebar() {
    return Drawer(
      child: Container(
        color: Color(0xFF2C3E50),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF34495E),
              ),
              child: Center(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            buildSidebarItem(Icons.dashboard, 'Dashboard', true),
            buildSidebarItem(Icons.people, 'Mentors', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MentorsScreen()));
            }),
            buildSidebarItem(Icons.person, 'Mentees', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MenteeListPage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget buildSidebarItem(IconData icon, String label, bool isActive, [VoidCallback? onTap]) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(label, style: TextStyle(color: Colors.white)),
      tileColor: isActive ? Color(0xFF34495E) : Colors.transparent,
      onTap: onTap,
    );
  }

  Widget buildDashboardOverview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildDashboardCard('Total Mentors', mentorCount.toString()),
        buildDashboardCard('Total Mentees', menteeCount.toString()),
      ],
    );
  }

  Widget buildDashboardCard(String title, String count) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                color: Color(0xFF2980B9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
