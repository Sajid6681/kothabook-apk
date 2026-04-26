import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/bottom_nav_bar.dart'; 

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true; bool _isSaving = false; String _username = '';
  
  final _aboutMeController = TextEditingController();
  final _workTitleController = TextEditingController();
  final _workPlaceController = TextEditingController();
  final _workLinkController = TextEditingController(); 
  final _currentCityController = TextEditingController();
  final _hometownController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _classController = TextEditingController();
  String _selectedRelationship = 'Single'; String _workLinkType = 'Website'; String _selectedKothaBookPage = 'Select a Page';

  @override void initState() { super.initState(); _fetchExistingData(); }

  // 🚀 লাইভ ডাটাবেস থেকে ডাটা আনা
  Future<void> _fetchExistingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 
    if (mobileNumber != null) {
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobileNumber'));
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _username = userData['username'] ?? ''; _aboutMeController.text = userData['aboutMe'] ?? ''; _workTitleController.text = userData['workTitle'] ?? ''; _workPlaceController.text = userData['workPlace'] ?? ''; _currentCityController.text = userData['currentCity'] ?? ''; _hometownController.text = userData['hometown'] ?? ''; _schoolController.text = userData['schoolUniversity'] ?? ''; _majorController.text = userData['major'] ?? ''; _classController.text = userData['classBatch'] ?? ''; _selectedRelationship = userData['relationshipStatus'] ?? 'Single'; _workLinkType = userData['workLinkType'] ?? 'Website';
              if(_workLinkType == 'Website') _workLinkController.text = userData['workUrlOrPage'] ?? ''; else _selectedKothaBookPage = userData['workUrlOrPage'] ?? 'Select a Page';
              _isLoading = false;
            });
          }
        }
      } catch (e) { if(mounted) setState(() => _isLoading = false); }
    }
  }

  // 🚀 লাইভ সার্ভারে সেভ করা
  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('https://app.kothabook.com/api/update-profile'), headers: {"Content-Type": "application/json"},
        body: jsonEncode({ "username": _username, "aboutMe": _aboutMeController.text.trim(), "relationshipStatus": _selectedRelationship, "workTitle": _workTitleController.text.trim(), "workPlace": _workPlaceController.text.trim(), "workLinkType": _workLinkType, "workUrlOrPage": _workLinkType == 'Website' ? _workLinkController.text.trim() : _selectedKothaBookPage, "currentCity": _currentCityController.text.trim(), "hometown": _hometownController.text.trim(), "schoolUniversity": _schoolController.text.trim(), "major": _majorController.text.trim(), "classBatch": _classController.text.trim() }),
      );
      setState(() => _isSaving = false);
      if (response.statusCode == 200) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green)); Navigator.pop(context); }
    } catch (e) { setState(() => _isSaving = false); }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text('Edit Profile Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)), actions: [_isSaving ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFFFF6D00))) : TextButton(onPressed: _saveProfileData, child: Text('Save', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF6D00))))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit your info here...", style: GoogleFonts.poppins(fontSize: 14)), const SizedBox(height: 16),
            TextField(controller: _aboutMeController, decoration: const InputDecoration(labelText: "About Me", border: OutlineInputBorder())), const SizedBox(height: 16),
            TextField(controller: _currentCityController, decoration: const InputDecoration(labelText: "Current City", border: OutlineInputBorder())), const SizedBox(height: 16),
            TextField(controller: _workPlaceController, decoration: const InputDecoration(labelText: "Workplace", border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}