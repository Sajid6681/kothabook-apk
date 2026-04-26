import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'widgets/top_nav_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/left_sidebar.dart';
import 'widgets/story_section.dart';
import 'widgets/post_card.dart';
import 'widgets/custom_dialog.dart'; 
import 'profile_screen.dart';
import 'widgets/create_post_box.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLeftSidebarOpen = false;
  bool _showGreeting = true;

  String _fullName = "Loading...";
  String _profilePicUrl = ""; 
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
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
              // 🚀 Full Name শো করানোর লজিক
              _fullName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
              if (_fullName.isEmpty) _fullName = "User";
              
              _profilePicUrl = userData['profilePic'] ?? ""; 
              _isLoadingUserData = false;
            });
          }
        }
      } catch (error) {
        if (mounted) setState(() => _isLoadingUserData = false);
      }
    }
  }

  void _toggleLeftSidebar() {
    setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen);
  }

  void _hideGreeting() {
    CustomDialog.show(
      context: context,
      title: 'Hide Greeting?',
      message: 'Do you want to dismiss this greeting message?',
      confirmText: 'Hide',
      isDestructive: false, 
      onConfirm: () => setState(() => _showGreeting = false),
    );
  }

  void _goToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen(isOwnProfile: true)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Stack(
        children: [
          Column(
            children: [
              TopNavBar(onMenuTap: _toggleLeftSidebar),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StorySection(),
                      
                      // 🚀 Create Post Box (Profile screen এর মতো)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: CreatePostBox(), 
                      ),
                      const SizedBox(height: 12),

                      if (_showGreeting)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.amber, Color(0xFFFF6D00)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      const Icon(Icons.nights_stay_rounded, color: Colors.indigoAccent, size: 36),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Good Evening, $_fullName', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                                            const SizedBox(height: 2),
                                            Text('We hope you are enjoying your evening.', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B6B6B))),
                                          ],
                                        ),
                                      ),
                                      IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFFA0A0A0), size: 20), onPressed: _hideGreeting), 
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Updates', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                              child: Row(
                                children: [
                                  const Icon(Icons.menu_rounded, size: 14),
                                  const SizedBox(width: 4),
                                  Text('All', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Posts
                      const PostWidget(
                        isOwnPost: false, authorName: 'Alex Johnson', avatarImg: 'https://i.pravatar.cc/150?img=33', time: '2 hours ago',
                        content: 'Just experienced the most beautiful sunset today. KothaBook is awesome! ✨ #Nature #Vibes',
                        postImg: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
                      ),
                      const SizedBox(height: 12),
                      PostWidget(
                        isOwnPost: true, 
                        authorName: _fullName, // 🚀 Full Name Here
                        avatarImg: _profilePicUrl.isNotEmpty ? _profilePicUrl : 'https://i.pravatar.cc/150?img=11', time: 'Just now',
                        content: 'Working on some huge updates for KothaBook! Get ready guys! 🚀🔥', postImg: null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isLeftSidebarOpen) 
            GestureDetector(onTap: _toggleLeftSidebar, child: Container(color: Colors.black.withOpacity(0.5), width: size.width, height: size.height)),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic, top: 0, bottom: 0, left: _isLeftSidebarOpen ? 0 : -320,
            child: LeftSidebar(onClose: _toggleLeftSidebar),
          ),

          Positioned(bottom: 20, left: 16, right: 16, child: BottomNavBar(onProfileTap: _goToProfile)),
        ],
      ),
    );
  }
}