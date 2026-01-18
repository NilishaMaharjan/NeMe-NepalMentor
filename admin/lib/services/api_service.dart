import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; 

  // Method to get mentors
  Future<List<dynamic>> getMentors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mentors'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load mentors');
      }
    } catch (e) {
      throw Exception('Failed to load mentors: $e');
    }
  }

  // Method to get mentees
  Future<List<dynamic>> getMentees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mentees'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load mentees');
      }
    } catch (e) {
      throw Exception('Failed to load mentees: $e');
    }
  }

  // Method to get user counts
  Future<Map<String, int>> getUserCounts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user-count'));
      if (response.statusCode == 200) {
        return Map<String, int>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load user counts');
      }
    } catch (e) {
      throw Exception('Failed to load user counts: $e');
    }
  }
}
