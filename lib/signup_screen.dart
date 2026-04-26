import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'complete_profile_screen.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 🚀 অরিজিনাল স্টেট ভেরিয়েবলগুলো
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

  // 🌐 ঠিক করা লাইভ ডোমেইন (app. যুক্ত করা হয়েছে)
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

  // ========================================================
  // 🚀 ডাটাবেসে ইউজার রেজিস্টার করার মেইন API ফাংশন
  // ========================================================
  Future<void> _signupAndGoToCompleteProfile() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    final String apiUrl = '$baseUrl/api/register';

    try {
      String displayDate = _selectedBirthday != null 
        ? "${_selectedBirthday!.day.toString().padLeft(2, '0')} / ${_selectedBirthday!.month.toString().padLeft(2, '0')} / ${_selectedBirthday!.year}" 
        : "";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "mobileNumber": _mobileController.text.trim(),
          "password": _passwordController.text,
          "birthday": displayDate,
          "gender": _selectedGender,
        }),
      );

      final responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false; 
      });

      if (response.statusCode == 201) {
        // 🚀 রেজিস্ট্রেশন সফল হলে মোবাইল নাম্বার সেভ করা হচ্ছে
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('mobileNumber', _mobileController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'], style: GoogleFonts.poppins()), backgroundColor: Colors.green)
        );

        String generatedUsername = responseData['user']['username']; 

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CompleteProfileScreen(
              generatedUsername: generatedUsername,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Signup failed!', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Signup Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server connection failed!', style: GoogleFonts.poppins()), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1970), 
      lastDate: DateTime(2026, 12, 31), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6D00), 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  bool get _isFormValid => 
      _agreedToTerms && 
      _selectedGender != null && 
      _selectedBirthday != null &&
      _firstNameController.text.isNotEmpty &&
      _lastNameController.text.isNotEmpty &&
      _mobileController.text.isNotEmpty && 
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Create Account', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Join KothaBook today and connect!', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B6B6B))),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildCompactTextField('First Name', 'First', Icons.person_outline_rounded, _firstNameController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactTextField('Last Name', 'Last', Icons.person_outline_rounded, _lastNameController),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _buildCompactTextField('Mobile Number', 'Ex: 01XXXXXXXXX', Icons.phone_android_rounded, _mobileController, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              
              _buildPasswordField('Password', 'Create a password', _passwordController, false),
              const SizedBox(height: 12),

              _buildPasswordField('Confirm Password', 'Re-enter password', _confirmPasswordController, true),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildBirthdayField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGenderDropdown()),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 2),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: _agreedToTerms ? const Color(0xFFFF6D00) : Colors.transparent,
                        border: Border.all(color: _agreedToTerms ? const Color(0xFFFF6D00) : const Color(0xFFC0C0C0), width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _agreedToTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B6B6B)),
                          children: [
                            TextSpan(text: 'Terms', style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontWeight: FontWeight.w500)),
                            const TextSpan(text: ' & '),
                            TextSpan(text: 'Privacy Policy', style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontWeight: FontWeight.w500)),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: (_isFormValid && !_isLoading) ? _signupAndGoToCompleteProfile : null, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB782), 
                  disabledBackgroundColor: const Color(0xFFFFB782),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) return const Color(0xFFFFB782);
                      return const Color(0xFFFF6D00); 
                    }
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Create Account', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B6B6B))),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: Text('Log In', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🏗️ অরিজিনাল স্টাইলের ইনপুট বিল্ডার
  Widget _buildCompactTextField(String label, String hint, IconData? icon, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (v) => setState(() {}), 
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: hint, 
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFA0A0A0)),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFA0A0A0), size: 18) : null,
              contentPadding: EdgeInsets.symmetric(horizontal: icon == null ? 16 : 0, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, String hint, TextEditingController controller, bool isConfirm) {
    bool obscure = isConfirm ? _obscureConfirmPassword : _obscurePassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            onChanged: (v) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: hint, 
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFA0A0A0)),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFA0A0A0), size: 18),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFA0A0A0), size: 18),
                onPressed: () {
                  setState(() {
                    if (isConfirm) _obscureConfirmPassword = !_obscureConfirmPassword;
                    else _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayField() {
    String displayDate = _selectedBirthday != null 
        ? "${_selectedBirthday!.day.toString().padLeft(2, '0')} / ${_selectedBirthday!.month.toString().padLeft(2, '0')} / ${_selectedBirthday!.year}" 
        : "DD / MM / YYYY"; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Birthday', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedBirthday != null ? const Color(0xFFFF6D00).withOpacity(0.5) : Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayDate,
                    style: GoogleFonts.poppins(fontSize: 13, color: _selectedBirthday != null ? const Color(0xFF1A1A1A) : const Color(0xFFA0A0A0)),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF1A1A1A)), 
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Gender', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ),
        SizedBox(
          height: 48,
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
              setState(() {
                _selectedGender = newValue;
              });
            },
          ),
        ),
      ],
    );
  }
}