import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'conf_ip.dart';

class MenteeChatScreen extends StatefulWidget {
  final dynamic slot; 
  final String receiverId;

  const MenteeChatScreen({
    Key? key,
    required this.slot,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<MenteeChatScreen> createState() => _MenteeChatScreenState();
}

class _MenteeChatScreenState extends State<MenteeChatScreen> {
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  String? menteeId;
  String? slotId; // Currently selected slot identifier.
  List<dynamic> acceptedSlots = []; // List of accepted slot requests.
  IO.Socket? socket;

  // Profile details of the current user.
  String? firstName;
  String? lastName;
  String? role;

  @override
  void initState() {
    super.initState();
    if (widget.slot != null) {
      setState(() {
        acceptedSlots = [widget.slot];
        slotId = widget.slot is Map ? widget.slot['slotId'] : widget.slot;
      });
    }
    _getMenteeId();
  }

  Future<void> _getMenteeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      menteeId = prefs.getString('userId');
    });
    if (menteeId != null) {
      _getUserProfile();
      _fetchAcceptedRequests();
    } else {
      print("Mentee ID is null");
    }
  }

  Future<void> _getUserProfile() async {
    if (menteeId == null) return;
    final url = Uri.parse('$baseUrl/api/mentees/$menteeId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(response.body);
        setState(() {
          firstName = profileData['firstName'];
          lastName = profileData['lastName'];
          role = profileData['role'] ?? 'mentee';
        });
      } else {
        print(
            "Failed to fetch user profile. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchAcceptedRequests() async {
    if (menteeId == null) return;
    final requestUrl =
        '$baseUrl/api/requests/mentee/accepted?userId=$menteeId';
    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            acceptedSlots = data;
            slotId ??= acceptedSlots[0]['slotId'];
          });
          _fetchMessages();
          _connectSocket();
        } else {
          print("No accepted requests found for mentee: $menteeId");
        }
      } else {
        print("Failed to fetch accepted requests: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching accepted requests: $e");
    }
  }

  Future<void> _fetchMessages() async {
    if (slotId == null || slotId!.isEmpty) return;
    final messagesUrl = '$baseUrl/api/chat/$slotId';
    try {
      final response = await http.get(Uri.parse(messagesUrl));
      if (response.statusCode == 200) {
        var messageData = json.decode(response.body);
        setState(() {
          messages = messageData;
        });
      } else {
        print("Failed to fetch messages: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  void _connectSocket() {
    if (menteeId == null || slotId == null) return;
    socket?.dispose();
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();

    socket!.onConnect((_) {
      socket!.emit("joinRoom", {"slotId": slotId, "userId": menteeId});
    });

    socket!.on("joinRoomError", (data) {
      print("Join room error: $data");
    });

    socket!.on("previousMessages", (data) {
      setState(() {
        messages = data;
      });
    });

    socket!.on("receiveMessage", (data) {
      setState(() {
        messages.add(data);
      });
    });

    socket!.on("userJoined", (data) {
      setState(() {
        messages.add({
          'message': "User ${data['userId']} joined the chat.",
          'sender': "system",
        });
      });
    });

    socket!.onDisconnect((_) {
      print("Disconnected from socket");
    });
  }

  Future<void> _sendMessage() async {
    if (slotId == null || menteeId == null || messageController.text.isEmpty) {
      return;
    }
    if (socket == null) {
      return;
    }
    final messageData = {
      "slotId": slotId,
      "sender": menteeId,
      "message": messageController.text.trim(),
    };
    socket!.emit("sendMessage", messageData);
    messageController.clear();
  }

  @override
  void dispose() {
    messageController.dispose();
    socket?.dispose();
    super.dispose();
  }

  // Added link handling logic
  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri url = Uri.parse(link.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch ${link.url}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Mentee Chat",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade50, Colors.teal.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];

                          // System messages.
                          if (msg['sender'] == 'system') {
                            return Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['message'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          bool isSentByMe;
                          String senderName = "";
                          bool isMentor = false;
                          if (msg['sender'] is Map) {
                            isSentByMe = msg['sender']['_id'] == menteeId;
                            String senderRole = msg['sender']['role'] ?? '';
                            isMentor = senderRole.toLowerCase() == 'mentor';
                            senderName =
                                "${msg['sender']['firstName']} ${msg['sender']['lastName']}" +
                                    (senderRole.isNotEmpty
                                        ? " ($senderRole)"
                                        : "");
                          } else {
                            isSentByMe = msg['sender'] == menteeId;
                          }

                          // Set bubble colors.
                          Color bubbleColor;
                          BoxBorder? bubbleBorder;
                          if (msg['sender'] is Map && isMentor) {
                            bubbleColor = Colors.teal.shade50;
                            bubbleBorder =
                                Border.all(color: Colors.teal, width: 1);
                          } else {
                            bubbleColor =
                                isSentByMe ? Colors.teal : Colors.teal.shade100;
                          }

                          // Use clickable link widget for the message text.
                          Widget messageBubble = Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              border: bubbleBorder,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                )
                              ],
                            ),
                            child: SelectableLinkify(
                              onOpen: _onOpenLink,
                              text: msg['message'] ?? '',
                              style: TextStyle(
                                color: isSentByMe ? Colors.white : Colors.black87,
                                fontSize: 18,
                                height: 1.4,
                              ),
                              linkStyle: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );

                          // Layout for mentor messages
                          if (msg['sender'] is Map && isMentor) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.teal,
                                        child: Icon(Icons.school,
                                            color: Colors.white, size: 16),
                                        radius: 12,
                                      ),
                                      const SizedBox(width: 8),
                                      if (senderName.isNotEmpty)
                                        Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  messageBubble,
                                ],
                              ),
                            );
                          } else {
                            // Layout for mentee or other messages.
                            return Container(
                              alignment: isSentByMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (senderName.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        senderName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  messageBubble,
                                ],
                              ),
                            );
                          }
                        },
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.teal.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(color: Colors.teal.shade300),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}