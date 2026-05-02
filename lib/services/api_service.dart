import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🚀 POST রিকোয়েস্ট পাঠানোর জেনেরিক ফাংশন
  static Future<http.Response> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      // 🚀 সার্ভার ডাউন বা নেট না থাকলে এই কাস্টম এরর থ্রো করবে
      throw Exception("Check your internet connection");
    }
  }
}