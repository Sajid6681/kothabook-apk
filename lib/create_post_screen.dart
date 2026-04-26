import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreatePostScreen extends StatefulWidget {
  final bool autoOpenGallery;
  
  const CreatePostScreen({super.key, this.autoOpenGallery = false});
  
  @override 
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isPosting = false; 
  String _privacy = 'Public';
  
  String _authorId = ""; 
  String _authorName = "User"; 
  String _authorProfilePic = "";
  List<File> _selectedImages = []; 
  final ImagePicker _picker = ImagePicker();

  @override 
  void initState() {
    super.initState(); 
    _fetchUserData();
    if (widget.autoOpenGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobile = prefs.getString('mobileNumber'); 
    _authorId = mobile ?? "";
    
    if (mobile != null) {
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobile'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() { 
              _authorName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim(); 
              _authorProfilePic = data['profilePic'] ?? ''; 
            });
          }
        }
      } catch (e) { 
        print(e); 
      }
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() { 
        for (var xfile in pickedFiles) { 
          _selectedImages.add(File(xfile.path)); 
        } 
      });
    }
  }

  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty && _selectedImages.isEmpty) return;
    
    setState(() => _isPosting = true);
    
    List<String> uploadedUrls = [];
    if (_selectedImages.isNotEmpty) {
      for (File imageFile in _selectedImages) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://app.kothabook.com/kothabook_api/upload.php'));
          request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
          var response = await request.send();
          var jsonResponse = jsonDecode(await response.stream.bytesToString());
          if (jsonResponse['success'] == true) uploadedUrls.add(jsonResponse['imageUrl']);
        } catch (e) { 
          print(e); 
        }
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://app.kothabook.com/api/create-post'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "authorId": _authorId, 
          "authorName": _authorName, 
          "authorProfilePic": _authorProfilePic, 
          "textContent": _textController.text.trim(), 
          "postImageUrl": uploadedUrls.join(',')
        }),
      );
      
      if (mounted) {
        setState(() => _isPosting = false);
        if (response.statusCode == 201) { 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post uploaded successfully! 🎉'), backgroundColor: Colors.green)
          ); 
          Navigator.pop(context, true); 
        }
      }
    } catch (e) { 
      if (mounted) setState(() => _isPosting = false); 
    }
  }

  @override 
  void dispose() { 
    _textController.dispose(); 
    super.dispose(); 
  }

  @override 
  Widget build(BuildContext context) {
    bool canPost = _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0), 
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: Colors.grey.shade300, width: 1.5)
            ), 
            child: IconButton(
              padding: EdgeInsets.zero, 
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 20), 
              onPressed: () => Navigator.pop(context)
            )
          )
        ),
        title: Text(
          'Create Post', 
          style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.bold)
        ), 
        centerTitle: true,
        actions: [
          _isPosting 
            ? const Padding(
                padding: EdgeInsets.only(right: 24), 
                child: Center(
                  child: SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 2)
                  )
                )
              ) 
            : TextButton(
                onPressed: canPost ? _handlePost : null, 
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), 
                  child: Text(
                    'Post', 
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: canPost ? const Color(0xFFFF6D00) : Colors.grey.shade400)
                  )
                )
              )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22, 
                        backgroundColor: Colors.grey.shade200, 
                        backgroundImage: _authorProfilePic.isNotEmpty ? NetworkImage(_authorProfilePic) : null
                      ), 
                      const SizedBox(width: 12), 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(
                            _authorName, 
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))
                          ), 
                          const SizedBox(height: 2), 
                          Row(
                            children: [
                              Text(
                                _privacy, 
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B))
                              ), 
                              const SizedBox(width: 4), 
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B6B6B))
                            ]
                          )
                        ]
                      )
                    ]
                  ), 
                  const SizedBox(height: 20),
                  
                  // এখানেই Error টি ছিল! minHeight কে constraints এর ভেতরে দেয়া হয়েছে।
                  Container(
                    width: double.infinity, 
                    constraints: const BoxConstraints(minHeight: 180), // Fix applied here
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA), 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0), 
                          child: TextField(
                            controller: _textController, 
                            maxLines: null, 
                            keyboardType: TextInputType.multiline, 
                            style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A1A1A)), 
                            decoration: InputDecoration(
                              hintText: "Write a caption...", 
                              hintStyle: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFFA0A0A0)), 
                              border: InputBorder.none, 
                              isDense: true, 
                              contentPadding: EdgeInsets.zero
                            )
                          )
                        ), 
                        if (_selectedImages.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.all(12.0), 
                            child: Wrap(
                              spacing: 8, 
                              runSpacing: 8, 
                              children: _selectedImages.map((img) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8), 
                                    child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover)
                                  ), 
                                  Positioned(
                                    top: 4, 
                                    right: 4, 
                                    child: GestureDetector(
                                      onTap: () => setState(()=> _selectedImages.remove(img)), 
                                      child: Container(
                                        padding: const EdgeInsets.all(2), 
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                                        child: const Icon(Icons.close, color: Colors.white, size: 14)
                                      )
                                    )
                                  )
                                ]
                              )).toList()
                            )
                          )
                      ]
                    )
                  ), 
                  const SizedBox(height: 24),
                  _buildOptionCard(Icons.photo_library_outlined, 'Photo/Video', _pickImage), 
                  _buildOptionCard(Icons.person_outline_rounded, 'Tag People', (){}), 
                  _buildOptionCard(Icons.location_on_outlined, 'Add Location', (){}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: Colors.grey.shade200), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ]
        ), 
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6D00), size: 22), 
            const SizedBox(width: 16), 
            Expanded(
              child: Text(
                title, 
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))
              )
            ), 
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFA0A0A0), size: 20)
          ]
        )
      )
    );
  }
}