import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// 🚀 ইমপোর্ট (কন্ট্রোলার এবং হোম স্ক্রিন)
import '../../controllers/profile_controller.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String generatedUsername;
  final String firstName;
  final String lastName;

  const CompleteProfileScreen({
    super.key,
    required this.generatedUsername,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // 🧠 কন্ট্রোলার কানেকশন
  final ProfileController _profileController = ProfileController();

  // 📸 ইমেজের জন্য ভেরিয়েবল
  File? _profileImage;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  // 🗄️ UI কন্ট্রোলারসমূহ
  final _cityController = TextEditingController();
  final _hometownController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _classController = TextEditingController(); // 🎓 Class/Year
  
  final _workPlaceController = TextEditingController();
  final _workTitleController = TextEditingController();
  final _workWebsiteController = TextEditingController();

  // 📸 গ্যালারি থেকে ছবি সিলেক্ট
  Future<void> _pickImage(bool isProfile) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _coverImage = File(pickedFile.path);
        }
      });
    }
  }

  // ─── 🚀 সেভ বাটনে ক্লিক করলে যা হবে ───
  Future<void> _handleSaveProfile() async {
    setState(() => _isSaving = true);

    // 🧠 UI থেকে ডাটা নিয়ে Controller-এর কাছে পাঠানো হচ্ছে
    bool isSuccess = await _profileController.uploadProfileData(
      firstName: widget.firstName,
      lastName: widget.lastName,
      username: widget.generatedUsername,
      city: _cityController.text.trim(),
      hometown: _hometownController.text.trim(),
      school: _schoolController.text.trim(),
      major: _majorController.text.trim(),
      classYear: _classController.text.trim(),
      workPlace: _workPlaceController.text.trim(),
      workTitle: _workTitleController.text.trim(),
      workWebsite: _workWebsiteController.text.trim(),
      profileImage: _profileImage,
      coverImage: _coverImage,
    );

    setState(() => _isSaving = false);

    if (isSuccess) {
      if (mounted) _showCongratulationsDialog(); // 🎉 সাকসেস পপআপ
    } else {
      _showSnackbar("Failed to save profile. Please try again.");
    }
  }

  // 🎉 CONGRATULATIONS POPUP (User Friendly)
  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFF6D00), size: 70),
              const SizedBox(height: 16),
              Text("Congratulations!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text(
                "Your profile setup is complete. Welcome to the KothaBook community!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                ),
                child: Text("LET'S GO", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 🎨 UI Input Decoration
  InputDecoration _customInput(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
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
        child: Column(
          children: [
            // 🌟 Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Setup Profile", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text("STEP ${_currentPage + 1} / 3", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: (_currentPage + 1) / 3, backgroundColor: Colors.grey[100], color: const Color(0xFFFF6D00), minHeight: 6),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // ─── STEP 1: Photos Only ───
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(false),
                              child: Container(
                                height: 160, width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA), 
                                  borderRadius: BorderRadius.circular(20), 
                                  border: Border.all(color: Colors.grey.shade200, width: 2),
                                  image: _coverImage != null ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover) : null
                                ),
                                child: _coverImage == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade300), const SizedBox(height: 8), Text("Add Cover Photo", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold))]) : null,
                              ),
                            ),
                            Positioned(
                              bottom: -45,
                              child: GestureDetector(
                                onTap: () => _pickImage(true),
                                child: Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle, 
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
                                    image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null
                                  ),
                                  child: _profileImage == null ? Icon(Icons.person_add_alt_1_outlined, size: 35, color: Colors.grey.shade300) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 70),
                        Text("Update your profile and cover photo", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                  // ─── STEP 2: Location & Education ───
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Location", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(controller: _cityController, decoration: _customInput("Current City", Icons.location_on_outlined)),
                        const SizedBox(height: 12),
                        TextField(controller: _hometownController, decoration: _customInput("Hometown", Icons.home_outlined)),
                        const SizedBox(height: 24),
                        Text("Education", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(controller: _schoolController, decoration: _customInput("School / University", Icons.school_outlined)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(flex: 2, child: TextField(controller: _majorController, decoration: _customInput("Major", Icons.stars_outlined))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: _classController, decoration: InputDecoration(hintText: "Year", hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400), filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6D00)))))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── STEP 3: Work Info ───
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Professional Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(controller: _workPlaceController, decoration: _customInput("Company / Workplace", Icons.business_center_outlined)),
                        const SizedBox(height: 12),
                        TextField(controller: _workTitleController, decoration: _customInput("Job Title", Icons.badge_outlined)),
                        const SizedBox(height: 12),
                        TextField(controller: _workWebsiteController, decoration: _customInput("Website (Optional)", Icons.language_rounded)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🌟 Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.linear), 
                      child: Text("BACK", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold))
                    )
                  else const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.linear);
                      } else {
                        _handleSaveProfile(); // 🧠 Controller কে কল করা হচ্ছে
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16), elevation: 0),
                    child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_currentPage == 2 ? "SAVE" : "NEXT", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}