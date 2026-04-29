import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ৩টি স্টেপের ইংলিশ ডেটা
  final List<Map<String, String>> _steps = [
    {
      'icon': '📸',
      'title': 'Share Your Story',
      'desc': 'Capture your moments and share them with your inner circle effortlessly.'
    },
    {
      'icon': '💬',
      'title': 'Stay Connected',
      'desc': 'Experience real-time chatting with high-end security and speed.'
    },
    {
      'icon': '🌍',
      'title': 'Find Community',
      'desc': 'Discover interesting people around you and build meaningful relations.'
    },
  ];

  void _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const SignupScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text('Skip', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _steps.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_steps[i]['icon']!, style: const TextStyle(fontSize: 100)),
                        const SizedBox(height: 40),
                        Text(
                          _steps[i]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _steps[i]['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade500, height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator and Button
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == i ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? const Color(0xFFFF6D00) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == 2) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: const Color(0xFFFF6D00).withOpacity(0.3),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'GET STARTED' : 'NEXT STEP',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}