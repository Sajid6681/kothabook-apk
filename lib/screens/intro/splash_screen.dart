import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🎭 লোগোর জন্য অরিজিনাল পপ-আপ অ্যানিমেশন
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    _checkAppFlow();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🧠 সাজিদ বেবির সেই মাস্টারমাইন্ড লজিক:
  _checkAppFlow() async {
    await Future.delayed(const Duration(seconds: 3));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      // সোজা হোম স্ক্রিনে যাবে
    } else {
      if (isFirstTime) {
        // ১ম বার: Splash -> Onboarding (৩টি স্টেপ)
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const OnboardingScreen())
        );
      } else {
        // ২য় বার থেকে: Splash -> Login
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
      backgroundColor: const Color(0xFFFF6D00), // KothaBook Signature Orange
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 2)
                  ]
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFFF6D00), size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                'KothaBook',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CONNECT. SHARE. ENJOY.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}