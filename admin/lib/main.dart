import 'package:flutter/material.dart';
import 'package:admin/screens/dashboard.dart'; // Import the DashboardPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // This removes the debug banner
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DashboardPage(), // Navigating directly to the DashboardPage
    );
  }
}
