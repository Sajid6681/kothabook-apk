import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// পাথ আপডেট করা হয়েছে যেহেতু ফাইলটি lib ফোল্ডারের সরাসরি ভেতরে
import '../create_post_screen.dart'; 

class CreatePostBox extends StatefulWidget {
  const CreatePostBox({super.key});
  @override State<CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<CreatePostBox> {
  String _firstName = "Loading...";
  String _profilePicUrl = ""; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 
    if (mobileNumber != null) {
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobileNumber'));
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          if (mounted) {
            setState(() { 
              _firstName = userData['firstName'] ?? "User"; 
              _profilePicUrl = userData['profilePic'] ?? ""; 
            });
          }
        }
      } catch (error) { 
        print(error); 
      }
    }
  }

  void _goToCreatePost(bool autoOpenGallery) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => CreatePostScreen(autoOpenGallery: autoOpenGallery))
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToCreatePost(false), 
      child: Container(
        color: Colors.white, 
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20, 
                  backgroundColor: const Color(0xFFE0E0E0), 
                  backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null, 
                  child: _profilePicUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9), 
                      borderRadius: BorderRadius.circular(24)
                    ), 
                    child: Text(
                      "What's on your mind, $_firstName?", 
                      style: GoogleFonts.poppins(color: const Color(0xFFA0A0A0), fontSize: 14)
                    )
                  )
                ),
              ],
            ),
            const SizedBox(height: 12), 
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)), 
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionItem(Icons.video_call_rounded, Colors.redAccent, 'Live', false),
                Container(width: 1, height: 24, color: const Color(0xFFF0F0F0)),
                _buildActionItem(Icons.photo_library_rounded, Colors.green, 'Photo', true),
                Container(width: 1, height: 24, color: const Color(0xFFF0F0F0)),
                _buildActionItem(Icons.video_camera_back_rounded, Colors.purpleAccent, 'Room', false),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, Color color, String label, bool isGallery) {
    return GestureDetector(
      onTap: () => _goToCreatePost(isGallery),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20), 
          const SizedBox(width: 6), 
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6B6B6B)))
        ]
      ),
    );
  }
}