import 'package:flutter/material.dart';

class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({Key? key}) : super(key: key);

  final Color themeColor = const Color.fromARGB(255, 47, 161, 150);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'This page is under development.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.teal),
          ),
        ),
      ),
    );
  }
}