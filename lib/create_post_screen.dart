import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/custom_dialog.dart';

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
  
  String _mobileNumber = '';
  String _fullName = 'Loading...';
  String _profilePicUrl = '';
  
  List<File> _selectedImages = [];
  File? _selectedVideo; // 🚀 Reels এর জন্য
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData(); 
    if (widget.autoOpenGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto());
    }
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobile = prefs.getString('mobileNumber');
    if (mobile != null) {
      _mobileNumber = mobile;
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobile'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
              if (_fullName.isEmpty) _fullName = "User";
              _profilePicUrl = data['profilePic'] ?? '';
            });
          }
        }
      } catch (e) {
        print("Fetch User Error: $e");
      }
    }
  }

  // 🚀 Multiple Photos Selection
  Future<void> _pickPhoto() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedVideo = null; // ভিডিও থাকলে মুছে যাবে
        for (var xfile in pickedFiles) {
          _selectedImages.add(File(xfile.path));
        }
      });
    }
  }

  // 🚀 Single Video (Reels) Selection
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedImages.clear(); // ছবি থাকলে মুছে যাবে
        _selectedVideo = File(video.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() { _selectedImages.removeAt(index); });
  }

  void _removeVideo() {
    setState(() { _selectedVideo = null; });
  }

  void _attemptExit() {
    if (_textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty || _selectedVideo != null) {
      CustomDialog.show(
        context: context, title: 'Discard Post?', message: 'Are you sure you want to discard this post? Your edits will be lost.', confirmText: 'Discard', isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(), 
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text('Post Audience', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPrivacyOption(Icons.public, 'Public', 'Anyone on or off KothaBook'),
              _buildPrivacyOption(Icons.people_alt_rounded, 'Friends', 'Your friends on KothaBook'),
              _buildPrivacyOption(Icons.groups_rounded, 'Followers', 'People who follow you'),
              _buildPrivacyOption(Icons.lock_outline_rounded, 'Only me', 'Only you can see this post'), // 🚀 Only me Privacy
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle) {
    bool isSelected = _privacy == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFFF6D00) : const Color(0xFF1A1A1A)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
      trailing: isSelected ? const Icon(Icons.radio_button_checked, color: Color(0xFFFF6D00)) : null,
      onTap: () { setState(() => _privacy = title); Navigator.pop(context); },
    );
  }

  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedVideo == null) return;
    setState(() => _isPosting = true);
    
    List<String> uploadedUrls = [];

    // 🚀 আপলোডের শক্তিশালী কোড
    if (_selectedImages.isNotEmpty || _selectedVideo != null) {
      List<File> filesToUpload = _selectedImages.isNotEmpty ? _selectedImages : [_selectedVideo!];
      for (File file in filesToUpload) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://kothabook.com/kothabook_api/upload.php'));
          request.files.add(await http.MultipartFile.fromPath('image', file.path));
          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);

          if (jsonResponse['success'] == true) {
            uploadedUrls.add(jsonResponse['imageUrl']);
          }
        } catch (e) {
          print("Upload Error: $e");
        }
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://app.kothabook.com/api/create-post'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "authorId": _mobileNumber,
          "authorName": _fullName,
          "authorProfilePic": _profilePicUrl,
          "textContent": _textController.text.trim(),
          "postImageUrl": uploadedUrls.join(','),
        }),
      );

      if (mounted) {
        setState(() => _isPosting = false);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post uploaded successfully! 🎉', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post!', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Error!', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canPost = _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty || _selectedVideo != null;

    return WillPopScope(
      onWillPop: () async { _attemptExit(); return false; },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(Icons.arrow_back_rounded, _attemptExit),
                    Text('Create Post', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    _isPosting 
                      ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 2)))
                      : TextButton(onPressed: canPost ? _handlePost : null, child: Text('Post', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: canPost ? const Color(0xFFFF6D00) : Colors.grey.shade400)))
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 22, backgroundColor: const Color(0xFFE0E0E0), backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fullName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: _showPrivacySheet,
                                child: Row(children: [Text(_privacy, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B))), const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B6B6B))]),
                              )
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        constraints: const BoxConstraints(minHeight: 120),
                        child: TextField(
                          controller: _textController, maxLines: null, keyboardType: TextInputType.multiline, autofocus: !widget.autoOpenGallery,
                          style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A1A1A)),
                          decoration: InputDecoration(hintText: "What's on your mind?", hintStyle: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFFA0A0A0)), border: InputBorder.none),
                        ),
                      ),
                      
                      // 🚀 Photos Grid Preview
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _selectedImages.length == 1 ? 1 : 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: _selectedImages.length == 1 ? 4/3 : 1),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImages[index], fit: BoxFit.cover)),
                                Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => _removeImage(index), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)))),
                              ],
                            );
                          },
                        )
                      ],

                      // 🚀 Reels/Video Preview
                      if (_selectedVideo != null) ...[
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 48))),
                            Positioned(top: 8, right: 8, child: GestureDetector(onTap: _removeVideo, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)))),
                          ],
                        )
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // 🚀 Separate Photo and Reels Options
                      _buildOptionCard(Icons.photo_library_outlined, 'Photo', Colors.green, _pickPhoto), 
                      _buildOptionCard(Icons.video_library_outlined, 'Reels', Colors.purpleAccent, _pickVideo), 
                      _buildOptionCard(Icons.person_outline_rounded, 'Tag People', const Color(0xFFFF6D00), (){}),
                      _buildOptionCard(Icons.location_on_outlined, 'Add Location', Colors.red, (){}),
                      _buildOptionCard(Icons.emoji_emotions_outlined, 'Feeling/Activity', Colors.amber, (){}), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)), child: Icon(icon, color: const Color(0xFF1A1A1A), size: 20)),
    );
  }

  Widget _buildOptionCard(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22), const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)))),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFA0A0A0), size: 14),
          ],
        ),
      ),
    );
  }
}