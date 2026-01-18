import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Base URL of your backend API (adjust it to your actual backend URL)
  static const String baseUrl = 'http://localhost:3000';

  // Get count of mentors and mentees
  static Future<Map<String, int>> getUserCount() async {
    final response = await http.get(Uri.parse('$baseUrl/user-count'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'mentorCount': data['mentorCount'],
        'menteeCount': data['menteeCount'],
      };
    } else {
      throw Exception('Failed to load user count');
    }
  }

  // Get all mentors
  static Future<List<dynamic>> getMentors() async {
    final response = await http.get(Uri.parse('$baseUrl/mentors'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mentors');
    }
  }

  // Get all mentees
  static Future<List<dynamic>> getMentees() async {
    final response = await http.get(Uri.parse('$baseUrl/mentees'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mentees');
    }
  }

  // Delete a user by ID
  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // Update a user by ID
  static Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }
}
