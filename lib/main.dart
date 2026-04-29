import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🚀 তোমার ফোল্ডার স্ট্রাকচার অনুযায়ী সব ইমপোর্ট
import 'screens/intro/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
// import 'screens/intro/onboarding_screen.dart'; // যদি এই ফাইলটা থাকে তবে আনকমেন্ট করো

void main() {
  // নিশ্চিত করা হচ্ছে যে ফ্লাটার বাইন্ডিং প্রপারলি ইনিশিয়ালাইজ হয়েছে
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KothaBookApp());
}

class KothaBookApp extends StatelessWidget {
  const KothaBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KothaBook',
      debugShowCheckedModeBanner: false, // 🚀 ডানপাশের DEBUG ব্যানারটি রিমুভ করা হলো
      
      // 🎨 অ্যাপের মেইন অরেঞ্জ থিম কনফিগারেশন
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF6D00),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6D00),
          primary: const Color(0xFFFF6D00),
        ),
        scaffoldBackgroundColor: Colors.white,
        
        // 🖋️ পুরো অ্যাপে Poppins ফন্ট সেট করা হলো
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        
        // ইনপুট বক্সের গ্লোবাল ডিজাইন
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
          ),
        ),
      ),

      // 🚀 ম্যাজিক লাইন: এখানে SplashScreen দিয়েছি যাতে অ্যাপ শুরুতেই এটা লোড করে
      home: const SplashScreen(),
    );
  }
}