import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'menteeprofile.dart'; 
import 'conf_ip.dart'; 

class MenteesListScreen extends StatefulWidget {
  const MenteesListScreen({Key? key}) : super(key: key);

  @override
  State<MenteesListScreen> createState() => _MenteesListScreenState();
}

class _MenteesListScreenState extends State<MenteesListScreen> {
  List<Map<String, dynamic>> acceptedMentees = [];
  List<dynamic> communitySlots = []; // Fetched availability slots
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  // Get userId and then fetch both availability and accepted mentees
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    if (userId != null) {
      await _fetchAvailability();
      await _fetchAcceptedMentees();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found! Please login again.')),
      );
    }
  }

  // Fetch the mentor's availability slots
  Future<void> _fetchAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/availability/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['slots'] is List) {
          setState(() {
            communitySlots = List<dynamic>.from(data['slots']);
          });
        }
      } else {
        print("Failed to fetch availability: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching availability: $e");
    }
  }

  // Fetch accepted mentees from your backend.
  Future<void> _fetchAcceptedMentees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/mentor/accepted?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          acceptedMentees = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showError('Failed to fetch accepted mentees: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Error fetching mentees. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentees'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : acceptedMentees.isEmpty
              ? const Center(
                  child: Text(
                    'No accepted mentees found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: acceptedMentees.length,
                  itemBuilder: (context, index) {
                    final mentee = acceptedMentees[index];
                    return MenteeCard(
                      mentee: mentee,
                      communitySlots: communitySlots,
                      onTap: () {
                        final menteeUserId = mentee['mentee']['userId'] ??
                            mentee['mentee']['_id'];
                        if (menteeUserId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MenteeProfilePage(userId: menteeUserId),
                            ),
                          );
                        } else {
                          print("Mentee user ID is null");
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class MenteeCard extends StatelessWidget {
  final Map<String, dynamic> mentee;
  final List<dynamic> communitySlots;
  final VoidCallback onTap;

  const MenteeCard({
    Key? key,
    required this.mentee,
    required this.onTap,
    required this.communitySlots,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menteeFirstName = mentee['mentee']['firstName'] ?? 'Unknown';
    final menteeLastName = mentee['mentee']['lastName'] ?? 'Unknown';
    final menteeName = '$menteeFirstName $menteeLastName';
    final menteeEmail = mentee['mentee']['email'] ?? 'Unknown';

    Widget slotDetailsWidget;

    // First check if the mentee has a full slot object (as a Map or formatted String)
    if (mentee['slot'] != null) {
      if (mentee['slot'] is Map) {
        final slotMap = mentee['slot'];
        String time = slotMap['time'] ?? 'No time info';
        String price =
            slotMap['price'] != null ? 'Rs. ${slotMap['price']}/month' : '';
        String type = slotMap['type'] ?? '';
        slotDetailsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: $time', style: const TextStyle(fontSize: 14)),
            if (price.isNotEmpty)
              Text('Price: $price', style: const TextStyle(fontSize: 14)),
            if (type.isNotEmpty)
              Text('Type: $type', style: const TextStyle(fontSize: 14)),
          ],
        );
      } else if (mentee['slot'] is String) {
        List<String> parts = mentee['slot'].toString().split(' - ');
        if (parts.length >= 3) {
          String price = parts[0].trim();
          String type = parts[1].trim();
          String time = parts.sublist(2).join(' - ').trim();
          slotDetailsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $time', style: const TextStyle(fontSize: 14)),
              Text('Price: $price', style: const TextStyle(fontSize: 14)),
              Text('Type: $type', style: const TextStyle(fontSize: 14)),
            ],
          );
        } else {
          slotDetailsWidget =
              Text(mentee['slot'], style: const TextStyle(fontSize: 14));
        }
      } else {
        slotDetailsWidget =
            const Text('No Slot Selected', style: TextStyle(fontSize: 14));
      }
    }
    // Otherwise, if a slotId exists, try to find matching slot details
    else if (mentee['slotId'] != null) {
      final slotId = mentee['slotId'];
      final matchingSlot = communitySlots.firstWhere(
        (slot) => slot['_id'] == slotId,
        orElse: () => null,
      );
      if (matchingSlot != null && matchingSlot is Map) {
        String time = matchingSlot['time'] ?? 'No time info';
        String price = matchingSlot['price'] != null
            ? 'Rs. ${matchingSlot['price']}/month'
            : '';
        String type = matchingSlot['type'] ?? '';
        slotDetailsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: $time', style: const TextStyle(fontSize: 14)),
            if (price.isNotEmpty)
              Text('Price: $price', style: const TextStyle(fontSize: 14)),
            if (type.isNotEmpty)
              Text('Type: $type', style: const TextStyle(fontSize: 14)),
          ],
        );
      } else {
        slotDetailsWidget =
            const Text('No Slot Selected', style: TextStyle(fontSize: 14));
      }
    } else {
      slotDetailsWidget =
          const Text('No Slot Selected', style: TextStyle(fontSize: 14));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(menteeName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(menteeEmail),
            const SizedBox(height: 4),
            const Text('Slot Details:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            slotDetailsWidget,
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}