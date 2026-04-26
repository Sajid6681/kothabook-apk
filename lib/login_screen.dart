import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'signup_screen.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false; 

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🌐 ঠিক করা লাইভ ডোমেইন (app. যুক্ত করা হয়েছে)
  final String baseUrl = "https://app.kothabook.com"; 

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToSignup() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  // ==========================================
  // 🚀 Login API কানেকশন ফাংশন
  // ==========================================
  Future<void> _loginAndGoToHome() async {
    if (_mobileController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter mobile number and password', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String apiUrl = '$baseUrl/api/login';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobileNumber": _mobileController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // 🚀 সফল লগইনের পর ডাটাবেস থেকে পাওয়া নাম্বার সেভ করা হচ্ছে
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('mobileNumber', _mobileController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'], style: GoogleFonts.poppins()), backgroundColor: Colors.green)
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Login failed!', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Login Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server connection failed!', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF6D00), size: 32),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Sign in to continue to KothaBook', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B6B))),
                const SizedBox(height: 48),

                _buildLabel('Mobile Number'),
                _buildTextField(
                  controller: _mobileController,
                  hint: 'Ex: 01XXXXXXXXX',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                
                _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  }
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: const EdgeInsets.only(top: 8, bottom: 8, right: 0), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Forgot Password?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFFF6D00))),
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: _isLoading ? null : _loginAndGoToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00), foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFB782),
                    minimumSize: const Size(double.infinity, 56), elevation: 4,
                    shadowColor: const Color(0xFFFF6D00).withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Log In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? ', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B6B))),
                    GestureDetector(
                      onTap: _goToSignup,
                      child: Text('Sign Up', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
      ),
    );
  }

  // 🏗️ তোমার অরিজিনাল স্টাইলের TextField Builder
  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    bool isPassword = false, 
    bool? obscure,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (obscure ?? true) : false,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFA0A0A0)),
        filled: true, fillColor: const Color(0xFFF8F9FA),
        prefixIcon: Icon(icon, color: const Color(0xFFA0A0A0), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon((obscure ?? true) ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFA0A0A0), size: 20),
                onPressed: onToggle,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
      ),
    );
  }
}