import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
// import 'onboarding_screen.dart'; // অনবোর্ডিং থাকলে এটা আনকমেন্ট করবে

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // ⏳ ৩ সেকেন্ড পর চেক করবে ইউজার লগইন করা আছে কিনা
    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  // 🧠 মাস্টারমাইন্ড রাউটিং লজিক
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 💾 ক্যাশ থেকে চেক করছে ইউজার লগইন করা কিনা
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // ✅ যদি আগে থেকেই লগইন করা থাকে, সোজা Home Screen-এ যাও
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // ❌ যদি লগইন করা না থাকে, Login Screen-এ যাও
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6D00), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/logo.png', // 🖼️ তোমার লোগো
              width: 150, 
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}