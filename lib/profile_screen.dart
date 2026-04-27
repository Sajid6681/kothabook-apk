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
import 'kothabook_verified_screen.dart';
import 'privacy_settings_screen.dart';
import 'share_profile_screen.dart';
import 'report_profile_screen.dart';
import 'add_to_story_screen.dart';

const String _kBaseUrl = 'https://app.kothabook.com/api';

class ProfileScreen extends StatefulWidget {
  final bool isOwnProfile;
  final String? profileUserId;

  const ProfileScreen({
    super.key,
    this.isOwnProfile = true,
    this.profileUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLeftSidebarOpen = false;
  bool _isTopNavVisible = true;

  String _currentUserId = '';
  String _currentUserMobile = '';

  bool _isLoadingUserData = true;
  bool _isUploadingImage = false;
  Map<String, dynamic> _userData = {};

  List<dynamic> _feedPosts = [];
  List<dynamic> _photos    = [];
  List<dynamic> _reels     = [];
  bool _loadingPosts  = true;
  bool _loadingPhotos = true;
  bool _loadingReels  = true;

  List<dynamic> _friends = [];
  // ✅ Friend Requests section — profile থেকে সরানো হয়েছে (top nav bar এ যাবে)
  String _friendshipStatus = 'none'; // none | friends | request_sent | request_received
  bool _loadingFriends = true;

  // ── Follow status
  bool _isFollowing = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserMobile = prefs.getString('mobileNumber') ?? '';
    _currentUserId     = prefs.getString('userId') ?? '';

    if (widget.isOwnProfile) {
      await _fetchUserData(byMobile: true, mobile: _currentUserMobile);
    } else {
      await _fetchUserData(byId: true, id: widget.profileUserId ?? '');
      await _fetchFriendshipStatus();
    }

    final profileId = _userData['_id']?.toString() ?? widget.profileUserId ?? '';
    await Future.wait([
      _fetchFeedPosts(profileId),
      _fetchPhotos(profileId),
      _fetchReels(profileId),
      _fetchFriends(profileId),
    ]);

  }

  // ──────────────────────────────────────────────────────────
  // FETCH USER DATA
  // ──────────────────────────────────────────────────────────
  Future<void> _fetchUserData({bool byMobile = false, String mobile = '', bool byId = false, String id = ''}) async {
    try {
      final uri = byMobile
          ? Uri.parse('$_kBaseUrl/user/$mobile')
          : Uri.parse('$_kBaseUrl/user-by-id/$id');
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _userData = jsonDecode(res.body);
          _isLoadingUserData = false;
        });
        if (byMobile) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          _currentUserId = _userData['_id']?.toString() ?? '';
          await prefs.setString('userId', _currentUserId);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // FETCH POSTS / PHOTOS / REELS
  // ──────────────────────────────────────────────────────────
  Future<void> _fetchFeedPosts(String authorId) async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/user-posts/$authorId'));
      if (res.statusCode == 200 && mounted) setState(() { _feedPosts = jsonDecode(res.body); _loadingPosts = false; });
    } catch (_) { if (mounted) setState(() => _loadingPosts = false); }
  }

  Future<void> _fetchPhotos(String authorId) async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/user-photos/$authorId'));
      if (res.statusCode == 200 && mounted) setState(() { _photos = jsonDecode(res.body); _loadingPhotos = false; });
    } catch (_) { if (mounted) setState(() => _loadingPhotos = false); }
  }

  Future<void> _fetchReels(String authorId) async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/user-reels/$authorId'));
      if (res.statusCode == 200 && mounted) setState(() { _reels = jsonDecode(res.body); _loadingReels = false; });
    } catch (_) { if (mounted) setState(() => _loadingReels = false); }
  }

  // ──────────────────────────────────────────────────────────
  // FRIENDS
  // ──────────────────────────────────────────────────────────
  Future<void> _fetchFriends(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friends/$userId'));
      if (res.statusCode == 200 && mounted) setState(() { _friends = jsonDecode(res.body); _loadingFriends = false; });
    } catch (_) { if (mounted) setState(() => _loadingFriends = false); }
  }

  Future<void> _fetchFriendshipStatus() async {
    if (_currentUserId.isEmpty || widget.profileUserId == null) return;
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friendship-status?currentUserId=$_currentUserId&targetUserId=${widget.profileUserId}'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _friendshipStatus = data['status'] ?? 'none';
          _isFollowing = data['isFollowing'] ?? false; // ✅ Follow status একসাথে লোড হবে
        });
      }
    } catch (_) {}
  }

  Future<void> _sendFriendRequest() async {
    try {
      final res = await http.post(Uri.parse('$_kBaseUrl/send-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fromUserId': _currentUserId, 'toUserId': widget.profileUserId}));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _friendshipStatus = 'request_sent';
          _isFollowing = true; // ✅ Auto-follow হয়ে যাবে
        });
      }
    } catch (_) {}
  }

  Future<void> _acceptFriendRequest(String fromUserId) async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/accept-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'fromUserId': fromUserId}));
      await _fetchFriends(_currentUserId);
      setState(() => _friendshipStatus = 'friends');
    } catch (_) {}
  }

  Future<void> _unfriend() async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/unfriend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'targetUserId': widget.profileUserId}));
      if (mounted) setState(() => _friendshipStatus = 'none');
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────
  // FOLLOW / UNFOLLOW
  // ──────────────────────────────────────────────────────────
  Future<void> _toggleFollow() async {
    final targetUserId = widget.profileUserId ?? '';
    if (targetUserId.isEmpty) return;

    // ✅ Unfollow এ confirmation popup
    if (_isFollowing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Unfollow?"),
          content: Text(
            'Are you sure you want to unfollow this user?',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Unfollow", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final endpoint = _isFollowing ? 'unfollow' : 'follow';
      final res = await http.post(
        Uri.parse('$_kBaseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'currentUserId': _currentUserId, 'targetUserId': targetUserId}),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────
  // HIGHLIGHTS & ALBUMS
  // ──────────────────────────────────────────────────────────
  Future<void> _addHighlight(String title, String coverImg) async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/add-highlight'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': _currentUserId, 'title': title, 'coverImg': coverImg, 'stories': []}));
      await _fetchUserData(byMobile: true, mobile: _currentUserMobile);
    } catch (_) {}
  }

  Future<void> _deleteHighlight(String highlightId) async {
    try {
      await http.delete(Uri.parse('$_kBaseUrl/delete-highlight'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': _currentUserId, 'highlightId': highlightId}));
      await _fetchUserData(byMobile: true, mobile: _currentUserMobile);
    } catch (_) {}
  }

  Future<void> _createAlbum(String title) async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/create-album'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': _currentUserId, 'title': title, 'coverImg': ''}));
      await _fetchUserData(byMobile: true, mobile: _currentUserMobile);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────
  // PHOTO UPLOAD
  // ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadImageDirectly(bool isProfilePic) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: isProfilePic
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : const CropAspectRatio(ratioX: 16, ratioY: 9),
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
        var request = http.MultipartRequest('POST', Uri.parse('https://kothabook.com/kothabook_api/upload.php'));
        request.files.add(await http.MultipartFile.fromPath('image', croppedFile.path));
        var res = await request.send();
        var jsonResp = jsonDecode(await res.stream.bytesToString());

        if (jsonResp['success'] == true) {
          String uploadedUrl = jsonResp['imageUrl'];
          Map<String, dynamic> body = {"username": _userData['username']};
          if (isProfilePic) { body["profilePic"] = uploadedUrl; body["coverPhoto"] = _userData['coverPhoto'] ?? ""; }
          else              { body["coverPhoto"] = uploadedUrl;  body["profilePic"] = _userData['profilePic'] ?? ""; }
          await http.post(Uri.parse('$_kBaseUrl/update-profile'), headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
          await _fetchUserData(byMobile: true, mobile: _currentUserMobile);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo Updated!'), backgroundColor: Colors.green));
        }
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload Failed!'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  void _toggleLeftSidebar() => setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen);

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (bc) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          _buildMenuItem(Icons.edit, 'Edit Profile', () {
            Navigator.pop(bc);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                .then((_) => _fetchUserData(byMobile: true, mobile: _currentUserMobile));
          }),
          _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Settings', () {
            Navigator.pop(bc);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
          }),
          _buildMenuItem(Icons.share_outlined, 'Share Profile', () {
            Navigator.pop(bc);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareProfileScreen()));
          }),
          _buildMenuItem(Icons.verified_outlined, 'KothaBook Verified', () {
            Navigator.pop(bc);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KothabookVerifiedScreen()));
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showOtherProfileMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (bc) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          _buildMenuItem(Icons.block_outlined, 'Block User', () { Navigator.pop(bc); }),
          _buildMenuItem(Icons.flag_outlined, 'Report Profile', () {
            Navigator.pop(bc);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportProfileScreen()));
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6D00)),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoadingUserData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))));
    }

    final String fullName = '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}'.trim();
    final String usernameText = '@${_userData['username'] ?? ''}';
    final String profileImg = (_userData['profilePic'] != null && _userData['profilePic'].toString().isNotEmpty)
        ? _userData['profilePic']
        : (_userData['gender']?.toString().toLowerCase() == 'female'
            ? 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png'
            : 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_male.png');
    final String coverImg = (_userData['coverPhoto'] != null && _userData['coverPhoto'].toString().isNotEmpty)
        ? _userData['coverPhoto']
        : 'https://images.unsplash.com/photo-1557683316-973673baf926?w=800&q=80';
    final String bioText = _userData['aboutMe'] ?? 'Welcome to my KothaBook Profile! 💖';
    final int followerCount  = (_userData['followers'] as List?)?.length ?? 0;
    final int followingCount = (_userData['following'] as List?)?.length ?? 0;
    final int postsCount     = _feedPosts.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.direction == ScrollDirection.forward && !_isTopNavVisible) {
                  setState(() => _isTopNavVisible = true);
                } else if (n.direction == ScrollDirection.reverse && _isTopNavVisible) {
                  setState(() => _isTopNavVisible = false);
                }
                return true;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 60),

                        // ── Cover & Avatar ──
                        Stack(
                          clipBehavior: Clip.none, alignment: Alignment.topCenter,
                          children: [
                            GestureDetector(
                              onTap: () => widget.isOwnProfile ? _pickAndUploadImageDirectly(false) : null,
                              child: Container(
                                height: 180, width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover),
                                  color: const Color(0xFFF8F9FA),
                                ),
                              ),
                            ),
                            Positioned(top: 150, left: 0, right: 0,
                              child: Container(height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))))),
                            Positioned(
                              top: 100,
                              child: GestureDetector(
                                onTap: () => widget.isOwnProfile ? _pickAndUploadImageDirectly(true) : null,
                                child: Stack(children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: CircleAvatar(radius: 46, backgroundImage: NetworkImage(profileImg)),
                                  ),
                                  if (widget.isOwnProfile)
                                    Positioned(bottom: 4, right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: const Color(0xFFFF6D00), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                      )),
                                ]),
                              ),
                            ),
                            if (widget.isOwnProfile)
                              Positioned(
                                bottom: 20, right: 16,
                                child: GestureDetector(
                                  onTap: () => _pickAndUploadImageDirectly(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            if (_isUploadingImage)
                              Positioned(top: 80,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                                  child: const CircularProgressIndicator(color: Color(0xFFFF6D00)),
                                )),
                          ],
                        ),
                        const SizedBox(height: 50),

                        // ── Name & Badge ──
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(fullName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFFFF6D00), size: 22),
                        ]),
                        Center(child: Text(usernameText, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B6B6B)))),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(bioText, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A), height: 1.5)),
                        ),
                        const SizedBox(height: 16),

                        // ── Stats ──
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _buildStatItem('$followerCount', 'followers', () {}),
                          Text('  •  ', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                          _buildStatItem('$followingCount', 'following', () {}),
                          Text('  •  ', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                          _buildStatItem('$postsCount', 'posts', () => _tabController.animateTo(0)),
                        ]),
                        const SizedBox(height: 24),

                        // ── Action Buttons ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: widget.isOwnProfile
                                ? [
                                    // নিজের profile এ Add Friend নেই (top nav bar এ আছে)
                                    Expanded(child: _buildPrimaryButton(Icons.edit_rounded, 'Edit Profile', () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                                          .then((_) => _fetchUserData(byMobile: true, mobile: _currentUserMobile));
                                    })),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildSecondaryButton(Icons.add_box_rounded, 'Add to story', () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddToStoryScreen()));
                                    })),
                                    const SizedBox(width: 8),
                                    _buildIconOnlyButton(Icons.more_horiz_rounded, _showProfileMenu),
                                  ]
                                : _buildOtherUserButtons(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDetailedInfoList(),
                        const SizedBox(height: 16),

                        // ── Friends Section (own profile তে friend requests নেই, শুধু friends list)
                        _buildFriendsSection(),
                        const SizedBox(height: 24),

                        // ── Highlights ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Highlights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                        ),
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
                        labelColor: const Color(0xFFFF6D00), unselectedLabelColor: const Color(0xFFA0A0A0),
                        indicatorColor: const Color(0xFFFF6D00), indicatorWeight: 3,
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
                    _buildFeedsTab(fullName, profileImg),
                    _buildPhotosTab(),
                    _buildReelsTab(),
                  ],
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
            top: _isTopNavVisible ? 0 : -(MediaQuery.of(context).padding.top + 80),
            left: 0, right: 0,
            child: TopNavBar(onMenuTap: _toggleLeftSidebar),
          ),
          if (_isLeftSidebarOpen)
            GestureDetector(onTap: _toggleLeftSidebar, child: Container(color: Colors.black.withValues(alpha: 0.5), width: size.width, height: size.height)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
            left: _isLeftSidebarOpen ? 0 : -320, top: 0, bottom: 0,
            child: LeftSidebar(onClose: _toggleLeftSidebar),
          ),
          Positioned(bottom: 20, left: 16, right: 16, child: BottomNavBar(onProfileTap: () {})),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // OTHER USER ACTION BUTTONS
  // ✅ Add Friend | Follow | Message(icon) | More
  // ══════════════════════════════════════════════════════════
  List<Widget> _buildOtherUserButtons() {
    Widget friendBtn;
    switch (_friendshipStatus) {
      case 'friends':
        friendBtn = Expanded(
          child: _buildPrimaryButton(Icons.people_rounded, 'Friends', () {
            showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Unfriend?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () { Navigator.pop(context); _unfriend(); },
                  child: const Text("Unfriend", style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
          }),
        );
        break;
      case 'request_sent':
        friendBtn = Expanded(
          child: _buildSecondaryButton(Icons.hourglass_top_rounded, 'Request Sent', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request already sent")));
          }),
        );
        break;
      case 'request_received':
        friendBtn = Expanded(
          child: _buildPrimaryButton(Icons.person_add_rounded, 'Accept', () => _acceptFriendRequest(widget.profileUserId ?? '')),
        );
        break;
      default:
        friendBtn = Expanded(
          child: _buildPrimaryButton(Icons.person_add_rounded, 'Add Friend', _sendFriendRequest),
        );
    }

    // ✅ Follow Button — proper full button (আইকন-only নয়)
    final followBtn = Expanded(
      child: _isFollowing
          ? _buildSecondaryButton(
              Icons.person_remove_outlined,
              'Following',
              _toggleFollow, // confirmation popup আছে _toggleFollow এ
            )
          : _buildSecondaryButton(
              Icons.person_add_alt_1_rounded,
              'Follow',
              _toggleFollow,
            ),
    );

    return [
      friendBtn,
      const SizedBox(width: 8),
      followBtn,
      const SizedBox(width: 8),
      _buildIconOnlyButton(Icons.chat_bubble_outline_rounded, () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message feature coming soon")));
      }),
      const SizedBox(width: 8),
      _buildIconOnlyButton(Icons.more_horiz_rounded, _showOtherProfileMenu),
    ];
  }

  // ══════════════════════════════════════════════════════════
  // FRIENDS SECTION — own profile তে শুধু Friends list দেখাবে
  // Friend Requests section সরিয়ে top nav bar এ নেওয়া হয়েছে
  // ══════════════════════════════════════════════════════════
  Widget _buildFriendsSection() {
    if (_loadingFriends) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator(color: Color(0xFFFF6D00)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Friends', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            if (_friends.isNotEmpty)
              GestureDetector(
                onTap: () {},
                child: Text('See all', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFFF6D00), fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 12),
          if (_friends.isEmpty)
            Text('No friends yet', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13))
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _friends.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final f = _friends[i];
                  final fPic = f['profilePic']?.toString().isNotEmpty == true
                      ? f['profilePic']
                      : (f['gender']?.toString() == 'female'
                          ? 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png'
                          : 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_male.png');
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: f['_id']?.toString()))),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                        child: CircleAvatar(radius: 34, backgroundImage: NetworkImage(fPic)),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${f['firstName'] ?? ''} ${f['lastName'] ?? ''}',
                          textAlign: TextAlign.center, maxLines: 2,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STORY HIGHLIGHTS
  // ══════════════════════════════════════════════════════════
  Widget _buildStoryHighlights() {
    final highlights = (_userData['highlights'] as List?) ?? [];
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (widget.isOwnProfile)
            GestureDetector(
              onTap: () => _showAddHighlightDialog(),
              child: Column(children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF6D00), width: 2),
                    color: Colors.orange.shade50,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFFF6D00), size: 28),
                ),
                const SizedBox(height: 6),
                Text('New', style: GoogleFonts.poppins(fontSize: 11)),
              ]),
            ),
          ...highlights.map<Widget>((h) {
            final cover = h['coverImg']?.toString().isNotEmpty == true ? h['coverImg'] : null;
            return GestureDetector(
              onLongPress: widget.isOwnProfile ? () => _showDeleteHighlightDialog(h['_id']) : null,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6D00), width: 2),
                      image: cover != null ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover) : null,
                      color: Colors.grey.shade200,
                    ),
                    child: cover == null ? const Icon(Icons.star_outline, color: Colors.grey) : null,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(width: 60, child: Text(h['title'] ?? '', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11))),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddHighlightDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Add Highlight"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Title...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00)),
          onPressed: () { if (ctrl.text.isNotEmpty) { _addHighlight(ctrl.text, ''); Navigator.pop(context); } },
          child: const Text("Add", style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showDeleteHighlightDialog(String highlightId) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Delete Highlight?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { Navigator.pop(context); _deleteHighlight(highlightId); },
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  // ══════════════════════════════════════════════════════════
  // FEEDS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildFeedsTab(String fullName, String profileImg) {
    return CustomScrollView(slivers: [
      if (widget.isOwnProfile)
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(12), child: CreatePostBox(authorName: fullName, authorProfilePic: profileImg, onPostCreated: () => _fetchFeedPosts(_currentUserId)))),
      if (_loadingPosts)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))))
      else if (_feedPosts.isEmpty)
        SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No posts yet', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)))))
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final p = _feedPosts[i];
              final List<dynamic> likes    = (p['likes']    as List?) ?? [];
              final List<dynamic> comments = (p['comments'] as List?) ?? [];
              return PostCard(
                postId:           p['_id']?.toString() ?? '',
                currentUserId:    _currentUserId,
                authorId:         p['authorId']?.toString() ?? '',
                authorName:       '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim(),
                userGender:       p['gender']?.toString() ?? 'male',
                authorProfilePic: p['profilePic']?.toString(),
                timeAgo:          _timeAgo(p['createdAt']),
                textContent:      p['textContent']?.toString() ?? '',
                postImageUrl:     p['postImageUrl']?.toString() ?? '',
                likes:            likes,
                comments:         comments,
                views:            (p['views'] as num?)?.toInt() ?? 0,
              );
            },
            childCount: _feedPosts.length,
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // PHOTOS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildPhotosTab() {
    final albums = (_userData['albums'] as List?) ?? [];
    return ListView(children: [
      if (widget.isOwnProfile)
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: _showCreateAlbumDialog,
            icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFFF6D00)),
            label: Text('Create Album', style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A))),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF6D00)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      if (albums.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Albums', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = albums[i];
              final cover = a['coverImg']?.toString().isNotEmpty == true ? a['coverImg'] : null;
              return Column(children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    image: cover != null ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover) : null,
                  ),
                  child: cover == null ? const Icon(Icons.photo_library_outlined, color: Colors.grey) : null,
                ),
                const SizedBox(height: 4),
                SizedBox(width: 70, child: Text(a['title']?.toString() ?? '', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10))),
              ]);
            },
          ),
        ),
      ],
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('All Photos', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold))),
      const SizedBox(height: 10),
      if (_loadingPhotos)
        const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
      else if (_photos.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No photos yet', style: GoogleFonts.poppins(color: Colors.grey))))
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemBuilder: (_, i) {
            final p = _photos[i];
            return GestureDetector(
              onTap: () => _openFullscreenPhoto(p['imageUrl']?.toString() ?? ''),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(p['imageUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
              ),
            );
          },
        ),
      const SizedBox(height: 80),
    ]);
  }

  void _openFullscreenPhoto(String url) {
    if (url.isEmpty) return;
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
          Positioned(top: 50, left: 16, child: GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white, size: 28))),
        ]),
      ),
    ));
  }

  void _showCreateAlbumDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Create Album"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Album name...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00)),
          onPressed: () { if (ctrl.text.isNotEmpty) { _createAlbum(ctrl.text); Navigator.pop(context); } },
          child: const Text("Create", style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  // ══════════════════════════════════════════════════════════
  // REELS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildReelsTab() {
    if (_loadingReels) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
    if (_reels.isEmpty) return Center(child: Text('No reels yet', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)));

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: _reels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 9 / 16),
      itemBuilder: (_, i) {
        final r = _reels[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(r['postImageUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[800])),
            const Positioned(bottom: 8, left: 8, child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 32)),
          ]),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════
  Widget _buildStatItem(String count, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: RichText(text: TextSpan(style: GoogleFonts.poppins(fontSize: 14), children: [TextSpan(text: count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), TextSpan(text: ' $label', style: const TextStyle(color: Color(0xFF6B6B6B)))])));
  }

  Widget _buildDetailedInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_userData['workTitle'] != null && _userData['workTitle'].toString().isNotEmpty) _buildInfoRow(Icons.work_outline_rounded, 'Works as ${_userData['workTitle']} at ', _userData['workPlace'] ?? ''),
        if (_userData['currentCity'] != null && _userData['currentCity'].toString().isNotEmpty) _buildInfoRow(Icons.home_outlined, 'Lives in ', _userData['currentCity']),
        if (_userData['schoolUniversity'] != null && _userData['schoolUniversity'].toString().isNotEmpty) _buildInfoRow(Icons.school_outlined, 'Studied at ', _userData['schoolUniversity']),
        if (_userData['relationshipStatus'] != null && _userData['relationshipStatus'] != 'Single') _buildInfoRow(Icons.favorite_border_rounded, 'Status: ', _userData['relationshipStatus']),
      ]),
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

  Widget _buildIconOnlyButton(IconData icon, VoidCallback onTap, {String? tooltip, Color? color}) {
    return Tooltip(
      message: tooltip ?? '',
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 40), side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Icon(icon, size: 20, color: color ?? const Color(0xFF1A1A1A)),
      ),
    );
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return 'Just now'; }
  }
}

// ══════════════════════════════════════════════════════════
// STICKY TAB BAR DELEGATE
// ══════════════════════════════════════════════════════════
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height + 1.0;
  @override double get maxExtent => tabBar.preferredSize.height + 1.0;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: Column(mainAxisSize: MainAxisSize.min, children: [tabBar, Container(height: 1, color: Colors.grey.shade200)]));
  @override bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}
