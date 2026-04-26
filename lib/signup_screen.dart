import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
// import 'complete_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; 
  DateTime? _selectedBirthday;
  String? _selectedGender;
  bool _agreedToTerms = false;
  bool _isLoading = false; 

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final String baseUrl = "https://app.kothabook.com";

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (_firstNameController.text.isEmpty || _mobileController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill in all fields.!");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("পাসওয়ার্ড দুটি মিলছে না!");
      return;
    }

    if (!_agreedToTerms) {
      _showError("দয়া করে Terms & Conditions এ সম্মতি দিন!");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "mobile": _mobileController.text,
          "password": _passwordController.text,
          "gender": _selectedGender ?? "Not Specified",
          "birthday": _selectedBirthday?.toIso8601String() ?? "",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("অ্যাকাউন্ট তৈরি সফল হয়েছে! লগইন করুন।", style: GoogleFonts.poppins())),
          );
          _goToLogin();
        }
      } else {
        _showError(data['message'] ?? "সাইনআপ ব্যর্থ হয়েছে!");
      }
    } catch (e) {
      _showError("সার্ভার কানেকশন ফেইলড! (kothabook.com)");
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF6D00)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() { _selectedBirthday = picked; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: _goToLogin,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Create Account",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Join the KothaBook community today",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('First Name', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      ),
                      _buildTextField(controller: _firstNameController, hint: "First Name", icon: Icons.person_outline),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('Last Name', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      ),
                      _buildTextField(controller: _lastNameController, hint: "Last Name", icon: Icons.person_outline),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Mobile Number', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
            _buildTextField(
              controller: _mobileController, 
              hint: "Enter Mobile Number", 
              icon: Icons.phone_android_outlined, 
              keyboardType: TextInputType.phone
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('Birthday', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      ),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _selectedBirthday == null 
                                    ? "Select Date" 
                                    : "${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}",
                                style: GoogleFonts.poppins(
                                  color: _selectedBirthday == null ? Colors.grey[400] : Colors.black87,
                                  fontSize: 13
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('Gender', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      ),
                      SizedBox(
                        height: 52,
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          icon: const SizedBox.shrink(), 
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
                          ),
                          hint: Text('Select', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A))), 
                          items: ['Male', 'Female', 'Other'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() { _selectedGender = newValue; });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
            _buildTextField(
              controller: _passwordController, 
              hint: "Create Password", 
              icon: Icons.lock_outline, 
              isPassword: true,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Confirm Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
            _buildTextField(
              controller: _confirmPasswordController, 
              hint: "Confirm your password", 
              icon: Icons.lock_reset_outlined, 
              isPassword: true,
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
            ),
            
            const SizedBox(height: 20),

            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: const Color(0xFFFF6D00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (value) {
                    setState(() { _agreedToTerms = value ?? false; });
                  },
                ),
                Expanded(
                  child: Text(
                    "I agree to the Terms and Conditions",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("Sign Up", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? ", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                GestureDetector(
                  onTap: _goToLogin,
                  child: Text(
                    "Login",
                    style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
      ),
    );
  }
}
