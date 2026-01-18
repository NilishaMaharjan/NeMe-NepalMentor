import 'dart:convert';
import 'package:http/http.dart' as http;

class MentorService {
  static const String baseUrl = 'http://localhost:3000'; 

  Future<List<dynamic>> getAllMentors() async {
    final response = await http.get(Uri.parse('$baseUrl/mentors'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mentors');
    }
  }
}
