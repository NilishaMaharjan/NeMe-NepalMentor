import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // For navigation
import 'package:http/http.dart' as http; // For HTTP requests
import 'conf_ip.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To store token locally
import 'signup.dart'; // Signup page import
import 'forgetpw.dart'; // Forgot password page import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool isMentee = true; // Track role selection (Mentee/Mentor)
  bool _isPasswordVisible = false; // Password visibility toggle
  final TextEditingController emailController =
      TextEditingController(); // Email input
  final TextEditingController passwordController =
      TextEditingController(); // Password input

  // Function to perform login and call backend API
  Future<void> loginUser() async {
    final email = emailController.text;
    final password = passwordController.text;
    final role = isMentee ? 'mentee' : 'mentor'; // Use selected role

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'), // My IP address
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );


      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String token = data['token'];
        String userId = data['userId'];

        // Store token using shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        // Conditional navigation based on role
        if (role == 'mentor') {
          Get.offNamed('/mentordashboard'); // Navigate to mentor dashboard
        } else {
          Get.offNamed('/dashboard'); // Navigate to mentee dashboard
        }
      } else {
        Get.snackbar('Error', 'Login failed: ${response.body}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Role Selection Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildRoleTab('I\'m a mentee', isMentee),
                    buildRoleTab('I\'m a mentor', !isMentee),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Email Input
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email or username',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    floatingLabelStyle: TextStyle(color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Password Input
                TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    floatingLabelStyle: const TextStyle(color: Colors.teal),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Login Button
                Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ElevatedButton(
                    onPressed: loginUser, // Call login function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),

                // Forgot Password Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 16.0),

                const Text(
                  "Don't have an account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0),
                ),
                const SizedBox(height: 8.0),

                // Signup and Mentor Application Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up as a mentee',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(' or ', style: TextStyle(fontSize: 14.0)),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed('/mentorregistration');
                      },
                      child: const Text(
                        'apply to be a mentor',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build Role Tabs
  Widget buildRoleTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isMentee = title.contains('mentee');
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.teal : Colors.grey,
              ),
            ),
            const SizedBox(height: 4.0),
            if (isSelected)
              Container(
                height: 2.0,
                width: 80.0,
                color: Colors.teal,
              ),
          ],
        ),
      ),
    );
  }
}