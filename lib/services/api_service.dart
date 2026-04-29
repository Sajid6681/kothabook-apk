import 'dart:convert';
import 'dart:io'; // SocketException এর জন্য
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ FIX: আলাদা আলাদা error type handle করা হলো
  static Future<http.Response> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15)); // ✅ FIX: 15 সেকেন্ড timeout যোগ করা হলো
      
      return response;

    } on SocketException {
      // ইন্টারনেট নেই
      throw Exception("No internet connection");
    } on HttpException {
      // Server খুঁজে পাওয়া যাচ্ছে না
      throw Exception("Server not found. Please try again later.");
    } on FormatException {
      // Server ভুল response পাঠাচ্ছে
      throw Exception("Invalid server response.");
    } catch (e) {
      // অন্য যেকোনো error (timeout সহ)
      if (e.toString().contains('TimeoutException')) {
        throw Exception("Connection timed out. Please try again.");
      }
      throw Exception("Connection failed. Please try again.");
    }
  }
}
