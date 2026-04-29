import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
// import '../home/home_screen.dart'; // হোম স্ক্রিনের ইমপোর্ট

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ─── State Variables ───────────────────────────────────────────────────────
  bool _useEmail = true; // 🚀 ফিক্সড: ডিফল্ট হিসেবে Email সিলেক্ট করা থাকবে
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── নম্বর ফরম্যাটিং লজিক ────────────────────────
  String get _formattedPhoneNumber {
    String raw = _contactController.text.trim();
    if (raw.isEmpty) return "";
    
    if (raw.startsWith('0')) {
      raw = raw.substring(1);
    }
    return "+880$raw";
  }

  // ─── ভ্যালিডেশন লজিক ──────────────────────────────────────────────────────
  bool get _isFormValid {
    return _contactController.text.trim().isNotEmpty &&
           _passwordController.text.length >= 8;
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 0.5)),
  );

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn("EMAIL", _useEmail, () => setState(() { _useEmail = true; _contactController.clear(); })),
          _toggleBtn("NUMBER", !_useEmail, () => setState(() { _useEmail = false; _contactController.clear(); })),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6D00) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey)),
      ),
    );
  }

  void _handleLogin() {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);
    
    // TODO: Connect to Node.js backend
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
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
                Icon(Icons.hub, size: 60, color: const Color(0xFFFF6D00)),
                const SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  "Login to your KothaBook account",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _fieldLabel("Contact Info"),
                    _buildToggle(),
                  ],
                ),
                TextFormField(
                  controller: _contactController,
                  keyboardType: _useEmail ? TextInputType.emailAddress : TextInputType.phone,
                  onChanged: (val) => setState(() {}),
                  decoration: _inputDecoration(_useEmail ? "Enter your email" : "e.g. 017XXXXXXXX", _useEmail ? Icons.email_outlined : Icons.phone_outlined),
                ),
                const SizedBox(height: 20),

                _fieldLabel("Password"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (val) => setState(() {}),
                  decoration: _inputDecoration("Enter your password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text("Forgot Password?", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("LOGIN", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _isFormValid ? Colors.white : Colors.grey[600])),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                      },
                      child: Text("Signup", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
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