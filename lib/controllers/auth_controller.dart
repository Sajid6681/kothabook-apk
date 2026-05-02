import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart'; // তোমার API লিংক ফাইল

class AuthController {
  
  // ==========================================
  // 🚀 ১. Signup Logic (সার্ভারে ডাটা পাঠানো)
  // ==========================================
  Future<Map<String, dynamic>> signupUser({
    required String firstName,
    required String lastName,
    required String username,
    required String contact, // Email or Phone
    required String password,
    required String dob,
    required String gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'contact': contact,
          'password': password,
          'dob': dob,
          'gender': gender,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Signup failed!'};
      }
    } catch (e) {
      print("Signup Error: $e");
      return {'success': false, 'message': 'Network error! Check your internet connection.'};
    }
  }

  // ==========================================
  // 🔐 ২. Login Logic (সার্ভার থেকে টোকেন আনা)
  // ==========================================
  Future<Map<String, dynamic>> loginUser({
    required String contact,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      // যদি লগইন সাকসেস হয়
      if (response.statusCode == 200 && responseData['success'] == true) {
        
        // 🎟️ টোকেন এবং ইউজারের ডাটা সেভ করা (যাতে বারবার লগইন করতে না হয়)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString('userId', responseData['user']['id'].toString());
        await prefs.setString('username', responseData['user']['username']);

        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Invalid credentials!'};
      }
    } catch (e) {
      print("Login Error: $e");
      return {'success': false, 'message': 'Network error! Check your internet connection.'};
    }
  }
}