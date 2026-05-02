import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💾 সেশন সেভ করার জন্য

import '../widgets/custom_popup.dart'; // 🚨 গ্লোবাল পপআপ
import 'signup_screen.dart';
import 'forgot_password_screen.dart'; // 🔑 ফরগট পাসওয়ার্ড স্ক্রিন
import '../home/home_screen.dart'; // 🏠 হোম স্ক্রিন

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // 🎛️ Admin Panel Simulator (ভবিষ্যতে API থেকে আসবে)
  // Options: 'both', 'number', 'email'
  final String _adminMode = 'both'; 

  final int _maxPhoneLength = 15;
  final int _minPhoneLength = 7;

  // ─── স্মার্ট কন্টাক্ট চেঞ্জ হ্যান্ডলার (Smart Input Limiter) ───
  void _handleContactChange(String val) {
    if (_adminMode == 'number') {
      // 🚨 নাম্বার মোডে '@' টাইপ করলে পপআপ দিবে
      if (val.contains('@')) {
        _contactController.text = val.replaceAll('@', '');
        _contactController.selection = TextSelection.fromPosition(TextPosition(offset: _contactController.text.length));
        _showErrorPopup("Currently, email login is disabled. Please enter your mobile number.");
      } 
      // 🛡️ ১৫ ডিজিটের বেশি টাইপ করতে দিবে না
      else if (val.length > _maxPhoneLength) {
        _contactController.text = val.substring(0, _maxPhoneLength);
        _contactController.selection = TextSelection.fromPosition(TextPosition(offset: _maxPhoneLength));
      }
    } else if (_adminMode == 'email') {
      // 🚨 ইমেইল মোডে শুধু নাম্বার টাইপ করলে পপআপ দিবে
      if (RegExp(r'^\d{4}$').hasMatch(val)) {
        _contactController.clear();
        _showErrorPopup("Currently, mobile login is disabled. Please enter your email address.");
      }
    }
    setState(() {}); // UI আপডেট করবে
  }

  // 🚨 গ্লোবাল পপআপ কল করার ফাংশন
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomPopup(
          title: "Invalid Input",
          message: message,
          onOkay: () => Navigator.of(context).pop(), // পপআপ কাটার লজিক
        );
      },
    );
  }

  // ─── ভ্যালিডেশন লজিক ───
  bool get _isEmailValid => _contactController.text.contains('@') && _contactController.text.contains('.');
  bool get _isMobileValid => RegExp(r'^\d+$').hasMatch(_contactController.text) && 
                             _contactController.text.length >= _minPhoneLength;

  bool get _isContactValid {
    if (_adminMode == 'both') return _isEmailValid || _isMobileValid;
    if (_adminMode == 'number') return _isMobileValid;
    if (_adminMode == 'email') return _isEmailValid;
    return false;
  }

  bool get _isPasswordValid => _passwordController.text.length >= 8;
  bool get _isFormValid => _isContactValid && _isPasswordValid;

  // ─── লগইন লজিক ───
  Future<void> _handleLogin() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    // ⏳ TODO: Connect to Node.js backend
    await Future.delayed(const Duration(seconds: 2));

    // 💾 লগইন সফল হলে ক্যাশে সেভ করে রাখবো
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    setState(() => _isLoading = false);

    if (mounted) {
      // 🚀 হোম স্ক্রিনে পাঠিয়ে দেওয়া এবং পেছনের সব স্ক্রিন রিমুভ করা
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const HomeScreen()), 
        (route) => false
      );
    }
  }

  // ─── UI Helpers ───
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // 🌟 Text Logo
                Image.asset(
                  'assets/logo/text_logo.png', // তোমার টেক্সট লোগো
                  height: 45,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  _adminMode == 'both' 
                    ? "Enter your email or mobile number." 
                    : "Enter your ${_adminMode == 'email' ? 'email address' : 'mobile number'}.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 40),

                // 🧠 স্মার্ট কন্টাক্ট ফিল্ড
                TextField(
                  controller: _contactController,
                  keyboardType: _adminMode == 'number' ? TextInputType.phone : TextInputType.text,
                  onChanged: _handleContactChange,
                  decoration: _inputDecoration(
                    _adminMode == 'both' ? "Email or Mobile Number" : 
                    _adminMode == 'email' ? "Enter Email Address" : 
                    "Enter Mobile Number",
                    Icons.person_outline
                  ),
                ),
                const SizedBox(height: 20),

                // 🔒 পাসওয়ার্ড ফিল্ড
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (val) => setState(() {}),
                  decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                
                // 🛡️ স্মার্ট পাসওয়ার্ড ট্র্যাকার (UX Masterpiece)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPasswordValid ? Icons.check_circle : Icons.error_outline,
                            size: 14,
                            color: _isPasswordValid ? Colors.green : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Minimum 8 characters", 
                            style: GoogleFonts.poppins(
                              fontSize: 11, 
                              fontWeight: FontWeight.w500,
                              color: _isPasswordValid ? Colors.green : Colors.grey.shade500,
                            )
                          ),
                        ],
                      ),
                      
                      // 🔑 Forgot Password Navigation
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                        },
                        child: Text(
                          "Forgot Password?", 
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🚀 Login Button
                ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _isFormValid ? 4 : 0,
                    shadowColor: const Color(0xFFFF6D00).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("LOGIN", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _isFormValid ? Colors.white : Colors.grey[400])),
                ),
                const SizedBox(height: 30),

                // 📝 Signup Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                      },
                      child: Text("Sign Up", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}