import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:convert';
import 'home_screen.dart'; // যদি home_screen.dart অন্য ফোল্ডারে থাকে, তবে পাথ ঠিক করে নিও

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

  late TextEditingController _usernameController;
  final _mobileController = TextEditingController(); 
  final _cityController = TextEditingController();
  final _hometownController = TextEditingController();
  final _workPlaceController = TextEditingController();
  final _workTitleController = TextEditingController();
  final _workWebsiteController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _classController = TextEditingController();

  File? _newProfileImage;
  File? _newCoverImage;
  final ImagePicker _picker = ImagePicker();

  @override 
  void initState() { 
    super.initState(); 
    _usernameController = TextEditingController(text: widget.generatedUsername); 
  }

  Future<void> _pickAndCropImage(bool isProfilePic) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: isProfilePic ? const CropAspectRatio(ratioX: 1, ratioY: 1) : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isProfilePic ? 'Crop Profile Photo' : 'Position Cover',
            toolbarColor: const Color(0xFFFF6D00),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isProfilePic ? CropAspectRatioPreset.square : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          if (isProfilePic) {
            _newProfileImage = File(croppedFile.path);
          } else {
            _newCoverImage = File(croppedFile.path);
          }
        });
      }
    }
  }

  // 🚀 হোস্টিংয়ে ছবি আপলোডের শক্তিশালী ফাংশন
  Future<String> _uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://kothabook.com/kothabook_api/upload.php'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      try {
        var jsonResponse = jsonDecode(responseData);
        if (jsonResponse['success'] == true) {
          return jsonResponse['imageUrl'];
        }
      } catch (e) { 
        print("JSON Decode Error: $responseData"); 
      }
    } catch (e) { 
      print("Image Upload Exception: $e"); 
    }
    return "";
  }

  // 🚀 লাইভ সার্ভারে ডাটা সেভ করা
  Future<void> _saveDataAndFinish() async {
    setState(() => _isSaving = true);
    
    String profilePicUrl = "";
    String coverPhotoUrl = "";

    // 🚀 আগে ছবি আপলোড হবে
    if (_newProfileImage != null) profilePicUrl = await _uploadImage(_newProfileImage!);
    if (_newCoverImage != null) coverPhotoUrl = await _uploadImage(_newCoverImage!);

    try {
      final response = await http.post(
        Uri.parse('https://app.kothabook.com/api/update-profile'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "profilePic": profilePicUrl,
          "coverPhoto": coverPhotoUrl,
          "workTitle": _workTitleController.text.trim(), 
          "workPlace": _workPlaceController.text.trim(),
          "workLinkType": "Website", 
          "workUrlOrPage": _workWebsiteController.text.trim(), 
          "currentCity": _cityController.text.trim(),
          "hometown": _hometownController.text.trim(), 
          "schoolUniversity": _schoolController.text.trim(), 
          "major": _majorController.text.trim(), 
          "classBatch": _classController.text.trim(),
        }),
      );
      
      setState(() => _isSaving = false);
      
      if (response.statusCode == 200) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update!'), backgroundColor: Colors.red));
      }
    } catch (e) { 
      setState(() => _isSaving = false); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server Error!'), backgroundColor: Colors.red));
    }
  }

  void _nextPageOrFinish() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveDataAndFinish();
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: _currentPage > 0 
          ? IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)) 
          : const SizedBox()
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
              child: Row(
                children: List.generate(3, (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300), 
                    margin: const EdgeInsets.symmetric(horizontal: 4), 
                    height: 5, 
                    decoration: BoxDecoration(color: index <= _currentPage ? const Color(0xFFFF6D00) : Colors.grey.shade200, borderRadius: BorderRadius.circular(4))
                  )
                ))
              )
            ),
            Expanded(
              child: PageView(
                controller: _pageController, 
                physics: const NeverScrollableScrollPhysics(), 
                onPageChanged: (index) => setState(() => _currentPage = index), 
                children: [_buildStep1Basic(), _buildStep2Work(), _buildStep3Education()]
              )
            ),
            Container(
              padding: const EdgeInsets.all(24), 
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saveDataAndFinish, 
                    child: Text('Skip', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500))
                  ), 
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _nextPageOrFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), 
                      elevation: 0
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Row(
                          children: [
                            Text(_currentPage == 2 ? 'Finish' : 'Next', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)), 
                            if (_currentPage < 2) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 18)]
                          ]
                        ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Basic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Complete Your Profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), 
          const SizedBox(height: 8), 
          Text('Don\'t worry, only you can see your personal data.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)), 
          const SizedBox(height: 30),
          
          // 🚀 Photo Upload UI
          Stack(
            clipBehavior: Clip.none, 
            alignment: Alignment.bottomCenter, 
            children: [
              GestureDetector(
                onTap: () => _pickAndCropImage(false),
                child: Container(
                  height: 180, 
                  width: double.infinity, 
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5), 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), 
                    image: _newCoverImage != null ? DecorationImage(image: FileImage(_newCoverImage!), fit: BoxFit.cover) : null
                  ), 
                  child: _newCoverImage == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade400, size: 32), 
                          const SizedBox(height: 4), 
                          Text('Add Cover Photo', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500))
                        ]
                      ) 
                    : null
                ),
              ), 
              Positioned(
                bottom: -40, 
                child: GestureDetector(
                  onTap: () => _pickAndCropImage(true),
                  child: Stack(
                    alignment: Alignment.bottomRight, 
                    children: [
                      Container(
                        width: 90, 
                        height: 90, 
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white, width: 4), 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)], 
                          image: _newProfileImage != null ? DecorationImage(image: FileImage(_newProfileImage!), fit: BoxFit.cover) : null
                        ), 
                        child: _newProfileImage == null 
                          ? CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person_rounded, size: 40, color: Colors.grey)) 
                          : null
                      ), 
                      Container(
                        padding: const EdgeInsets.all(6), 
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00), 
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white, width: 2)
                        ), 
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14)
                      )
                    ]
                  ),
                )
              )
            ]
          ), 
          const SizedBox(height: 60),
          
          _buildField('Username', _usernameController, isEditable: true), 
          _buildField('Current City', _cityController, hint: 'Ex. Dhaka'), 
          _buildField('Home Town', _hometownController, hint: 'Ex. Chittagong'),
        ],
      ),
    );
  }

  Widget _buildStep2Work() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text('Work Details', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), 
          const SizedBox(height: 8), 
          Text('Tell us what you do.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)), 
          const SizedBox(height: 30), 
          _buildField('Work Place', _workPlaceController, hint: 'Ex. KheloBD'), 
          _buildField('Work Title', _workTitleController, hint: 'Ex. Software Engineer'), 
          _buildField('Work Website', _workWebsiteController, hint: 'Ex. www.khelobd.com')
        ]
      )
    );
  }

  Widget _buildStep3Education() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text('Education Details', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), 
          const SizedBox(height: 8), 
          Text('Where did you study?', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)), 
          const SizedBox(height: 30), 
          _buildField('School/University', _schoolController, hint: 'Ex. Dhaka University'), 
          _buildField('Major/Department', _majorController, hint: 'Ex. Computer Science'), 
          _buildField('Class/Batch', _classController, hint: 'Ex. Batch 2024')
        ]
      )
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
}