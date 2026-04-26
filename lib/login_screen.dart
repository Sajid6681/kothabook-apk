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

  Future<void> _loginAndGoToHome() async {
    if (_mobileController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("সবগুলো ঘর পূরণ করুন!", style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        // 🚀 ১. API লিংক ঠিক করা হয়েছে
        Uri.parse("$baseUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          // 🚀 ২. mobile এর জায়গায় mobileNumber দেওয়া হয়েছে
          "mobileNumber": _mobileController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        // 🚀 ৩. হোম পেজের জন্য mobileNumber সেভ করা হয়েছে
        await prefs.setString('mobileNumber', _mobileController.text.trim());
        if (data['user'] != null && data['user']['_id'] != null) {
           await prefs.setString('userId', data['user']['_id']);
        }

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "লগইন ব্যর্থ হয়েছে!", style: GoogleFonts.poppins()))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Connection Failed!", style: GoogleFonts.poppins()))
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 50, color: Color(0xFFFF6D00)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "KothaBook",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6D00),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Login to continue your journey",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 48),
              
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text('Mobile Number', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
              ),
              _buildTextField(
                controller: _mobileController,
                hint: "Enter Mobile Number",
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text('Password', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
              ),
              _buildTextField(
                controller: _passwordController,
                hint: "Enter Password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Forgot Password?", style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginAndGoToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF6D00).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("Login", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                  GestureDetector(
                    onTap: _goToSignup,
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    bool isPassword = false, 
    bool? obscure,
    void Function()? onToggle,
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