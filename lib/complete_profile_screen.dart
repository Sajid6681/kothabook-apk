import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // নতুন ইম্পোর্ট
import 'dart:convert';
import 'home_screen.dart';

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
  // নতুন ছবি ফাইল
  File? _newProfileImage;
  File? _newCoverImage;

  // ডাটাবেস থেকে আসা আগের ছবির লিংক
  String? _existingProfilePicUrl;
  String? _existingCoverPhotoUrl;

  bool _isLoading = false;
  bool _isFetchingData = true; // প্রথমবার ডাটা লোড করার সময়

  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final _aboutMeController = TextEditingController();
  final _workTitleController = TextEditingController();
  final _workPlaceController = TextEditingController();
  final _workLinkController = TextEditingController(); 
  final _currentCityController = TextEditingController();
  final _hometownController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _classController = TextEditingController();

  String _selectedRelationship = 'Single';
  String _workLinkType = 'Website'; 
  String _selectedKothaBookPage = 'Select a Page';

  final List<String> relationshipOptions = ['Single', 'In a Relationship', 'Engaged', 'Married', 'It\'s Complicated'];
  final List<String> workLinkOptions = ['Website', 'Page'];
  final List<String> userPages = ['Select a Page', 'KheloBD', 'Sajid Tech', 'KothaBook Official'];

  @override
  void initState() {
    super.initState();
    // 🚀 স্ক্রিন চালু হলেই আগের তথ্য ডাটাবেস থেকে টেনে এনে এখানে সেট করবে
    _fetchExistingUserData();
  }

  Future<void> _fetchExistingUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 

    if (mobileNumber != null) {
      final String apiUrl = 'https://app.kothabook.com/api/user/$mobileNumber';
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          
          setState(() {
            // কন্ট্রোলারগুলোতে আগের ডাটা বসানো
            _aboutMeController.text = userData['aboutMe'] ?? '';
            _workTitleController.text = userData['workTitle'] ?? '';
            _workPlaceController.text = userData['workPlace'] ?? '';
            _currentCityController.text = userData['currentCity'] ?? '';
            _hometownController.text = userData['hometown'] ?? '';
            _schoolController.text = userData['schoolUniversity'] ?? '';
            _majorController.text = userData['major'] ?? '';
            _classController.text = userData['classBatch'] ?? '';
            
            _selectedRelationship = userData['relationshipStatus'] ?? 'Single';
            _workLinkType = userData['workLinkType'] ?? 'Website';

            if(_workLinkType == 'Website') {
                _workLinkController.text = userData['workUrlOrPage'] ?? '';
            } else {
                _selectedKothaBookPage = userData['workUrlOrPage'] ?? 'Select a Page';
            }

            // আগের ছবির লিংকগুলো স্টোর করা (গায়েব হওয়া ঠেকাতে)
            _existingProfilePicUrl = userData['profilePic'];
            _existingCoverPhotoUrl = userData['coverPhoto'];

            _isFetchingData = false;
          });
        }
      } catch (error) {
        print("Fetch User Error: $error");
        setState(() => _isFetchingData = false);
      }
    }
  }

  // 📸 ছবি সিলেক্ট এবং ক্রপ করার ফাংশন
  Future<void> _pickAndCropImage(bool isProfilePic) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: isProfilePic ? const CropAspectRatio(ratioX: 1, ratioY: 1) : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isProfilePic ? 'Crop Profile Photo' : 'Drag & Position Cover',
            toolbarColor: const Color(0xFFFF6D00),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isProfilePic ? CropAspectRatioPreset.square : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
            hideBottomControls: false,
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

  // 🚀 হোস্টিংয়ে ছবি আপলোড করার ফাংশন
  Future<String?> _uploadImageToHosting(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://kothabook.com/kothabook_api/upload.php'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      if (jsonResponse['success'] == true) {
        return jsonResponse['imageUrl'];
      }
    } catch (e) { print("Upload Error: $e"); }
    return null;
  }

  // 💾 প্রোফাইল ডাটা সার্ভারে সেভ করার ফাংশন
  Future<void> _saveProfileAndGoToHome() async {
    setState(() => _isLoading = true);

    // ১. ছবি আপলোডের লজিক (ছবি গায়েব হওয়া ঠেকাতে)
    String profilePicUrlToSend = "";
    String coverPhotoUrlToSend = "";

    // প্রোফাইল পিকচার লজিক:
    if (_newProfileImage != null) {
      // যদি ইউজার নতুন ছবি সিলেক্ট করে থাকে, তবে সেটা আপলোড করে নতুন লিংক নাও
      profilePicUrlToSend = await _uploadImageToHosting(_newProfileImage!) ?? "";
    } else {
      // যদি নতুন ছবি সিলেক্ট না করে, তবে আগের যেই লিংক ডাটাবেসে ছিল, সেটাই পাঠাও (গায়েব হবে না)
      profilePicUrlToSend = _existingProfilePicUrl ?? "";
    }

    // কাভার ফটো লজিক (সেম পদ্ধতি):
    if (_newCoverImage != null) {
      coverPhotoUrlToSend = await _uploadImageToHosting(_newCoverImage!) ?? "";
    } else {
      coverPhotoUrlToSend = _existingCoverPhotoUrl ?? "";
    }

    // ৩. Node.js সার্ভারে ডাটা পাঠানো
    final String apiUrl = 'https://app.kothabook.com/api/update-profile';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.generatedUsername,
          "profilePic": profilePicUrlToSend,
          "coverPhoto": coverPhotoUrlToSend,
          "aboutMe": _aboutMeController.text.trim(),
          "relationshipStatus": _selectedRelationship,
          "workTitle": _workTitleController.text.trim(),
          "workPlace": _workPlaceController.text.trim(),
          "workLinkType": _workLinkType,
          "workUrlOrPage": _workLinkType == 'Website' ? _workLinkController.text.trim() : _selectedKothaBookPage,
          "currentCity": _currentCityController.text.trim(),
          "hometown": _hometownController.text.trim(),
          "schoolUniversity": _schoolController.text.trim(),
          "major": _majorController.text.trim(),
          "classBatch": _classController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated complete!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save data!', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      }
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error!', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingData) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    }

    // ছবি ডিসপ্লে করার লজিক
    ImageProvider profileImageProvider;
    if (_newProfileImage != null) {
      profileImageProvider = FileImage(_newProfileImage!); // ইউজার নতুন ছবি সিলেক্ট করেছে
    } else if (_existingProfilePicUrl != null && _existingProfilePicUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(_existingProfilePicUrl!); // ডাটাবেসে আগের ছবি আছে
    } else {
      profileImageProvider = const NetworkImage('https://i.pravatar.cc/150?img=11'); // কোনো ছবিই নেই, ডামি
    }

    ImageProvider coverImageProvider;
    if (_newCoverImage != null) {
      coverImageProvider = FileImage(_newCoverImage!); // নতুন ছবি
    } else if (_existingCoverPhotoUrl != null && _existingCoverPhotoUrl!.isNotEmpty) {
      coverImageProvider = NetworkImage(_existingCoverPhotoUrl!); // আগের ছবি
    } else {
      coverImageProvider = const NetworkImage('https://images.unsplash.com/photo-1557683316-973673baf926?w=800&q=80'); // ডামি
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Setup Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: false, backgroundColor: Colors.white, elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
            child: Text('Skip', style: GoogleFonts.poppins(color: const Color(0xFFFF6D00), fontWeight: FontWeight.bold, fontSize: 16)),
          ), const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover & Profile Photo Design
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Cover Photo
                  GestureDetector(
                    onTap: () => _pickAndCropImage(false),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(image: coverImageProvider, fit: BoxFit.cover),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircleAvatar(backgroundColor: Colors.white70, radius: 16, child: Icon(Icons.crop, size: 16, color: Colors.black)),
                          ),
                        ),
                    ),
                  ),
                  
                  // Profile Photo
                  Positioned(
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickAndCropImage(true),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                              image: DecorationImage(image: profileImageProvider, fit: BoxFit.cover),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFFF6D00), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('${widget.firstName} ${widget.lastName}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('@${widget.generatedUsername}', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B6B))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 1. Basic Info
            _buildSectionHeader('Basic Info'),
            _buildDropdown('Relationship Status', _selectedRelationship, relationshipOptions, (val) => setState(() => _selectedRelationship = val!)),
            _buildTextField('Bio / About Me', _aboutMeController, maxLines: 3, hint: 'Write something about yourself...'),
            const SizedBox(height: 16),
            
            // 2. Work
            _buildSectionHeader('Work'),
            _buildTextField('Work Title', _workTitleController, hint: 'Ex. Software Engineer'),
            _buildTextField('Work Place', _workPlaceController, hint: 'Ex. KheloBD'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 2, child: _buildDropdown('Link Type', _workLinkType, workLinkOptions, (val) { setState(() { _workLinkType = val!; _selectedKothaBookPage = 'Select a Page'; }); })),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _workLinkType == 'Website' ? _buildTextField('URL', _workLinkController, hint: 'www.example.com') : _buildDropdown('Select Page', _selectedKothaBookPage, userPages, (val) => setState(() => _selectedKothaBookPage = val!))),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Location
            _buildSectionHeader('Location'),
            Row(children: [Expanded(child: _buildTextField('Current City', _currentCityController, hint: 'Ex. Dhaka')), const SizedBox(width: 12), Expanded(child: _buildTextField('Hometown', _hometownController, hint: 'Ex. Chittagong'))]),
            const SizedBox(height: 16),

            // 4. Education
            _buildSectionHeader('Education'),
            _buildTextField('School/University', _schoolController, hint: 'Ex. Dhaka University'),
            Row(children: [Expanded(child: _buildTextField('Major', _majorController, hint: 'Ex. CSE')), const SizedBox(width: 12), Expanded(child: _buildTextField('Class/Batch', _classController, hint: 'Ex. 2024'))]),
            
            const SizedBox(height: 40),

            // Save & Continue Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfileAndGoToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00), foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Save & Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16, top: 8), child: Row(children: [Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))), const SizedBox(width: 12), Expanded(child: Container(height: 1, color: const Color(0xFFFF6D00).withOpacity(0.2)))]));
  }

  Widget _buildTextField(String label, TextEditingController controller, {String hint = '', int maxLines = 1}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), const SizedBox(height: 8), TextField(controller: controller, maxLines: maxLines, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13), filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5))))]));
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), const SizedBox(height: 8), DropdownButtonFormField<String>(value: value, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A1A1A)), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)), decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5))), hint: Text('Select', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13)), items: items.map((String val) => DropdownMenuItem(value: val, child: Text(val, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged)]));
  }
}