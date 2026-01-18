import 'dart:convert';
import 'package:flutter/material.dart';
import 'conf_ip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_availability.dart';
import 'package:get/get.dart';
import 'login.dart';
import 'mentees_list_screen.dart';
import 'package:http/http.dart' as http;
import 'mentorprofile_edit.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int _selectedIndex = 0;
  String? userId;
  List<dynamic> communitySlots = [];
  List<Map<String, dynamic>> menteeRequests = []; // Holds mentee requests dynamically

  // <-- ADDED: Mentor profile variable to store details like photo and name
  Map<String, dynamic>? mentorProfile;

  @override
  void initState() {
    super.initState();
    _getUserId().then((_) {
      _fetchAvailability();
      _fetchMenteeRequests(); // Fetch mentee requests on load
      _fetchMentorProfile();   // <-- ADDED: Fetch mentor profile data
    });
  }

  // Fetch the userId from SharedPreferences
  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  // <-- ADDED: Fetch mentor profile from API using userId
  Future<void> _fetchMentorProfile() async {
    if (userId == null) return;
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/mentors/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          mentorProfile = data;
        });
      } else {
        print("Failed to fetch mentor profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching mentor profile: $e");
    }
  }

  // Fetch mentor's availability slots from backend
  Future<void> _fetchAvailability() async {
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/availability/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if data['slots'] is a List before using it
        if (data['slots'] is List) {
          setState(() {
            communitySlots = List<dynamic>.from(data['slots']);
          });
        } else {
          print("Unexpected format for slots: ${data['slots']}");
        }
      }
    } catch (e) {
      print("Error fetching availability: $e");
    }
  }

  // Fetch mentee requests from backend
  Future<void> _fetchMenteeRequests() async {
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/mentor?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if data is a List before using it
        if (data is List) {
          setState(() {
            menteeRequests = List<Map<String, dynamic>>.from(data);
          });
        } else {
          print("Unexpected format for mentee requests: $data");
        }
      } else {
        print("Failed to fetch mentee requests: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching mentee requests: $e");
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        _fetchMenteeRequests(); // Refresh requests
      } else {
        print("Failed to update request status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating request status: $e");
    }
  }

  // update the UI for request status changes.
  void _quickUpdateRequestStatus(int index, String status) {
    final removedRequest = menteeRequests[index];
    setState(() {
      menteeRequests.removeAt(index);
    });
    _updateRequestStatus(removedRequest['_id'], status).catchError((error) {
      setState(() {
        menteeRequests.insert(index, removedRequest);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update request status. Please try again.')),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout function
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Clear the stored userId
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0
              ? 'My Community'
              : _selectedIndex == 1
                  ? 'Requests'
                  : _selectedIndex == 2
                      ? 'Profile'
                      : '',
        ),
        backgroundColor: Colors.teal,
      ),
      body: _selectedIndex == 0
          ? _buildHomeScreen()
          : _selectedIndex == 1
              ? _buildMenteeRequests()
              : _selectedIndex == 2
                  ? _buildProfile()
                  : Container(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  // Build the Home Screen with community slots
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // <-- UPDATED HEADER: Displays mentor photo and name if available
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal,
                  backgroundImage: mentorProfile != null &&
                          mentorProfile!['profilePicture'] != null &&
                          mentorProfile!['profilePicture'].toString().trim().startsWith('http')
                      ? NetworkImage(mentorProfile!['profilePicture'])
                      : null,
                  child: (mentorProfile == null ||
                          mentorProfile!['profilePicture'] == null ||
                          !mentorProfile!['profilePicture'].toString().trim().startsWith('http'))
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorProfile != null &&
                              mentorProfile!['firstName'] != null &&
                              mentorProfile!['lastName'] != null
                          ? 'Hello, ${mentorProfile!['firstName']} ${mentorProfile!['lastName']}'
                          : 'Hello, Mentor!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Manage your community effectively.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'My Community',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          if (communitySlots.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No communities available. Please add availability slots.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ...communitySlots.map((slot) => _buildCommunityCard(slot)),
        ],
      ),
    );
  }

  // Build each community card using the updated slot model.
  Widget _buildCommunityCard(dynamic slot) {
    final timeInfo =
        slot is Map && slot.containsKey('time') ? slot['time'] : 'No time info';
    return InkWell(
      onTap: () {
        Get.toNamed('/chat', arguments: {
          'slot': slot,
          'receiverId': userId,
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.teal.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.group,
                  size: 28,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Slot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Time: $timeInfo',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the Mentee Requests Screen
  Widget _buildMenteeRequests() {
    return menteeRequests.isEmpty
        ? const Center(
            child: Text(
              'No requests found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
            itemCount: menteeRequests.length,
            itemBuilder: (context, index) {
              final request = menteeRequests[index];
              final menteeFirstName = request['mentee'] != null
                  ? request['mentee']['firstName'] ?? 'Unknown'
                  : 'Unknown';
              final menteeLastName = request['mentee'] != null
                  ? request['mentee']['lastName'] ?? 'Unknown'
                  : 'Unknown';
              final menteeName = '$menteeFirstName $menteeLastName';
              final menteeEmail = request['mentee']?['email'] ?? 'Unknown';

              Widget slotDetailsWidget;
              if (request['slot'] != null) {
                if (request['slot'] is Map) {
                  final slotMap = request['slot'];
                  String time = slotMap['time'] ?? 'No time info';
                  String price = slotMap['price'] != null
                      ? 'Rs. ${slotMap['price']}/month'
                      : '';
                  String type = slotMap['type'] ?? '';
                  slotDetailsWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time: $time', style: const TextStyle(fontSize: 14)),
                      if (price.isNotEmpty)
                        Text('Price: $price',
                            style: const TextStyle(fontSize: 14)),
                      if (type.isNotEmpty)
                        Text('Type: $type',
                            style: const TextStyle(fontSize: 14)),
                    ],
                  );
                } else if (request['slot'] is String) {
                  List<String> parts = request['slot'].toString().split(' - ');
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
                    slotDetailsWidget = Text(request['slot'],
                        style: const TextStyle(fontSize: 14));
                  }
                } else {
                  slotDetailsWidget = const Text(
                    'No slot selected',
                    style: TextStyle(fontSize: 14),
                  );
                }
              } else if (request['slotId'] != null) {
                final matchingSlot = communitySlots.firstWhere(
                  (slot) => slot['_id'] == request['slotId'],
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
                        Text('Price: $price',
                            style: const TextStyle(fontSize: 14)),
                      if (type.isNotEmpty)
                        Text('Type: $type',
                            style: const TextStyle(fontSize: 14)),
                    ],
                  );
                } else {
                  slotDetailsWidget = const Text(
                    'No slot selected',
                    style: TextStyle(fontSize: 14),
                  );
                }
              } else {
                slotDetailsWidget = const Text(
                  'No slot selected',
                  style: TextStyle(fontSize: 14),
                );
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menteeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: $menteeEmail',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      const Text(
                        'Slot Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      slotDetailsWidget,
                      const SizedBox(height: 12),
                      if (request['message'] != null &&
                          request['message'].toString().trim().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['message'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _quickUpdateRequestStatus(index, 'accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Accept',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () =>
                                _quickUpdateRequestStatus(index, 'rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Reject',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // Build the Profile Screen
  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Setting',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.account_circle, color: Colors.teal),
          title: const Text('My Profile'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MentorProfileEditPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.schedule, color: Colors.teal),
          title: const Text('View Availability'),
          onTap: () async {
            await Get.to(() => const ViewAvailabilityScreen());
            _fetchAvailability(); // Refresh community slots on return
          },
        ),
        ListTile(
          leading: const Icon(Icons.star, color: Colors.teal),
          title: const Text('My Mentees'),
          onTap: () async {
            await Get.to(() => const MenteesListScreen());
          },
        ),
        ListTile(
          leading: const Icon(Icons.payment, color: Colors.teal),
          title: const Text('Payment History'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: _logout,
        ),
      ],
    );
  }

  void showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }
}
