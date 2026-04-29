import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
// import '../home/home_screen.dart'; // 🚀 হোম স্ক্রিন তৈরি হলে এটা আনকমেন্ট করবে

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

  // 🚀 Image Variables
  File? _profileImage;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  // Controllers for Step 2 & 3
  final _cityController = TextEditingController();
  final _hometownController = TextEditingController();
  final _workPlaceController = TextEditingController();
  final _workTitleController = TextEditingController();
  final _workWebsiteController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _classController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    _hometownController.dispose();
    _workPlaceController.dispose();
    _workTitleController.dispose();
    _workWebsiteController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _classController.dispose();
    super.dispose();
  }

  // ─── 📸 Image Picker & Cropper Logic ───────────────────────────────────────

  // প্রোফাইল ছবি: Circle Crop
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        // ✅ FIX: cropStyle সরানো হয়েছে — এটা image_cropper v8+ এ নেই
        // Circle crop এর জন্য uiSettings এ aspectRatio square করলেই হয়
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: const Color(0xFFFF6D00),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(title: 'Crop Profile Photo'),
        ],
      );
      if (croppedFile != null) {
        setState(() { _profileImage = File(croppedFile.path); });
      }
    }
  }

  // কভার ছবি: Rectangle (16:9) Drag to Position
  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        // ✅ FIX: cropStyle সরানো হয়েছে (rectangle হলো default)
        // ✅ FIX: aspectRatioPresets সরানো হয়েছে — এটা এখন uiSettings এর ভেতরে দিতে হয়
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Cover Photo',
            toolbarColor: const Color(0xFFFF6D00),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true, 
            hideBottomControls: false,
            // ✅ aspectRatioPresets এখন AndroidUiSettings এর ভেতরে
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
          IOSUiSettings(
            title: 'Adjust Cover Photo',
            aspectRatioLockEnabled: true,
            // ✅ aspectRatioPresets এখন IOSUiSettings এর ভেতরে
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() { _coverImage = File(croppedFile.path); });
      }
    }
  }

  // ─── Step 1: Basic Info & Photos ──────────────────────────────────────────
  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 🚀 Cover & Profile Photo Stack 
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 40.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // ─── Cover Photo ───
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF6D00), width: 1.5),
                    image: _coverImage != null ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover) : null,
                  ),
                  child: _coverImage == null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Color(0xFFFF6D00), size: 32),
                      const SizedBox(height: 6),
                      Text("ADD COVER PHOTO", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00), letterSpacing: 0.5)),
                    ],
                  ) : null,
                ),
              ),
              
              // ─── Profile Photo with floating + Icon ───
              Positioned(
                bottom: -50,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    clipBehavior: Clip.none, 
                    children: [
                      // Main Profile Image Circle
                      Container(
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF6D00), width: 1.5),
                            image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
                          ),
                          child: _profileImage == null ? const Icon(Icons.camera_alt, color: Color(0xFFFF6D00), size: 36) : null,
                        ),
                      ),
                      
                      // The '+' Icon 
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Read-Only Display Names
        Text("FULL NAME", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Text(widget.firstName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Text(widget.lastName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Text("USERNAME", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
          child: Row(
            children: [
              Text("@", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade300)),
              const SizedBox(width: 4),
              Text(widget.generatedUsername, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 2 & 3 (UNTOUCHED) ───────────────────────────────────────────────
  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), 
      children: [
        Text("Location Info", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))), 
        const SizedBox(height: 16), 
        _buildField("Current City", _cityController, hint: "e.g. Dhaka, Bangladesh"), 
        _buildField("Hometown", _hometownController, hint: "e.g. Chittagong, Bangladesh"), 
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFFEEEEEE), thickness: 1)), 
        Text("Education", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))), 
        const SizedBox(height: 16), 
        _buildField("School / University", _schoolController, hint: "e.g. Dhaka University"), 
        Row(
          children: [
            Expanded(flex: 2, child: _buildField("Major / Degree", _majorController, hint: "e.g. CSE")), 
            const SizedBox(width: 16), 
            Expanded(flex: 1, child: _buildField("Class / Year", _classController, hint: "e.g. 2024"))
          ]
        )
      ]
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), 
      children: [
        Text("Professional Details", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))), 
        const SizedBox(height: 16), 
        _buildField("Workplace / Company", _workPlaceController, hint: "e.g. Google"), 
        _buildField("Job Title", _workTitleController, hint: "e.g. Software Engineer"), 
        _buildField("Website (Optional)", _workWebsiteController, hint: "https://yourwebsite.com", keyboardType: TextInputType.url)
      ]
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String hint = '', bool isEditable = true, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), 
          const SizedBox(height: 8), 
          TextField(
            controller: controller, 
            readOnly: !isEditable, 
            keyboardType: keyboardType, 
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: isEditable ? const Color(0xFF1A1A1A) : Colors.grey.shade600), 
            decoration: InputDecoration(
              hintText: hint, 
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400), 
              filled: true, 
              fillColor: isEditable ? const Color(0xFFF8F9FA) : Colors.grey.shade100, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5))
            )
          )
        ]
      )
    );
  }

  // ─── Navigation Logic ─────────────────────────────────────────────────────
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveProfileData();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);
    // TODO: Upload images and data to Node.js / MySQL backend
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSaving = false);

    if (mounted) {
      // 🚀 হোমস্ক্রিনে নেভিগেশন
      // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("Complete Profile", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), 
                  const SizedBox(height: 8), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text("Step ${_currentPage + 1} of 3", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)), 
                      Text(_currentPage == 0 ? "Basic Info" : _currentPage == 1 ? "Location & Edu" : "Professional", style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFFF6D00), fontWeight: FontWeight.w600))
                    ]
                  ), 
                  const SizedBox(height: 16), 
                  Row(
                    children: List.generate(3, (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0), 
                        height: 6, 
                        decoration: BoxDecoration(
                          color: index <= _currentPage ? const Color(0xFFFF6D00) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)
                        )
                      )
                    ))
                  )
                ]
              )
            ), 
            Expanded(
              child: PageView(
                controller: _pageController, 
                physics: const NeverScrollableScrollPhysics(), 
                onPageChanged: (index) => setState(() => _currentPage = index), 
                children: [_buildStep1(), _buildStep2(), _buildStep3()]
              )
            ), 
            Container(
              padding: const EdgeInsets.all(24), 
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  // ✅ FIX: withOpacity deprecated → Color.fromRGBO ব্যবহার করা হয়েছে
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ]
              ), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _prevPage,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text("Back", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700))
                    )
                  else const SizedBox(width: 80), 
                  ElevatedButton(
                    onPressed: _isSaving ? null : _nextPage, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0
                    ), 
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text(_currentPage == 2 ? "Save Profile" : "Next Step", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}
