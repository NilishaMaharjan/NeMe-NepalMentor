import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'conf_ip.dart';

class CommunityChatScreen extends StatefulWidget {
  final dynamic slot;
  final String receiverId;

  const CommunityChatScreen({
    Key? key,
    required this.slot,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  late IO.Socket socket;
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  String? senderId;
  late String slotId;
  late String slotTime;

  @override
  void initState() {
    super.initState();
    slotId = widget.slot['_id'].toString();
    slotTime = widget.slot['time'] ?? 'Unknown slot';

    _getSenderId().then((_) {
      _connectSocket();
    });
  }

  Future<void> _getSenderId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      senderId = prefs.getString('userId');
    });
  }

  void _connectSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    socket.onConnect((_) {
      if (senderId != null && slotId.isNotEmpty) {
        socket.emit("joinRoom", {"slotId": slotId, "userId": senderId});
      }
    });

    socket.on("previousMessages", (data) {
      setState(() {
        messages = List<dynamic>.from(data);
      });
    });

    socket.on("receiveMessage", (data) {
      setState(() {
        messages.add(data);
      });
    });

    socket.onDisconnect((_) {
      print("Disconnected from socket");
    });
  }

  void _sendMessage() {
    if (messageController.text.trim().isEmpty) return;
    final messageData = {
      "slotId": slotId,
      "sender": senderId,
      "receiver": widget.receiverId,
      "message": messageController.text.trim(),
    };
    socket.emit("sendMessage", messageData);
    messageController.clear();
  }

  @override
  void dispose() {
    socket.dispose();
    messageController.dispose();
    super.dispose();
  }

  // Updated to use launchUrl/canLaunchUrl
  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri url = Uri.parse(link.url);

    if (await canLaunchUrl(url)) {
      // Launch in an external application (browser)
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
      appBar: AppBar(
        title: Text("Chat - $slotTime"),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.grey[50],
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
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];

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

                          bool isSentByMe = false;
                          String senderName = "";
                          String senderRole = "";
                          bool senderIsMentor = false;

                          if (msg['sender'] is Map) {
                            isSentByMe = msg['sender']['_id'] == senderId;
                            senderRole = msg['sender']['role'] ?? '';
                            senderIsMentor =
                                senderRole.toLowerCase() == 'mentor';
                            senderName =
                                "${msg['sender']['firstName']} ${msg['sender']['lastName']} ($senderRole)";
                          } else {
                            isSentByMe = msg['sender'] == senderId;
                          }

                          Color bubbleColor =
                              isSentByMe ? Colors.teal : Colors.teal.shade100;
                          final textColor =
                              isSentByMe ? Colors.white : Colors.black87;

                          Widget senderInfo(bool showLogo) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showLogo)
                                    const CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      child: Icon(Icons.school,
                                          color: Colors.white, size: 16),
                                      radius: 12,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Use SelectableLinkify to make URLs clickable.
                          Widget messageBubble = Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: bubbleColor,
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
                                color: textColor,
                                fontSize: 18,
                                height: 1.4,
                              ),
                              linkStyle: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );

                          if (isSentByMe) {
                            return Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  senderInfo(senderIsMentor),
                                  messageBubble,
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              alignment: Alignment.centerLeft,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  senderInfo(false),
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
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: _sendMessage,
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