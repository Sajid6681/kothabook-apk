import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';

class ProfileController {
  // 🚀 ডাটাবেসে ডাটা পাঠানোর মাস্টার ফাংশন
  Future<bool> uploadProfileData({
    required String firstName,
    required String lastName,
    required String username,
    required String city,
    required String hometown,
    required String school,
    required String major,
    required String classYear,
    required String workPlace,
    required String workTitle,
    required String workWebsite,
    File? profileImage,
    File? coverImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/profile/setup'),
      );

      // 🔐 অথেনটিকেশন টোকেন
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 📦 টেক্সট ডাটা প্যাকেজিং
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['username'] = username;
      request.fields['city'] = city;
      request.fields['hometown'] = hometown;
      request.fields['school'] = school;
      request.fields['major'] = major;
      request.fields['class_year'] = classYear;
      request.fields['work_place'] = workPlace;
      request.fields['work_title'] = workTitle;
      request.fields['work_website'] = workWebsite;

      // 🖼️ ইমেজ আপলোড
      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', profileImage.path));
      }
      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
      }

      // 🚀 সার্ভারে সেন্ড করা হচ্ছে
      var streamedResponse = await request.send();
      
      // স্ট্যাটাস ২০০ বা ২০১ হলে ট্রু (সাকসেস) রিটার্ন করবে
      return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;

    } catch (e) {
      print("Profile Upload Error: $e");
      return false; // এরর হলে ফলস রিটার্ন করবে
    }
  }
}