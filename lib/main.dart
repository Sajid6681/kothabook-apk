import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌍 Multi-language প্যাকেজ

// 🚀 Core Imports
import 'core/theme/app_theme.dart';

// 🚀 Screens Imports
// TODO: তোমার ফাইল অনুযায়ী নিচের লোকেশনগুলো ঠিক করে নিও
import 'screens/intro/splash_screen.dart'; // হোম স্ক্রিন ইম্পোর্ট
// import 'features/splash/splash_screen.dart';

void main() async {
  // ১. ফ্লাটার ইঞ্জিন স্টার্ট করা
  WidgetsFlutterBinding.ensureInitialized();

  // ২. Multi-language (লোকালাইজেশন) ইঞ্জিন স্টার্ট করা
  await EasyLocalization.ensureInitialized();

  runApp(
    // ৩. অ্যাপকে ভাষার চাদরে মুড়িয়ে দেওয়া
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('bn')], // ইংরেজি ও বাংলা
      path: 'assets/translations', // 📁 যেখানে ভাষার JSON ফাইলগুলো থাকবে
      fallbackLocale: const Locale(
        'en',
      ), // কোনো ভাষা খুঁজে না পেলে ডিফল্ট ইংরেজি
      child: const KothaBookApp(),
    ),
  );
}

class KothaBookApp extends StatelessWidget {
  const KothaBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KothaBook',
      debugShowCheckedModeBanner:
          false, // 🚀 ডানপাশের DEBUG ব্যানারটি রিমুভ করা হলো
      // 🌍 Multi-language কানেকশন
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🎨 স্মার্ট থিম ইঞ্জিন কানেকশন (ম্যাজিক!)
      themeMode:
          ThemeMode.system, // ফোনের সেটিংস অনুযায়ী অটোমেটিক ডার্ক/লাইট মোড হবে!
      theme: AppTheme.lightTheme, // লাইট মোডের ডিজাইন
      darkTheme: AppTheme.darkTheme, // ডার্ক মোডের ডিজাইন
      // 🚀 প্রথম স্ক্রিন (এখানে তুমি চাইলে Splash Screen দিতে পারো)
      home: const SplashScreen(),
    );
  }
}
