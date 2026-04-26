import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart'; 
import 'onboarding_screen.dart'; // অনবোর্ডিং স্ক্রিন ইম্পোর্ট করা হলো

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 🚀 প্রো-লেভেল ম্যাজিক ফাংশন: ইউজারের স্ট্যাটাস চেক করা
  _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // ২ সেকেন্ড স্প্ল্যাশ স্ক্রিন দেখাবে
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true; // প্রথমবার কি না সেটা চেক

    if (!mounted) return;

    if (isLoggedIn == true) {
      // 🟢 আগে লগইন করা থাকলে সোজা Home Screen-এ যাবে
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    } else {
      if (isFirstTime) {
        // 🔵 একদম প্রথমবার অ্যাপ ওপেন করলে Onboarding-এ যাবে
        await prefs.setBool('isFirstTime', false); // এরপর আর প্রথমবার থাকবে না
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const OnboardingScreen())
        );
      } else {
        // 🟠 প্রথমবার নয়, কিন্তু লগইনও করা নেই, তাই Login-এ যাবে
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6D00), // KothaBook এর অরেঞ্জ থিম
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFFF6D00), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'KothaBook',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
