import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🚪 লগআউট লজিক: ক্যাশ ক্লিয়ার করে লগইন স্ক্রিনে পাঠিয়ে দিবে
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 💾 ক্যাশ আপডেট

    if (context.mounted) {
      // 🚀 অ্যাপের সব হিস্ট্রি ডিলিট করে লগইন পেজে পাঠাবে
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KothaBook", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context), // 🚪 লগআউটে ক্লিক করলে কাজ করবে
          )
        ],
      ),
      body: Center(
        child: Text(
          "Welcome to Home Screen! 🌍",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}