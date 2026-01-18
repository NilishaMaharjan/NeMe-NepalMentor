import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'http://localhost:3000'; // Replace with your backend URL if necessary

  // Get the stored token (if available)
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Assuming you store the token as 'token'
  }

  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Save mentee name and token locally after successful login
      await saveMenteeName(responseData['menteeName']);
      await _saveToken(responseData['token']); // Save JWT token

      return responseData; // Return the response data
    } else {
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  // Function to save mentee name in SharedPreferences
  Future<void> saveMenteeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mentee_name', name);
  }

  // Save JWT token in SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get all mentors
  Future<List<dynamic>> getUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/admin/mentors');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return list of mentors
    } else {
      throw Exception('Failed to load mentors: ${response.reasonPhrase}');
    }
  }

  // Get all mentees
  Future<List<dynamic>> getMentees() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/admin/mentees');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return list of mentees
    } else {
      throw Exception('Failed to load mentees: ${response.reasonPhrase}');
    }
  }

  // Get all requests
  Future<List<dynamic>> getRequests() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/admin/requests');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return list of requests
    } else {
      throw Exception('Failed to load requests: ${response.reasonPhrase}');
    }
  }

  // Get reviews for a specific mentor
  Future<Map<String, dynamic>> getReviewsForMentor(String mentorId, {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/reviews/$mentorId?page=$page&limit=$limit');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return the reviews data
    } else {
      throw Exception('Failed to load reviews: ${response.reasonPhrase}');
    }
  }

  // Delete user (either mentor or mentee)
  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/admin/users/$userId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.reasonPhrase}');
    }
  }

  // Delete request
  Future<void> deleteRequest(String requestId) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/admin/requests/$requestId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'}, // Add Authorization header
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete request: ${response.reasonPhrase}');
    }
  }
}
