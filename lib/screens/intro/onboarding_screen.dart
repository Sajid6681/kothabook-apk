import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💾 ক্যাশ মেমোরির জন্য
// import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../widgets/custom_button.dart';
// import '../auth/signup_screen.dart'; // সাইনআপ স্ক্রিন বানালে এটা আনকমেন্ট করবে

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Welcome to KothaBook",
      "desc": "Connect with friends, family and people who share your interests.",
      "image": "assets/intro/onboard_1.png" 
    },
    {
      "title": "Smart AI Feed",
      "desc": "Experience a personalized feed powered by our advanced AI system.",
      "image": "assets/intro/onboard_2.png" 
    },
    {
      "title": "Hyper-Local Marketplace",
      "desc": "Buy and sell items perfectly matched to your current location.",
      "image": "assets/intro/onboard_3.png" 
    },
  ];

  // 🧠 ক্যাশে সেভ করে সোজা সাইনআপে পাঠানোর ফাংশন
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 💾 ক্যাশে সেভ করে রাখলাম যে ইউজার অনবোর্ডিং দেখে ফেলেছে (False করে দিলাম)
    await prefs.setBool('isFirstTime', false);
    
    if (mounted) {
      // ➡️ সোজা Signup স্ক্রিনে পাঠিয়ে দাও
      // TODO: Signup স্ক্রিন বানালে নিচের লাইনটা আনকমেন্ট করে ঠিক করে নিও
      /*
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupScreen()),
      );
      */
      print("➡️ Sending to Signup Screen...");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ⏭️ Skip বাটন
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding, // স্কিপ করলে ক্যাশে সেভ হয়ে সাইনআপে যাবে
                child: Text(
                  "Skip",
                  style: AppTextStyles.bodyText(AppColors.primaryOrange),
                ),
              ),
            ),
            
            // 📱 পেজ স্লাইডার
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          onboardingData[index]["image"]!,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1(
                            isDarkMode ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyText(
                            isDarkMode ? AppColors.darkSubText : AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔵 ডট ইন্ডিকেটর
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _currentPage == index ? 25 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryOrange
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // 🔘 নেক্সট বা স্টার্ট বাটন
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: CustomButton( 
                text: _currentPage == onboardingData.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: () {
                  if (_currentPage == onboardingData.length - 1) {
                    _completeOnboarding(); // শেষ পেজে আসলে ক্যাশে সেভ হয়ে সাইনআপে যাবে
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}