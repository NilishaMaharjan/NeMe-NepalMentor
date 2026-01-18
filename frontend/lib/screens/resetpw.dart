import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX for navigation
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import for json encoding

class ResetPasswordPage extends StatelessWidget {
  final String token; // Pass the reset token to this page
  const ResetPasswordPage({required this.token, super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter New Password',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    floatingLabelStyle: TextStyle(color: Colors.teal),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    floatingLabelStyle: TextStyle(color: Colors.teal),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24.0),
                Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      String newPassword = passwordController.text.trim();
                      String confirmPassword =
                          confirmPasswordController.text.trim();

                      // Validate the new password
                      if (newPassword.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter a new password.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        Get.snackbar(
                          'Error',
                          'Passwords do not match.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      // Call the backend API for resetting the password
                      try {
                        final response = await http.post(
                          Uri.parse(
                              'http://192.168.0.102:3000/api/auth/reset-password/$token'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({'password': newPassword}),
                        );

                        if (response.statusCode == 200) {
                          Get.snackbar(
                            'Success',
                            'Password has been reset successfully.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.white,
                            colorText: Colors.teal,
                          );

                          // Navigate back to login or another appropriate page
                          Future.delayed(const Duration(seconds: 2), () {
                            Get.offAllNamed('/login'); // Redirect to login page
                          });
                        } else {
                          final errorResponse = json.decode(response.body);
                          Get.snackbar(
                            'Error',
                            errorResponse[
                                'msg'], // Display backend error message
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'An error occurred. Please try again later.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Reset Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    // Navigate back to the login page
                    Get.back();
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
