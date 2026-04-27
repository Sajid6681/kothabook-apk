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
  String _currentUserId = ""; 
  bool _isLoadingUserData = true;
  
  List<dynamic> _allPosts = []; 
  bool _isLoadingPosts = true;

  final String _baseUrl = "https://app.kothabook.com/api";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchPosts(); 
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mobileNumber = prefs.getString('mobileNumber'); 

    if (mobileNumber != null) {
      final String apiUrl = 'https://app.kothabook.com/api/user/$mobileNumber';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _fullName = "${data['firstName']} ${data['lastName']}";
              _currentUserId = data['_id']?.toString() ?? mobileNumber; 
              _isLoadingUserData = false;
            });
          }
        } else {
           if (mounted) setState(() => _isLoadingUserData = false);
        }
      } catch (error) {
        debugPrint("Error fetching user data: $error");
        if (mounted) setState(() => _isLoadingUserData = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/posts'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allPosts = jsonDecode(response.body);
            _isLoadingPosts = false;
          });
        }
      } else {
         if (mounted) setState(() => _isLoadingPosts = false);
      }
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  void _toggleLeftSidebar() {
    setState(() {
      _isLeftSidebarOpen = !_isLeftSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopNavBar(onMenuTap: _toggleLeftSidebar),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchUserData();
                      await _fetchPosts();
                    },
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (_showGreeting)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: _showGreeting ? 1.0 : 0.0,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.05),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text("👋", style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLoadingUserData ? "Loading..." : "Hello, ${_fullName.split(' ')[0]}!", 
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _showGreeting = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const StorySection(),
                          const SizedBox(height: 8),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: CreatePostBox(),
                          ),
                          const SizedBox(height: 8),

                          _isLoadingPosts 
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
                              )
                            : _allPosts.isEmpty 
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text("No posts found", style: GoogleFonts.poppins(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _allPosts.length,
                                  itemBuilder: (context, index) {
                                    var post = _allPosts[index];

                                    return PostCard(
                                      postId: post['_id']?.toString() ?? "",
                                      currentUserId: _currentUserId,
                                      authorId: post['authorId']?.toString() ?? "",
                                      authorName: post['authorName']?.toString() ?? "Unknown",
                                      userGender: post['authorGender']?.toString() ?? "male", 
                                      authorProfilePic: post['authorProfilePic']?.toString(),
                                      timeAgo: "Just now", 
                                      textContent: post['textContent']?.toString() ?? "",
                                      postImageUrl: post['postImageUrl']?.toString() ?? "",
                                      likes: post['likes'] is List ? post['likes'] : [],
                                      comments: post['comments'] is List ? post['comments'] : [],
                                      views: post['views'] is int ? post['views'] : 0,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isLeftSidebarOpen) 
              GestureDetector(
                onTap: _toggleLeftSidebar,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  width: size.width,
                  height: size.height,
                ),
              ),
            
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic, top: 0, bottom: 0, left: _isLeftSidebarOpen ? 0 : -320,
              child: LeftSidebar(onClose: _toggleLeftSidebar),
            ),

            Positioned(bottom: 20, left: 20, right: 20, child: BottomNavBar(onProfileTap: () {})),
          ],
        ),
      ),
    );
  }
}
