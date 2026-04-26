import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/bottom_nav_bar.dart'; 

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _username = '';
  
  // 🚀 Controllers
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
    _fetchExistingData();
  }

  // 🚀 ডাটাবেস থেকে ডাটা টেনে এনে বক্সে বসানোর ম্যাজিক
  Future<void> _fetchExistingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 

    if (mobileNumber != null) {
      final String apiUrl = 'https://app.kothabook.com/api/user/$mobileNumber';
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          
          if (mounted) {
            setState(() {
              _username = userData['username'] ?? '';
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
              _isLoading = false;
            });
          }
        }
      } catch (e) { if(mounted) setState(() => _isLoading = false); }
    }
  }

  // 🚀 আপডেট করা ডাটা সেভ করার ফাংশন
  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);
    final String apiUrl = 'https://app.kothabook.com/api/update-profile';

    try {
      final response = await http.post(
        Uri.parse(apiUrl), headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _username,
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

      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context); // কাজ শেষ, প্রোফাইল পেজে ফিরে যাও
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server Error!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text('Edit Profile Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [
          _isSaving 
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
            : TextButton(
                onPressed: _saveProfileData,
                child: Text('Save', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Info'),
            _buildDropdown('Relationship Status', _selectedRelationship, relationshipOptions, (val) => setState(() => _selectedRelationship = val!)),
            _buildTextField('About Me', _aboutMeController, maxLines: 3, hint: 'Write something about yourself...'),
            const SizedBox(height: 16),
            
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

            _buildSectionHeader('Location'),
            Row(children: [Expanded(child: _buildTextField('Current City', _currentCityController, hint: 'Ex. Dhaka')), const SizedBox(width: 12), Expanded(child: _buildTextField('Hometown', _hometownController, hint: 'Ex. Chittagong'))]),
            const SizedBox(height: 16),

            _buildSectionHeader('Education'),
            _buildTextField('School/University', _schoolController, hint: 'Ex. Dhaka University'),
            Row(children: [Expanded(child: _buildTextField('Major', _majorController, hint: 'Ex. CSE')), const SizedBox(width: 12), Expanded(child: _buildTextField('Class/Batch', _classController, hint: 'Ex. 2024'))]),
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