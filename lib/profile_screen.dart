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
import 'edit_profile_screen.dart'; 
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
  bool _isLoadingUserData = true; 
  bool _isUploadingImage = false; 
  
  Map<String, dynamic> _userData = {};
  final ImagePicker _picker = ImagePicker();

  @override 
  void initState() { 
    super.initState(); 
    _tabController = TabController(length: 3, vsync: this); 
    if (widget.isOwnProfile) {
      _fetchUserData(); 
    }
  }

  // 🚀 লাইভ সার্ভার থেকে ইউজারের ডাটা আনা
  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 
    if (mobileNumber != null) {
      try {
        final response = await http.get(Uri.parse('https://app.kothabook.com/api/user/$mobileNumber'));
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() { 
              _userData = jsonDecode(response.body); 
              _isLoadingUserData = false; 
            });
          }
        }
      } catch (e) { 
        if (mounted) setState(() => _isLoadingUserData = false); 
      }
    } else {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  // 🚀 ছবি আপলোড লজিক
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
        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://app.kothabook.com/kothabook_api/upload.php'));
          request.files.add(await http.MultipartFile.fromPath('image', File(croppedFile.path).path));
          var response = await request.send();
          var jsonResponse = jsonDecode(await response.stream.bytesToString());
          
          if (jsonResponse['success'] == true) {
            String uploadedUrl = jsonResponse['imageUrl'];
            Map<String, dynamic> bodyData = {"username": _userData['username']};
            if (isProfilePic) { 
              bodyData["profilePic"] = uploadedUrl; 
              bodyData["coverPhoto"] = _userData['coverPhoto'] ?? ""; 
            } else { 
              bodyData["coverPhoto"] = uploadedUrl; 
              bodyData["profilePic"] = _userData['profilePic'] ?? ""; 
            }
            
            await http.post(
              Uri.parse('https://app.kothabook.com/api/update-profile'), 
              headers: {"Content-Type": "application/json"}, 
              body: jsonEncode(bodyData)
            );
            
            await _fetchUserData();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo Updated!'), backgroundColor: Colors.green));
          }
        } catch (e) { 
          print(e); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update photo!'), backgroundColor: Colors.red));
        } finally { 
          setState(() => _isUploadingImage = false); 
        }
      }
    }
  }

  void _toggleLeftSidebar() { 
    setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen); 
  }

  // Bottom Sheet Menu for Profile Options
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _fetchUserData());
              }),
              _buildMenuItem(Icons.stars, 'Edit Highlights', () {
                Navigator.pop(bc); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditHighlightsScreen()));
              }),
              _buildMenuItem(Icons.verified, 'KothaBook Verified', () {
                Navigator.pop(bc); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const KothabookVerifiedScreen()));
              }, color: const Color(0xFFFF6D00)),
              _buildMenuItem(Icons.lock_outline, 'Privacy Settings', () {
                Navigator.pop(bc); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
              }),
              _buildMenuItem(Icons.share, 'Share Profile', () {
                Navigator.pop(bc); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShareProfileScreen()));
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
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: const BoxDecoration(color: Color(0xFFF0F2F5), shape: BoxShape.circle), 
        child: Icon(icon, color: color, size: 22)
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      onTap: onTap,
    );
  }

  @override 
  Widget build(BuildContext context) {
    if (_isLoadingUserData && widget.isOwnProfile) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    }

    final size = MediaQuery.of(context).size;
    String fullName = widget.isOwnProfile ? "${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}".trim() : 'Alex Johnson';
    if(fullName.isEmpty) fullName = "User";
    
    String profileImg = widget.isOwnProfile ? ((_userData['profilePic'] != null && _userData['profilePic'].toString().isNotEmpty) ? _userData['profilePic'] : 'https://i.pravatar.cc/150?img=11') : 'https://i.pravatar.cc/150?img=33';
    String coverImg = widget.isOwnProfile ? ((_userData['coverPhoto'] != null && _userData['coverPhoto'].toString().isNotEmpty) ? _userData['coverPhoto'] : 'https://images.unsplash.com/photo-1557683316-973673baf926?w=800&q=80') : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80';
    String bioText = widget.isOwnProfile ? (_userData['aboutMe'] ?? 'No bio available') : 'Wanderlust & photography 📸';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.forward) { 
                  if (!_isTopNavVisible) setState(() => _isTopNavVisible = true); 
                } else if (notification.direction == ScrollDirection.reverse) { 
                  if (_isTopNavVisible) setState(() => _isTopNavVisible = false); 
                }
                return true;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 60),
                        
                        // --- Cover & Profile Section ---
                        Stack(
                          clipBehavior: Clip.none, 
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              height: 180, 
                              width: double.infinity, 
                              decoration: BoxDecoration(
                                image: DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover), 
                                color: const Color(0xFFF8F9FA)
                              )
                            ),
                            Positioned(
                              top: 150, left: 0, right: 0, 
                              child: Container(
                                height: 40, 
                                decoration: const BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30))
                                )
                              )
                            ),
                            Positioned(
                              top: 100, 
                              child: GestureDetector(
                                onTap: () => widget.isOwnProfile ? _pickAndUploadImageDirectly(true) : null, 
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4), 
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), 
                                      child: CircleAvatar(radius: 46, backgroundImage: NetworkImage(profileImg))
                                    ), 
                                    if (widget.isOwnProfile) 
                                      Positioned(
                                        bottom: 4, right: 4, 
                                        child: Container(
                                          padding: const EdgeInsets.all(6), 
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6D00), 
                                            shape: BoxShape.circle, 
                                            border: Border.all(color: Colors.white, width: 2)
                                          ), 
                                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14)
                                        )
                                      )
                                  ]
                                )
                              )
                            ),
                            if (widget.isOwnProfile) 
                              Positioned(
                                bottom: 20, right: 16, 
                                child: GestureDetector(
                                  onTap: () => _pickAndUploadImageDirectly(false), 
                                  child: Container(
                                    padding: const EdgeInsets.all(8), 
                                    decoration: BoxDecoration(
                                      color: Colors.black54, 
                                      shape: BoxShape.circle, 
                                      border: Border.all(color: Colors.white, width: 1.5)
                                    ), 
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18)
                                  )
                                )
                              ),
                            if (_isUploadingImage) 
                              Positioned(
                                top: 80, 
                                child: Container(
                                  padding: const EdgeInsets.all(10), 
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)), 
                                  child: const CircularProgressIndicator(color: Color(0xFFFF6D00))
                                )
                              ),
                          ],
                        ), 
                        const SizedBox(height: 50),
                        
                        // --- Name & Bio ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Text(fullName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), 
                            const SizedBox(width: 6), 
                            const Icon(Icons.verified, color: Color(0xFFFF6D00), size: 22)
                          ]
                        ),
                        Center(
                          child: Text('@${_userData['username'] ?? 'username'}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B)))
                        ), 
                        const SizedBox(height: 12),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24), 
                          child: Text(bioText, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A), height: 1.5))
                        ), 
                        const SizedBox(height: 16),
                        
                        // --- Stats ---
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
                        
                        // --- Action Buttons ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: widget.isOwnProfile
                                ? [
                                    Expanded(
                                      child: _buildPrimaryButton(Icons.edit_rounded, 'Edit Profile', () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _fetchUserData());
                                      })
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildSecondaryButton(Icons.add_box_rounded, 'Add to story', () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddToStoryScreen()));
                                      })
                                    ),
                                    const SizedBox(width: 8),
                                    _buildIconOnlyButton(Icons.more_horiz_rounded, _showProfileMenu),
                                  ]
                                : [
                                    Expanded(
                                      child: _buildPrimaryButton(Icons.person_add_rounded, 'Add Friend', () {})
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildSecondaryButton(Icons.message_rounded, 'Message', () {})
                                    ),
                                    const SizedBox(width: 8),
                                    _buildIconOnlyButton(Icons.more_horiz_rounded, () {}),
                                ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // --- Detailed Info List ---
                        _buildDetailedInfoList(),
                        const SizedBox(height: 16),
                        
                        // --- Friends Grid ---
                        _buildFriendsGrid(),
                        const SizedBox(height: 24),

                        // --- Story Highlights ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16), 
                          child: Text('Highlights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)))
                        ),
                        const SizedBox(height: 12),
                        _buildStoryHighlights(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // --- Tab Bar ---
                  SliverPersistentHeader(
                    pinned: true, 
                    delegate: _StickyTabBarDelegate(
                      TabBar(
                        controller: _tabController, 
                        labelColor: const Color(0xFFFF6D00), 
                        unselectedLabelColor: Colors.grey, 
                        indicatorColor: const Color(0xFFFF6D00),
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Feeds'), 
                          Tab(text: 'Photos'), 
                          Tab(text: 'Reels')
                        ]
                      )
                    )
                  ),
                ],
                body: TabBarView(
                  controller: _tabController, 
                  children: [
                    _buildFeedsTab(fullName, profileImg, coverImg), 
                    _buildPhotosTab(), 
                    _buildReelsTab()
                  ]
                ),
              ),
            ),
          ),
          
          // --- App Bars & Sidebars ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), 
            top: _isTopNavVisible ? 0 : -80, left: 0, right: 0, 
            child: TopNavBar(onMenuTap: _toggleLeftSidebar)
          ),
          if (_isLeftSidebarOpen) 
            GestureDetector(
              onTap: _toggleLeftSidebar, 
              child: Container(color: Colors.black54, width: size.width, height: size.height)
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), 
            left: _isLeftSidebarOpen ? 0 : -320, top: 0, bottom: 0, 
            child: LeftSidebar(onClose: _toggleLeftSidebar)
          ),
          Positioned(
            bottom: 20, left: 16, right: 16, 
            child: BottomNavBar(onProfileTap: () {})
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  
  Widget _buildStatItem(String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 14), 
          children: [
            TextSpan(text: count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), 
            TextSpan(text: ' $label', style: const TextStyle(color: Color(0xFF6B6B6B)))
          ]
        )
      )
    );
  }

  Widget _buildPrimaryButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap, 
      icon: Icon(icon, size: 16), 
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)), 
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6D00), 
        foregroundColor: Colors.white, 
        elevation: 0, 
        padding: const EdgeInsets.symmetric(vertical: 10), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      )
    );
  }

  Widget _buildSecondaryButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap, 
      icon: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)), 
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis), 
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10), 
        side: BorderSide(color: Colors.grey.shade300, width: 1.5), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      )
    );
  }

  Widget _buildIconOnlyButton(IconData icon, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap, 
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero, 
        minimumSize: const Size(44, 40), 
        side: BorderSide(color: Colors.grey.shade300, width: 1.5), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A))
    );
  }

  Widget _buildDetailedInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userData['workTitle'] != null && _userData['workTitle'].toString().isNotEmpty) 
            _buildInfoRow(Icons.work_outline_rounded, 'Works as ${_userData['workTitle']} at ', _userData['workPlace'] ?? ''),
          if (_userData['currentCity'] != null && _userData['currentCity'].toString().isNotEmpty) 
            _buildInfoRow(Icons.home_outlined, 'Lives in ', _userData['currentCity']),
          if (_userData['schoolUniversity'] != null && _userData['schoolUniversity'].toString().isNotEmpty) 
            _buildInfoRow(Icons.school_outlined, 'Studied at ', _userData['schoolUniversity']),
          if (_userData['relationshipStatus'] != null && _userData['relationshipStatus'] != 'Single') 
            _buildInfoRow(Icons.favorite_border_rounded, 'Status: ', _userData['relationshipStatus']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String normalText, String boldText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Icon(icon, color: const Color(0xFFFF6D00), size: 22), 
          const SizedBox(width: 14), 
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)), 
                children: [
                  TextSpan(text: normalText), 
                  if (boldText.isNotEmpty) TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.bold))
                ]
              )
            )
          )
        ]
      )
    );
  }

  Widget _buildFriendsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Friends', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  Text('4,502 friends', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
              Text('Find Friends', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFFF6D00), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              List<String> names = ['Ishrat', 'David', 'Sarah', 'Mike', 'Emma', 'John'];
              List<String> images = [
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
                'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
                'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&q=80',
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(images[index], fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(names[index], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('See All Friends', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)))),
          )
        ],
      ),
    );
  }

  Widget _buildStoryHighlights() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index == 0 && widget.isOwnProfile) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)),
                    child: const Icon(Icons.add_rounded, color: Colors.black87, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text('New', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }
          List<String> titles = ['Travel ✈️', 'Food 🍔', 'Family ❤️', 'Vibes ✨'];
          List<String> images = [
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&q=80',
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=200&q=80',
            'https://images.unsplash.com/photo-1518002171953-a080ee817e1f?w=200&q=80',
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=200&q=80',
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 65, height: 65,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.network(images[index], fit: BoxFit.cover)),
                ),
                const SizedBox(height: 6),
                Text(titles[index], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedsTab(String name, String profilePic, String coverImg) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 120),
      children: [
        if (widget.isOwnProfile) const CreatePostBox(),
        const SizedBox(height: 8),
        PostWidget(
          isOwnPost: widget.isOwnProfile, 
          authorName: name, 
          avatarImg: profilePic, 
          time: 'Just now', 
          content: 'Updated my KothaBook Profile! ✨', 
          postImg: coverImg
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        List<String> images = [
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80',
          'https://images.unsplash.com/photo-1518002171953-a080ee817e1f?w=400&q=80',
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&q=80',
          'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400&q=80',
          'https://images.unsplash.com/photo-1470071131384-001b85755536?w=400&q=80',
          'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=400&q=80',
          'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=400&q=80',
          'https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=400&q=80',
        ];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(images[index], fit: BoxFit.cover)
        );
      },
    );
  }

  Widget _buildReelsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Reels Yet", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      )
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate { 
  final TabBar tabBar; 
  _StickyTabBarDelegate(this.tabBar); 
  
  @override 
  double get minExtent => tabBar.preferredSize.height + 1.0; 
  
  @override 
  double get maxExtent => tabBar.preferredSize.height + 1.0; 
  
  @override 
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { 
    return Container(
      color: Colors.white, 
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          tabBar, 
          Container(height: 1, color: Colors.grey.shade200)
        ]
      )
    ); 
  } 
  
  @override 
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false; 
}