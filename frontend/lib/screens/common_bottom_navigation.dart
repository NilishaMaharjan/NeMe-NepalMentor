import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'mentee_chat_page.dart';
import 'menteeprofile_edit.dart';
import 'session_history.dart';
import 'my_mentors.dart';
import 'conf_ip.dart';

class CommonBottomNavigation extends StatefulWidget {
  final Widget? sectionContent;
  final String? sectionTitle;
  final bool startWithSectionContent;

  const CommonBottomNavigation({
    Key? key,
    this.sectionContent,
    this.sectionTitle,
    this.startWithSectionContent = false,
  }) : super(key: key);

  @override
  _CommonBottomNavigationState createState() => _CommonBottomNavigationState();
}

class _CommonBottomNavigationState extends State<CommonBottomNavigation> {
  int _selectedIndex = 0;
  bool isSectionActive = false;
  final Color themeColor = const Color.fromARGB(255, 47, 161, 150);

  // Global pages (4 items):
  final List<Widget> _globalPages = [
    const Dashboard(), // index 0: Learning Dashboard (Home)
    const CommunitySlotsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _globalTitles = [
    "Learning Dashboard",
    "My Community",
    "Notifications",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    // Activate section mode only if sectionContent is provided and flag is true.
    isSectionActive =
        widget.startWithSectionContent && widget.sectionContent != null;
  }

  @override
  void didUpdateWidget(CommonBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget updates and section mode is desired, reset it.
    if (widget.startWithSectionContent && widget.sectionContent != null) {
      isSectionActive = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If section mode is active and a section title is provided, use that title.
    String appBarTitle = isSectionActive && widget.sectionContent != null
        ? (widget.sectionTitle ?? "Section")
        : _globalTitles[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: themeColor,
        // Show a back arrow on non‑Home global pages when not in section mode.
        leading: (!isSectionActive && _selectedIndex != 0)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              )
            : null,
      ),
      // If in section mode and sectionContent is provided, show it; otherwise, show the corresponding global page.
      body: isSectionActive && widget.sectionContent != null
          ? widget.sectionContent!
          : _globalPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Tapping any bottom navigation item disables section mode.
          setState(() {
            isSectionActive = false;
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups), label: 'My Community'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}

// CommunitySlotsScreen
class CommunitySlotsScreen extends StatefulWidget {
  const CommunitySlotsScreen({Key? key}) : super(key: key);

  @override
  _CommunitySlotsScreenState createState() => _CommunitySlotsScreenState();
}

class _CommunitySlotsScreenState extends State<CommunitySlotsScreen> {
  List<dynamic> acceptedSlots = [];
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserIdAndFetchSlots();
  }

  Future<void> _getUserIdAndFetchSlots() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    await _fetchAcceptedSlots();
  }

  Future<void> _fetchAcceptedSlots() async {
    if (userId == null) return;
    setState(() {
      isLoading = true;
    });
    final requestUrl = '$baseUrl/api/requests/mentee/accepted?userId=$userId';
    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            acceptedSlots = data;
          });
        } else {
          print("No accepted slots found for user: $userId");
        }
      } else {
        print("Failed to fetch accepted slots: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching accepted slots: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, String>> getSlotInfo(dynamic slotData) async {
    try {
      String? slotId = slotData['slotId'];
      if (slotId == null) {
        if (slotData.containsKey('_id')) {
          slotId = slotData['_id'];
        } else if (slotData.containsKey('slot')) {
          final dynamic slotObj = slotData['slot'];
          if (slotObj is Map<String, dynamic>) {
            slotId = slotObj['_id'];
          }
        }
      }
      if (slotId == null) {
        print("Slot id not found in slotData: $slotData");
        return {
          "mentor": "Unknown Mentor",
          "slotTime": "N/A",
          "subject": "N/A"
        };
      }
      final availResponse =
          await http.get(Uri.parse('$baseUrl/api/availability/slot/$slotId'));
      if (availResponse.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(availResponse.body);
        final String slotTime =
            (result.containsKey('slot') && result['slot'] is Map)
                ? (result['slot']['time'] ?? "N/A")
                : "N/A";
        final String? mentorUserId = result['mentorUserId'];
        if (mentorUserId != null && mentorUserId.isNotEmpty) {
          final mentorResponse =
              await http.get(Uri.parse('$baseUrl/api/mentors/$mentorUserId'));
          if (mentorResponse.statusCode == 200) {
            final Map<String, dynamic> mentor =
                json.decode(mentorResponse.body);
            String mentorName = "Unknown Mentor";
            if (mentor['firstName'] != null && mentor['lastName'] != null) {
              mentorName = "${mentor['firstName']} ${mentor['lastName']}";
            }
            String subjectStr = "N/A";
            if (mentor.containsKey('subjects')) {
              if (mentor['subjects'] is List && mentor['subjects'].isNotEmpty) {
                subjectStr = mentor['subjects'][0];
              } else if (mentor['subjects'] is String) {
                subjectStr = mentor['subjects'];
              }
            }
            return {
              "mentor": mentorName,
              "slotTime": slotTime,
              "subject": subjectStr
            };
          }
        }
      }
    } catch (e) {
      print("Error in getSlotInfo: $e");
    }
    return {"mentor": "Unknown Mentor", "slotTime": "N/A", "subject": "N/A"};
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : acceptedSlots.isEmpty
            ? const Center(child: Text("No accepted slots available"))
            : ListView.builder(
                itemCount: acceptedSlots.length,
                itemBuilder: (context, index) {
                  final slotData = acceptedSlots[index];
                  return FutureBuilder<Map<String, String>>(
                    future: getSlotInfo(slotData),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        return const ListTile(
                          title: Text("Error loading slot info"),
                        );
                      } else {
                        final slotInfo = snapshot.data!;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenteeChatScreen(
                                    slot: slotData,
                                    receiverId: "", // Adjust as needed.
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.subject,
                                            color: Colors.teal, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "SUBJECT: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                              fontSize: 16),
                                        ),
                                        Expanded(
                                          child: Text(
                                            slotInfo["subject"] ?? "N/A",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.teal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: Colors.teal, size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "TIME-SLOT: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                            fontSize: 14),
                                      ),
                                      Expanded(
                                        child: Text(
                                          slotInfo["slotTime"] ?? "N/A",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.teal, size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "MENTOR: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                            fontSize: 14),
                                      ),
                                      Expanded(
                                        child: Text(
                                          slotInfo["mentor"] ??
                                              "Unknown Mentor",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
  }
}

// --------------------------
// NotificationsScreen
// --------------------------
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationsFromLocalStorage();
    fetchNotifications();
  }

  Future<void> _loadNotificationsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedNotifications = prefs.getString('notifications');
    if (savedNotifications != null) {
      setState(() {
        notifications =
            List<Map<String, dynamic>>.from(jsonDecode(savedNotifications));
      });
    }
  }

  Future<void> _saveNotificationsToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(notifications));
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> fetchNotifications() async {
    String? userId = await getUserId();
    if (userId == null) return;
    final url = Uri.parse('$baseUrl/api/requests/notifications/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedNotifications = json.decode(response.body);
        setState(() {
          notifications = fetchedNotifications.cast<Map<String, dynamic>>();
        });
        _saveNotificationsToLocalStorage();
      } else {
        print(
            "Failed to fetch notifications. Status Code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching notifications: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return notifications.isEmpty
        ? const Center(child: Text("No notifications available"))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 1,
                child: ListTile(
                  // Removed the onTap that navigated to the Esewa screen.
                  leading: const Icon(Icons.notifications, color: Colors.teal),
                  title: Text(
                    notifications[index]['message'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            },
          );
  }
}

// --------------------------
// ProfileScreen
// --------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Widget _buildProfileOption(IconData icon, String title,
      [void Function()? onTap]) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setting',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildProfileOption(Icons.person, 'My Profile', () async {
            String? userId = await getUserId();
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileEditPage(userId: userId)),
              );
            }
          }),
          _buildProfileOption(Icons.history, 'Session History', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SessionHistoryPage()),
            );
          }),
          _buildProfileOption(Icons.star_border, 'My Mentors', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyMentorsPage()),
            );
          }),
          _buildProfileOption(Icons.payment, 'Payment History'),
          const SizedBox(height: 20),
          _buildLogoutButton(),
        ],
      ),
    );
  }
}
