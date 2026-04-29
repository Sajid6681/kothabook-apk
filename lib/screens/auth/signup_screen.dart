import 'dart:convert'; // 🚀 JSON ডিকোড করার জন্য
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// 🚀 তোমার আগের ইমপোর্টগুলো
import 'login_screen.dart'; 
import '../profile/complete_profile_screen.dart';

// 🚀 নতুন API ইমপোর্টগুলো
import '../../core/api_constants.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 🚀 ইনপুট কন্ট্রোলারসমূহ
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // 🚀 স্টেট ভেরিয়েবলসমূহ
  bool _useEmail = true; // ডিফল্ট হিসেবে Email সিলেক্ট করা থাকবে
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

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
    return _firstNameController.text.trim().isNotEmpty &&
           _lastNameController.text.trim().isNotEmpty &&
           _contactController.text.trim().isNotEmpty &&
           _passwordController.text.length >= 8 &&
           _passwordController.text == _confirmController.text &&
           _selectedDate != null &&
           _selectedGender != null &&
           _agreedToTerms;
  }

  bool get _isMismatch => _confirmController.text.isNotEmpty && _passwordController.text != _confirmController.text;

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
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1970),   
      lastDate: DateTime.now(),    
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ─── 🚀 আসল API Connection Logic ───────────────────────────────────────────
  Future<void> _handleSignup() async {
    if (!_isFormValid) return;
    
    setState(() => _isLoading = true);

    try {
      // ১. ডাটাবেসে পাঠানোর জন্য ইউজারের সব তথ্য এক করা হচ্ছে
      final Map<String, dynamic> requestBody = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "contactInfo": _contactController.text.trim(),
        "password": _passwordController.text,
      };

      // ২. ApiService ব্যবহার করে Node.js সার্ভারে রিকোয়েস্ট পাঠানো হচ্ছে
      final response = await ApiService.postRequest(ApiConstants.register, requestBody);
      final responseData = jsonDecode(response.body);

      // ৩. সার্ভার থেকে আসা রেজাল্ট চেক করা হচ্ছে
      if (response.statusCode == 201) {
        // 🟢 সাকসেস! ইউজারের ডাটা সেভ হয়ে গেছে (সম্পূর্ণ ইংলিশে মেসেজ)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful!"), backgroundColor: Colors.green)
          );

          // 🚀 সাকসেস হলে ইউজারের নামসহ Complete Profile স্ক্রিনে পাঠিয়ে দেওয়া হচ্ছে
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                generatedUsername: "${_firstNameController.text.trim().toLowerCase()}_kothabook",
              )
            )
          );
        }
      } else {
        // 🔴 সার্ভার থেকে কোনো এরর আসলে (যেমন: Duplicate email)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['error'] ?? "Registration failed!"), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      // 🔴 ইন্টারনেট না থাকলে বা সার্ভার অফ থাকলে (তোমার কথামতো সার্ভারের নাম হাইড করে ইংলিশ ওয়ার্নিং)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Check your internet connection"), 
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          )
        );
      }
    } finally {
      // কাজ শেষ হলে লোডিং অফ করে দেওয়া হচ্ছে
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── 🎨 সম্পূর্ণ আগের অরিজিনাল UI (কোনো চেঞ্জ করা হয়নি) ───────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Create Account", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("First Name"),
                        TextFormField(
                          controller: _firstNameController,
                          onChanged: (val) => setState(() {}),
                          decoration: _inputDecoration("First", Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Last Name"),
                        TextFormField(
                          controller: _lastNameController,
                          onChanged: (val) => setState(() {}),
                          decoration: _inputDecoration("Last", null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel("Contact Info"),
                  Container(
                    padding: const EdgeInsets.all(2),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() { _useEmail = true; _contactController.clear(); }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _useEmail ? const Color(0xFFFF6D00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("EMAIL", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: _useEmail ? Colors.white : Colors.grey)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() { _useEmail = false; _contactController.clear(); }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: !_useEmail ? const Color(0xFFFF6D00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("NUMBER", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: !_useEmail ? Colors.white : Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              TextFormField(
                controller: _contactController,
                keyboardType: _useEmail ? TextInputType.emailAddress : TextInputType.phone,
                onChanged: (val) => setState(() {}),
                maxLength: !_useEmail && _contactController.text.startsWith('01') ? 11 : null,
                decoration: _inputDecoration(_useEmail ? "Enter your email" : "e.g. 017XXXXXXXX", _useEmail ? Icons.email_outlined : Icons.phone_outlined).copyWith(counterText: ""),
              ),
              if (!_useEmail && _contactController.text.isNotEmpty && !_contactController.text.startsWith('01'))
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text("Number must start with 01 for Bangladesh", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red)),
                ),
              const SizedBox(height: 20),

              // Password
              _fieldLabel("Password"),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (val) => setState(() {}),
                decoration: _inputDecoration("create password", Icons.lock_outline).copyWith( 
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  "At least 8 characters required", 
                  style: GoogleFonts.poppins(
                    fontSize: 10, 
                    color: _passwordController.text.length >= 8 ? Colors.grey[600] : Colors.red,
                  )
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password
              _fieldLabel("Confirm Password"),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (val) => setState(() {}),
                decoration: _inputDecoration("Re-enter password", Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              if (_isMismatch)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text("Passwords do not match!", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red)),
                ),
              const SizedBox(height: 20),

              // Birthday & Gender
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Birthday"),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null ? "Select Date" : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                                  style: GoogleFonts.poppins(fontSize: 13, color: _selectedDate == null ? Colors.grey : Colors.black87),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Gender"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text("Select", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                              value: _selectedGender,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: ["Male", "Female", "Other"].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Terms and Conditions
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFFFF6D00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "I agree to the Terms of Service and Privacy Policy",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Signup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _handleSignup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("SIGN UP", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _isFormValid ? Colors.white : Colors.grey[600])),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text("Login", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}