import 'dart:io' as io; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  
  // 🚀 Real Gallery States
  List<io.File> _selectedFiles = []; 
  bool _isVideo = false; 

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickMedia(isReel: false); 
      });
    }
  }

  // ==========================================
  // 📸 গ্যালারি থেকে ছবি/ভিডিও আনার ফাংশন
  // ==========================================
  Future<void> _pickMedia({required bool isReel}) async {
    final ImagePicker picker = ImagePicker();
    
    if (isReel) {
      // 🎬 Reels (শুধুমাত্র ১টি ভিডিও)
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedFiles = [io.File(video.path)];
          _isVideo = true;
        });
      }
    } else {
      // 🖼️ Photos (মাল্টিপল ছবি)
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles = images.map((img) => io.File(img.path)).toList();
          _isVideo = false;
        });
      }
    }
  }

  // ==========================================
  // 🚀 PHP সার্ভারে ছবি/ভিডিও আপলোডের ফাংশন
  // ==========================================
  Future<String?> _uploadFileToPHP(io.File file) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://kothabook.com/kothabook_api/upload.php')
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = await response.stream.bytesToString();
        try {
          var json = jsonDecode(responseData);
          return json['url'] ?? json['file_url'] ?? json['image_url']; 
        } catch (e) {
          if (responseData.startsWith('http')) return responseData.trim();
        }
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
    return null;
  }

  // ==========================================
  // 🚀 ডাটাবেসে পোস্ট সেভ করার মেইন ফাংশন
  // ==========================================
  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('পোস্ট লেখার জন্য কিছু লিখুন বা ছবি/রিল দিন!', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() { _isPosting = true; });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? mobileNumber = prefs.getString('mobileNumber');
      if (mobileNumber == null) throw Exception('User not logged in');

      List<String> uploadedUrls = [];
      for (io.File file in _selectedFiles) {
        String? url = await _uploadFileToPHP(file);
        if (url != null) uploadedUrls.add(url);
      }

      final String apiUrl = 'https://app.kothabook.com/api/post';
      Map<String, dynamic> postData = {
        'mobileNumber': mobileNumber,
        'content': _textController.text.trim(),
        'privacy': _privacy,
      };

      if (uploadedUrls.isNotEmpty) {
        postData['mediaUrls'] = uploadedUrls;
        postData['mediaType'] = _isVideo ? 'reel' : 'photo';
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true); 
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('পোস্ট করতে সমস্যা হয়েছে!', style: GoogleFonts.poppins())),
        );
      }
    } finally {
      if (mounted) setState(() { _isPosting = false; });
    }
  }

  void _showPrivacyMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Who can see your post?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 20),
              
              _buildPrivacyOption(context, 'Public', 'Anyone on KothaBook', Icons.public),
              _buildPrivacyOption(context, 'Friends', 'Your friends on KothaBook', Icons.people_alt_outlined),
              _buildPrivacyOption(context, 'Only Me', 'Only you can see this', Icons.lock_outline),
              
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOption(BuildContext context, String title, String subtitle, IconData icon) {
    bool isSelected = _privacy == title;
    return InkWell(
      onTap: () {
        setState(() { _privacy = title; });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected ? const Color(0xFFFFF3E0).withOpacity(0.5) : Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF6D00) : Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF1A1A1A), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFFF6D00), size: 24),
          ],
        ),
      ),
    );
  }

  // 🔥 এখানেই CustomDialog বাদ দিয়ে অরিজিনাল ফ্লাটার ডায়ালগ বসানো হয়েছে
  Future<bool> _onWillPop() async {
    if (_textController.text.isNotEmpty || _selectedFiles.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text('Discard Post?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A1A1A))),
          content: Text('If you go back now, you will lose your post.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Keep Editing', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Discard', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 26),
            onPressed: () async {
              if (await _onWillPop() && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Create Post',
            style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _isPosting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isPosting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Post', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
        body: _buildCaptionView(),
      ),
    );
  }

  Widget _buildCaptionView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alex Johnson', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _showPrivacyMenu(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _privacy == 'Public' ? Icons.public : 
                                      _privacy == 'Friends' ? Icons.people_alt_outlined : Icons.lock_outline, 
                                      size: 14, color: const Color(0xFF6B6B6B)
                                    ),
                                    const SizedBox(width: 4),
                                    Text(_privacy, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B))),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF6B6B6B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 180),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF1A1A1A), height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'What is on your mind?',
                        hintStyle: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFFA0A0A0)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  if (_selectedFiles.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _isVideo 
                              ? Container(
                                  height: 200, width: double.infinity, color: Colors.black87,
                                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60)),
                                )
                              : Image.file(_selectedFiles[0], width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 12, right: 12,
                            child: GestureDetector(
                              onTap: () { setState(() { _selectedFiles.removeAt(0); if(_selectedFiles.isEmpty) _isVideo = false; }); },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          if (!_isVideo && _selectedFiles.length > 1)
                            Positioned(
                              bottom: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                                child: Text('+${_selectedFiles.length - 1} more', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: SafeArea(
            child: Row(
              children: [
                _buildCircleButton(Icons.photo_library_outlined, () => _pickMedia(isReel: false)),
                const SizedBox(width: 12),
                _buildCircleButton(Icons.video_library_outlined, () => _pickMedia(isReel: true)), 
                const SizedBox(width: 12),
                _buildCircleButton(Icons.person_add_outlined, () {}, isEnabled: false),
                const SizedBox(width: 12),
                _buildCircleButton(Icons.location_on_outlined, () {}, isEnabled: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, {bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade100, width: 1.5), color: isEnabled ? Colors.transparent : Colors.grey.shade50),
        child: Icon(icon, color: isEnabled ? const Color(0xFF1A1A1A) : Colors.grey.shade400, size: 20),
      ),
    );
  }
}