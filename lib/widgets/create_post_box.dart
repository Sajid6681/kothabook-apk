import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../create_post_screen.dart'; // পাথ ঠিক রেখো

class CreatePostBox extends StatefulWidget {
  final VoidCallback? onPostCreated;
  const CreatePostBox({super.key, this.onPostCreated});

  @override
  State<CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<CreatePostBox> {
  String _profilePicUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData(); 
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobile = prefs.getString('mobileNumber');
    if (mobile != null) {
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobile'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) setState(() { _profilePicUrl = data['profilePic'] ?? ''; });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 🚀 আগের মত মার্জিন
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20, 
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen(autoOpenGallery: false)),
                ).then((value) {
                  if (value == true && widget.onPostCreated != null) widget.onPostCreated!();
                });
              },
              child: Container(
                color: Colors.transparent, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What is on your mind?', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B6B6B), fontWeight: FontWeight.w500)),
                    Text('@Mention.. Link..', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFA0A0A0))),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen(autoOpenGallery: true)),
              ).then((value) {
                  if (value == true && widget.onPostCreated != null) widget.onPostCreated!();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.image_outlined, color: Color(0xFFFF6D00), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}