import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'conf_ip.dart';

class RequestPage extends StatefulWidget {
  final String mentorId; // Mentor's id
  final String slotTime; // The selected time slot (display text)
  final String slotId; // The actual slot ID
  final String slotPrice; // Price for the slot (e.g., "500")
  final String slotType; // Type for the slot (e.g., "Home Tuition" or "Online")

  const RequestPage({
    Key? key,
    required this.mentorId,
    required this.slotTime,
    required this.slotId,
    required this.slotPrice,
    required this.slotType,
  }) : super(key: key);

  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  bool isLoading = false; // For showing a loading spinner
  String? errorMessage; // For displaying errors
  String? mentorUserId; // Mentor's user ID
  final TextEditingController messageController =
      TextEditingController(); // Controller for optional message

  @override
  void initState() {
    super.initState();
    _fetchMentorUserId(); // Fetch the mentor's user ID
  }

  Future<void> _fetchMentorUserId() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String apiUrl = '$baseUrl/api/mentors/${widget.mentorId}';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Mentor data received: $data");

        // Fetch the mentor user ID from the response
        setState(() {
          mentorUserId =
              data['user']?['_id']; // Fetch the user._id from the response
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch mentor user ID.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching mentor user ID.';
        isLoading = false;
      });
    }
  }

  Future<void> sendRequest() async {
    if (mentorUserId == null) {
      setState(() {
        errorMessage = 'Mentor user ID not available.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        setState(() {
          errorMessage = 'User ID not found. Please log in again.';
        });
        return;
      }

      String apiUrl = '$baseUrl/api/requests';

      // Build the request payload. The slot details now include price and type.
      Map<String, String> requestBody = {
        'mentor': mentorUserId!, // Fetched mentor user ID
        'userId': userId, // Mentee's user ID
        'slotId': widget.slotId, // The actual slot ID
        'slot':
            'Rs. ${widget.slotPrice}/month - ${widget.slotType} - ${widget.slotTime}',
      };

      // Include message while requesting (optional)
      if (messageController.text.trim().isNotEmpty) {
        requestBody['message'] = messageController.text.trim();
      }
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Session Request has been sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your request has been successfully submitted, and you will be notified once the mentor confirms or declines your request. Thank you for your patience!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Dashboard(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Thanks, will do',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        setState(() {
          errorMessage = responseData['error'] ?? 'Failed to send request.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to send request. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again later.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Request Detail'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.black,
      ),
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Slot Display
                  Text(
                    'Selected Slot:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.slotTime,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Display Slot Price and Type
                  Text(
                    'Slot Details:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: Rs. ${widget.slotPrice}/month',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${widget.slotType}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Optional Additional Message
                  Text(
                    'Additional Message (optional):',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter any additional message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const Spacer(),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: isLoading || mentorUserId == null
                            ? null
                            : sendRequest,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Send Request',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}