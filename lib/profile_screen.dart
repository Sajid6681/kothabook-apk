import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'widgets/post_card.dart';
import 'widgets/custom_dialog.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/top_nav_bar.dart';
import 'widgets/left_sidebar.dart'; 
import 'widgets/create_post_box.dart'; 
import 'edit_profile_screen.dart'; // 🚀 সঠিক এডিট পেজ

import 'edit_highlights_screen.dart';
import 'kothabook_verified_screen.dart';
import 'privacy_settings_screen.dart';
import 'share_profile_screen.dart';
import 'report_profile_screen.dart';
import 'add_to_story_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOwnProfile;
  const ProfileScreen({super.key, this.isOwnProfile = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLeftSidebarOpen = false;
  bool _isTopNavVisible = true;

  // Database State
  bool _isLoadingUserData = true;
  bool _isUploadingImage = false; // ছবি আপলোডের সময় লোডিং
  Map<String, dynamic> _userData = {};
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.isOwnProfile) _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 
    if (mobileNumber != null) {
      final String apiUrl = 'https://app.kothabook.com/api/user/$mobileNumber';
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _userData = jsonDecode(response.body);
              _isLoadingUserData = false;
            });
          }
        }
      } catch (e) { if (mounted) setState(() => _isLoadingUserData = false); }
    }
  }

  // 🚀 ম্যাজিক: সরাসরি গ্যালারি থেকে ছবি নিয়ে হোস্টিংয়ে সেভ করা
  Future<void> _pickAndUploadImageDirectly(bool isProfilePic) async {
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
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _isUploadingImage = true);
        File imageFile = File(croppedFile.path);

        // ১. হোস্টিংয়ে আপলোড
        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://kothabook.com/kothabook_api/upload.php'));
          request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);

          if (jsonResponse['success'] == true) {
            String uploadedUrl = jsonResponse['imageUrl'];

            // ২. Node.js ডাটাবেসে লিংক সেভ করা (অন্য ছবি গায়েব হবে না)
            final String apiUrl = 'http://127.0.0.1:5000/api/update-profile';
            Map<String, dynamic> bodyData = {"username": _userData['username']};
            if (isProfilePic) {
              bodyData["profilePic"] = uploadedUrl;
              bodyData["coverPhoto"] = _userData['coverPhoto'] ?? ""; // আগের কাভার রেখে দেওয়া
            } else {
              bodyData["coverPhoto"] = uploadedUrl;
              bodyData["profilePic"] = _userData['profilePic'] ?? ""; // আগের প্রোফাইল রেখে দেওয়া
            }

            await http.post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json"}, body: jsonEncode(bodyData));

            // ৩. রিফ্রেশ করা
            await _fetchUserData();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo Updated!'), backgroundColor: Colors.green));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload Failed!'), backgroundColor: Colors.red));
        } finally {
          setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  void _toggleLeftSidebar() { setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen); }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              _buildMenuItem(Icons.edit, 'Edit Profile', () {
                Navigator.pop(bc);
                // 🚀 সঠিক এডিট স্ক্রিনে পাঠানো হচ্ছে
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _fetchUserData());
              }),
              _buildMenuItem(Icons.stars, 'Edit Highlights', () {
                Navigator.pop(bc); Navigator.push(context, MaterialPageRoute(builder: (context) => const EditHighlightsScreen()));
              }),
              _buildMenuItem(Icons.verified, 'KothaBook Verified', () {
                Navigator.pop(bc); Navigator.push(context, MaterialPageRoute(builder: (context) => const KothabookVerifiedScreen()));
              }, color: const Color(0xFFFF6D00)),
              _buildMenuItem(Icons.lock_outline, 'Privacy Settings', () {
                Navigator.pop(bc); Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
              }),
              _buildMenuItem(Icons.share, 'Share Profile', () {
                Navigator.pop(bc); Navigator.push(context, MaterialPageRoute(builder: (context) => const ShareProfileScreen()));
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color color = const Color(0xFF1A1A1A)}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFF0F2F5), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    }

    final size = MediaQuery.of(context).size;
    String fullName = widget.isOwnProfile ? "${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}".trim() : 'Alex Johnson';
    if(fullName.isEmpty) fullName = "User";
    String usernameText = widget.isOwnProfile ? '@${_userData['username'] ?? 'username'}' : '@alex_j';
    String profileImg = widget.isOwnProfile ? ((_userData['profilePic'] != null && _userData['profilePic'].toString().isNotEmpty) ? _userData['profilePic'] : 'https://i.pravatar.cc/150?img=11') : 'https://i.pravatar.cc/150?img=33';
    String coverImg = widget.isOwnProfile ? ((_userData['coverPhoto'] != null && _userData['coverPhoto'].toString().isNotEmpty) ? _userData['coverPhoto'] : 'https://images.unsplash.com/photo-1557683316-973673baf926?w=800&q=80') : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80';
    String bioText = widget.isOwnProfile ? (_userData['aboutMe'] ?? 'i wear my attitude like a crown 👑\\nWelcome to my KothaBook Profile! 💖') : 'Wanderlust & photography 📸';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.forward) { if (!_isTopNavVisible) setState(() => _isTopNavVisible = true); } 
                else if (notification.direction == ScrollDirection.reverse) { if (_isTopNavVisible) setState(() => _isTopNavVisible = false); }
                return true;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 60),

                        // --- Cover & Avatar Section ---
                        Stack(
                          clipBehavior: Clip.none, alignment: Alignment.topCenter,
                          children: [
                            Container(height: 180, width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover), color: const Color(0xFFF8F9FA))),
                            Positioned(top: 150, left: 0, right: 0, child: Container(height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))))),
                            Positioned(
                              top: 100,
                              child: GestureDetector(
                                onTap: () => widget.isOwnProfile ? _pickAndUploadImageDirectly(true) : null, // 🚀 Profile Photo Click
                                child: Stack(
                                  children: [
                                    Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: CircleAvatar(radius: 46, backgroundImage: NetworkImage(profileImg))),
                                    if (widget.isOwnProfile)
                                      Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFF6D00), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14))),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.isOwnProfile)
                              Positioned(
                                bottom: 20, right: 16,
                                child: GestureDetector(
                                  onTap: () => _pickAndUploadImageDirectly(false), // 🚀 Cover Photo Click
                                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18)),
                                ),
                              ),
                            if (_isUploadingImage)
                               Positioned(top: 80, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)), child: const CircularProgressIndicator(color: Color(0xFFFF6D00)))),
                          ],
                        ),
                        const SizedBox(height: 50),

                        // --- Name & Verified Badge ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(fullName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Color(0xFFFF6D00), size: 22), // 🚀 Bigger Icon
                          ],
                        ),
                        Center(child: Text(usernameText, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B)))),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(bioText, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A), height: 1.5)),
                        ),
                        const SizedBox(height: 16),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem('45.6K', 'followers', () {}),
                            Text('  •  ', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                            _buildStatItem('268', 'following', () {}),
                            Text('  •  ', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                            _buildStatItem('912', 'posts', () => _tabController.animateTo(0)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: widget.isOwnProfile
                                ? [
                                    Expanded(child: _buildPrimaryButton(Icons.edit_rounded, 'Edit Profile', () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _fetchUserData());
                                    })),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildSecondaryButton(Icons.add_box_rounded, 'Add to story', () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddToStoryScreen()));
                                    })),
                                    const SizedBox(width: 8),
                                    _buildIconOnlyButton(Icons.more_horiz_rounded, _showProfileMenu),
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDetailedInfoList(),
                        const SizedBox(height: 16),
                        _buildFriendsGrid(),
                        const SizedBox(height: 24),

                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Highlights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)))),
                        const SizedBox(height: 12),
                        _buildStoryHighlights(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFFFF6D00), unselectedLabelColor: const Color(0xFFA0A0A0), indicatorColor: const Color(0xFFFF6D00), indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.dashboard_rounded, size: 16), SizedBox(width: 4), Text('Feeds')])),
                          Tab(icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.photo_library_rounded, size: 16), SizedBox(width: 4), Text('Photos')])),
                          Tab(icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.play_circle_filled_rounded, size: 16), SizedBox(width: 4), Text('Reels')])),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeedsTab(fullName, profileImg, coverImg),
                    _buildPhotosTab(),
                    _buildReelsTab(),
                  ],
                ),
              ),
            ),
          ),

          AnimatedPositioned(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, top: _isTopNavVisible ? 0 : -(MediaQuery.of(context).padding.top + 80), left: 0, right: 0, child: TopNavBar(onMenuTap: _toggleLeftSidebar)),
          if (_isLeftSidebarOpen) GestureDetector(onTap: _toggleLeftSidebar, child: Container(color: Colors.black.withOpacity(0.5), width: size.width, height: size.height)),
          AnimatedPositioned(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, left: _isLeftSidebarOpen ? 0 : -320, top: 0, bottom: 0, child: LeftSidebar(onClose: _toggleLeftSidebar)),
          Positioned(bottom: 20, left: 16, right: 16, child: BottomNavBar(onProfileTap: () {})),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildStatItem(String count, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: RichText(text: TextSpan(style: GoogleFonts.poppins(fontSize: 14), children: [TextSpan(text: count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), TextSpan(text: ' $label', style: const TextStyle(color: Color(0xFF6B6B6B)))])));
  }

  Widget _buildDetailedInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userData['workTitle'] != null && _userData['workTitle'].toString().isNotEmpty) _buildInfoRow(Icons.work_outline_rounded, 'Works as ${_userData['workTitle']} at ', _userData['workPlace'] ?? ''),
          if (_userData['currentCity'] != null && _userData['currentCity'].toString().isNotEmpty) _buildInfoRow(Icons.home_outlined, 'Lives in ', _userData['currentCity']),
          if (_userData['schoolUniversity'] != null && _userData['schoolUniversity'].toString().isNotEmpty) _buildInfoRow(Icons.school_outlined, 'Studied at ', _userData['schoolUniversity']),
          if (_userData['relationshipStatus'] != null && _userData['relationshipStatus'] != 'Single') _buildInfoRow(Icons.favorite_border_rounded, 'Status: ', _userData['relationshipStatus']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String normalText, String boldText) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFFFF6D00), size: 22), const SizedBox(width: 14), Expanded(child: RichText(text: TextSpan(style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)), children: [TextSpan(text: normalText), if (boldText.isNotEmpty) TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.bold))])))]));
  }

  Widget _buildPrimaryButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildSecondaryButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)), label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildIconOnlyButton(IconData icon, VoidCallback onTap) {
    return OutlinedButton(onPressed: onTap, child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)), style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 40), side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildFriendsGrid() {
    return const SizedBox(); // তুমি চাইলে এখানে তোমার আগের Friends Grid রাখতে পারো
  }

  Widget _buildStoryHighlights() {
    return const SizedBox(height: 50, child: Center(child: Text("Highlights Add Feature Coming Soon")));
  }

  Widget _buildFeedsTab(String name, String profilePic, String coverImg) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 120),
      children: [
        if (widget.isOwnProfile) const Padding(padding: EdgeInsets.symmetric(horizontal: 0), child: CreatePostBox()),
        const SizedBox(height: 8),
        PostWidget(isOwnPost: widget.isOwnProfile, authorName: name, avatarImg: profilePic, time: 'Just now', content: 'Updating my KothaBook Profile! ✨', postImg: coverImg),
      ],
    );
  }

  Widget _buildPhotosTab() {
    // 🚀 Photos Tab "Coming Soon"
    return Center(child: Text("Photos coming soon...", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)));
  }

  Widget _buildReelsTab() {
    // 🚀 Reels Tab "Coming Soon"
    return Center(child: Text("Reels coming soon...", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)));
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height + 1.0;
  @override double get maxExtent => tabBar.preferredSize.height + 1.0;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(color: Colors.white, child: Column(mainAxisSize: MainAxisSize.min, children: [tabBar, Container(height: 1, color: Colors.grey.shade200)])); }
  @override bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}