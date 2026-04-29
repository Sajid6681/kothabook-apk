import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';
import '../profile/complete_profile_screen.dart';
import '../../core/api_constants.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _contactController   = TextEditingController();
  final TextEditingController _passwordController  = TextEditingController();
  final TextEditingController _confirmController   = TextEditingController();

  // ─── State Variables ───────────────────────────────────────────────────────
  bool      _useEmail         = true;
  DateTime? _selectedDate;
  String?   _selectedGender;
  bool      _obscurePassword  = true;
  bool      _obscureConfirm   = true;
  bool      _agreedToTerms    = false;
  bool      _isLoading        = false;

  // ─── Phone Number Formatting ───────────────────────────────────────────────
  String get _formattedPhoneNumber {
    String raw = _contactController.text.trim();
    if (raw.isEmpty) return "";
    if (raw.startsWith('0')) raw = raw.substring(1);
    return "+880$raw";
  }

  // ─── Form Validation ───────────────────────────────────────────────────────
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

  bool get _isMismatch =>
      _confirmController.text.isNotEmpty &&
      _passwordController.text != _confirmController.text;

  // ─── UI Helpers ───────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
        letterSpacing: 0.5,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
      ),
    );
  }

  // ─── Date Picker ──────────────────────────────────────────────────────────
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
      setState(() => _selectedDate = picked);
    }
  }

  // ─── ✅ FIXED: Signup API Call ─────────────────────────────────────────────
  Future<void> _handleSignup() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      // ✅ FIX: Phone mode-এ formatted number পাঠানো হচ্ছে
      final String contactInfo = _useEmail
          ? _contactController.text.trim()
          : _formattedPhoneNumber;

      final Map<String, dynamic> requestBody = {
        "first_name": _firstNameController.text.trim(),
        "last_name":  _lastNameController.text.trim(),
        "contactInfo": contactInfo,
        "password":   _passwordController.text,
      };

      final response = await ApiService.postRequest(
        ApiConstants.register,
        requestBody,
      );

      // ✅ FIX: Empty বা invalid JSON response হলে crash করবে না
      Map<String, dynamic> responseData = {};
      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body);
        }
      } catch (_) {
        // Server invalid JSON পাঠালে default empty map রাখা হবে
      }

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                firstName: _firstNameController.text.trim(),
                lastName:  _lastNameController.text.trim(),
                generatedUsername:
                    "${_firstNameController.text.trim().toLowerCase()}_kothabook",
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['error'] ?? "Registration failed!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ FIX: আসল error message দেখানো হচ্ছে
      if (mounted) {
        final String errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
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
        title: Text(
          "Create Account",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── First Name & Last Name ──────────────────────────────────────
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

              // ── Contact Info ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel("Contact Info"),
                  Container(
                    padding: const EdgeInsets.all(2),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _useEmail = true;
                            _contactController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _useEmail ? const Color(0xFFFF6D00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "EMAIL",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _useEmail ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _useEmail = false;
                            _contactController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: !_useEmail ? const Color(0xFFFF6D00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "NUMBER",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: !_useEmail ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _contactController,
                keyboardType: _useEmail
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                onChanged: (val) => setState(() {}),
                maxLength: !_useEmail && _contactController.text.startsWith('01') ? 11 : null,
                decoration: _inputDecoration(
                  _useEmail ? "Enter your email" : "e.g. 017XXXXXXXX",
                  _useEmail ? Icons.email_outlined : Icons.phone_outlined,
                ).copyWith(counterText: ""),
              ),
              if (!_useEmail &&
                  _contactController.text.isNotEmpty &&
                  !_contactController.text.startsWith('01'))
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    "Number must start with 01 for Bangladesh",
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Password ────────────────────────────────────────────────────
              _fieldLabel("Password"),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (val) => setState(() {}),
                decoration: _inputDecoration("Create password", Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey,
                    ),
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
                    color: _passwordController.text.length >= 8
                        ? Colors.grey[600]
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Confirm Password ────────────────────────────────────────────
              _fieldLabel("Confirm Password"),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (val) => setState(() {}),
                decoration: _inputDecoration("Re-enter password", Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              if (_isMismatch)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    "Passwords do not match!",
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Birthday & Gender ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Birthday"),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _selectedDate == null
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
                              hint: Text(
                                "Select",
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey),
                              ),
                              value: _selectedGender,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              items: ["Male", "Female", "Other"].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() => _selectedGender = newValue);
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

              // ── Terms & Conditions ──────────────────────────────────────────
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFFFF6D00),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "I agree to the Terms of Service and Privacy Policy",
                      style:
                          GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ── Sign Up Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _handleSignup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "SIGN UP",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isFormValid ? Colors.white : Colors.grey[600],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // ── Already have account ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Login",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6D00),
                      ),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
