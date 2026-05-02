import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;

// 🚀 API এবং Constants
import '../../core/api_constants.dart';
import '../../services/api_service.dart';
import '../../core/constants/country_list.dart';

// 🚀 উইজেটসমূহ
import '../widgets/custom_button.dart';
import '../widgets/custom_popup.dart';

// 🚀 নেভিগেশন
import '../profile/complete_profile_screen.dart'; 

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
  DateTime? _selectedDate; // 📅 Date of Birth
  String? _selectedGender; // 🚻 Gender
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  // 🎛️ Admin Mode ও Toggle 
  final String _adminMode = 'both'; 
  String _signupMethod = 'number';

  // 🌍 Country State
  CountryModel _selectedCountry = AppConstants.countries[0]; // Default BD
  List<CountryModel> _filteredCountries = AppConstants.countries;

  @override
  void initState() {
    super.initState();
    _detectUserCountry();
    if (_adminMode == 'email') _signupMethod = 'email';
    if (_adminMode == 'number') _signupMethod = 'number';
  }

  // 🧠 IP Track করে অটোমেটিক দেশের কোড বসানো
  Future<void> _detectUserCountry() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['countryCode'];
        if (mounted) {
          setState(() {
            _selectedCountry = AppConstants.countries.firstWhere(
              (c) => c.isoCode == countryCode,
              orElse: () => AppConstants.countries[0],
            );
          });
        }
      }
    } catch (_) {}
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => CustomPopup(title: "Invalid Input", message: message, onOkay: () => Navigator.pop(context)),
    );
  }

  void _handleContactChange(String val) {
    if (_signupMethod == 'number') {
      if (val.length > 15) {
        _contactController.text = val.substring(0, 15);
        _contactController.selection = TextSelection.fromPosition(const TextPosition(offset: 15));
      }
    }
    setState(() {});
  }

  // 📅 Date of Birth Picker Logic (ডিফল্ট ২০০০ সাল)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1), // 🚀 ক্যালেন্ডার ওপেন হলেই ২০০০ সাল দেখাবে!
      firstDate: DateTime(1970), // শুরু ১৯৭০
      lastDate: DateTime(2020, 12, 31), // শেষ ২০২০
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6D00), // KothaBook অরেঞ্জ থিম
              onPrimary: Colors.white,
              onSurface: Colors.black87,
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

  // 🧠 Growth Hacking: অটোমেটিক ইউজারনেম জেনারেটর
  String _generateUsername(String firstName, String lastName) {
    String baseName = "${firstName.trim().toLowerCase()}${lastName.trim().toLowerCase()}";
    baseName = baseName.replaceAll(RegExp(r'\s+'), ''); 
    int randomNum = 1056 + Random().nextInt(5000); 
    return "${baseName}_$randomNum"; 
  }

  // ─── ভ্যালিডেশন লজিক ───
  bool get _isEmailValid => _contactController.text.contains('@') && _contactController.text.contains('.');
  bool get _isMobileValid => RegExp(r'^\d+$').hasMatch(_contactController.text) && _contactController.text.length >= 7;
  bool get _isContactValid => _signupMethod == 'email' ? _isEmailValid : _isMobileValid;
  bool get _isPasswordValid => _passwordController.text.length >= 8;
  bool get _isPasswordMatch => _passwordController.text == _confirmController.text && _confirmController.text.isNotEmpty;
  bool get _isNameValid => _firstNameController.text.trim().isNotEmpty && _lastNameController.text.trim().isNotEmpty;
  
  // ✅ Final Form Validation
  bool get _isFormValid => _isNameValid && _isContactValid && _isPasswordValid && _isPasswordMatch && _selectedDate != null && _selectedGender != null && _agreedToTerms;

  // ─── 🚀 REAL API SIGNUP LOGIC ───
  Future<void> _handleSignup() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final fullContact = _signupMethod == 'number' 
          ? "${_selectedCountry.code}${_contactController.text.trim()}" 
          : _contactController.text.trim();

      final String generatedUsername = _generateUsername(_firstNameController.text, _lastNameController.text);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final body = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "username": generatedUsername,
        "contact": fullContact,
        "password": _passwordController.text,
        "dob": formattedDate, 
        "gender": _selectedGender, 
      };

      final response = await ApiService.postRequest(ApiConstants.register, body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          // 🚀 সাইনআপ সফল হলে প্রোফাইল স্ক্রিনে যাবে
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompleteProfileScreen(
                    generatedUsername: generatedUsername,
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                  )));
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorPopup(errorData['message'] ?? "Signup failed. Try again.");
      }
    } catch (e) {
      _showErrorPopup("Check your internet connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌍 কান্ট্রি পিকার বটম শিট
  void _openCountryPicker() {
    setState(() => _filteredCountries = AppConstants.countries);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6D00),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Select Country", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search country...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _filteredCountries = AppConstants.countries.where((c) => 
                            c.name.toLowerCase().contains(val.toLowerCase()) || c.code.contains(val)
                          ).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final c = _filteredCountries[index];
                        return ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          trailing: Text(c.code, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                          onTap: () {
                            setState(() => _selectedCountry = c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset('assets/logo/text_logo.png', height: 40),
              const SizedBox(height: 20),
              Text("Create Account", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 🛠️ Name Fields Fixed (50/50 Split)
              Row(
                children: [
                  Expanded(child: TextField(controller: _firstNameController, onChanged: (v)=>setState((){}), decoration: _inputDecoration("Enter First Name"))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _lastNameController, onChanged: (v)=>setState((){}), decoration: _inputDecoration("Enter Last Name"))),
                ],
              ),
              const SizedBox(height: 16),

              // 🔘 Top-Right Email / Number Toggle & Contact Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_adminMode == 'both')
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () { setState(() { _signupMethod = 'number'; _contactController.clear(); }); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(color: _signupMethod == 'number' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6), boxShadow: _signupMethod == 'number' ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : []),
                              child: Text("Number", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _signupMethod == 'number' ? const Color(0xFFFF6D00) : Colors.grey)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () { setState(() { _signupMethod = 'email'; _contactController.clear(); }); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(color: _signupMethod == 'email' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6), boxShadow: _signupMethod == 'email' ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : []),
                              child: Text("Email", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _signupMethod == 'email' ? const Color(0xFFFF6D00) : Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      if (_signupMethod == 'number') ...[
                        GestureDetector(
                          onTap: _openCountryPicker,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20, height: 1.2)),
                                Text(_selectedCountry.code, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _contactController,
                          keyboardType: _signupMethod == 'number' ? TextInputType.phone : TextInputType.emailAddress,
                          onChanged: _handleContactChange,
                          decoration: _inputDecoration(_signupMethod == 'number' ? "Enter Mobile Number" : "Enter Email Address").copyWith(
                            prefixIcon: _signupMethod == 'email' ? const Icon(Icons.mail_outline, color: Colors.grey, size: 20) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 📅 Date of Birth & Gender
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate == null ? "Select Date" : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                                style: GoogleFonts.poppins(
                                  fontSize: 13, 
                                  color: _selectedDate == null ? Colors.grey.shade400 : Colors.black87,
                                  fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, color: Colors.grey, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                hint: Text("Gender", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
                                value: _selectedGender,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                isExpanded: true,
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                                items: ["Male", "Female", "Other"].map((String gender) {
                                  return DropdownMenuItem<String>(value: gender, child: Text(gender));
                                }).toList(),
                                onChanged: (String? newValue) { setState(() { _selectedGender = newValue; }); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🚀 Passwords
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (v)=>setState((){}),
                decoration: _inputDecoration("Create a Password").copyWith(prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (v)=>setState((){}),
                decoration: _inputDecoration("Confirm your Password").copyWith(prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
              ),

              // 🛡️ Trackers
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Column(
                  children: [
                    Row(children: [Icon(_isPasswordValid ? Icons.check_circle : Icons.error_outline, size: 14, color: _isPasswordValid ? Colors.green : Colors.grey), const SizedBox(width: 4), Text("Minimum 8 characters", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _isPasswordValid ? Colors.green : Colors.grey.shade400))]),
                    const SizedBox(height: 4),
                    Row(children: [Icon(_isPasswordMatch ? Icons.check_circle : Icons.error_outline, size: 14, color: _isPasswordMatch ? Colors.green : Colors.grey), const SizedBox(width: 4), Text("Passwords must match", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _isPasswordMatch ? Colors.green : Colors.grey.shade400))]),
                  ],
                ),
              ),

              // Terms
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: _agreedToTerms, activeColor: const Color(0xFFFF6D00), onChanged: (v) => setState(() => _agreedToTerms = v!)),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text("By creating an account, you agree to our Terms of Service and Privacy Policy.", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)))),
                ],
              ),
              const SizedBox(height: 20),

              // 🚀 CustomButton 
              _isLoading 
                  ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))))
                  : CustomButton(
                      text: "CREATE ACCOUNT",
                      onPressed: _isFormValid ? _handleSignup : () {},
                    ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Text("Login", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00)))),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}