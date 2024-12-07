import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentService {
  static const String baseUrl = "http://10.121.97.237:5000";

  static Future<Map<String, dynamic>?> fetchStudentData(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_student_data?student_id=$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          return responseData['data'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching student data: $e");
      return null;
    }
  }
}
