import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../profile_screen.dart';
import 'comment_section.dart';
import 'share_post_screen.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String currentUserId; 
  final String authorId;
  final String authorName;
  final String userGender; 
  final String? authorProfilePic;
  final String timeAgo;
  final String textContent; 
  final String postImageUrl;
  final List<dynamic> likes; 
  final List<dynamic> comments; 
  final int views;

  const PostCard({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.authorId,
    required this.authorName,
    this.userGender = "male",
    this.authorProfilePic,
    this.timeAgo = "Just now",
    this.textContent = "",
    this.postImageUrl = "",
    this.likes = const [],
    this.comments = const [],
    this.views = 0,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final Color primaryColor = const Color(0xFFFF6D00);
  final String baseUrl = "http://YOUR_SERVER_IP:5000/api"; 

  bool isSaved = false;
  bool isCaptionExpanded = false;
  
  Map<String, dynamic>? postReaction; 
  Map<String, dynamic>? commentReaction;
  
  int localLikeCount = 0;
  int localCommentCount = 0;

  final List<Map<String, dynamic>> reactionsList = [
    {'label': 'Like', 'asset': 'assets/reactions/like.png', 'color': const Color(0xFF0056D2)},
    {'label': 'Love', 'asset': 'assets/reactions/love.png', 'color': const Color(0xFFF33E58)},
    {'label': 'Haha', 'asset': 'assets/reactions/haha.png', 'color': const Color(0xFFF7B125)},
    {'label': 'Wow', 'asset': 'assets/reactions/wow.png', 'color': const Color(0xFFF7B125)},
    {'label': 'Sad', 'asset': 'assets/reactions/sad.png', 'color': const Color(0xFFF7B125)},
    {'label': 'Angry', 'asset': 'assets/reactions/angry.png', 'color': const Color(0xFFE9710F)},
  ];

  @override
  void initState() {
    super.initState();
    localLikeCount = widget.likes.length;
    localCommentCount = widget.comments.length;
    if (widget.likes.contains(widget.currentUserId)) {
      postReaction = reactionsList[0]; 
    }
  }

  String _getAvatarUrl(String? url, String gender) {
    if (url != null && url.isNotEmpty) return url;
    if (gender.toLowerCase() == 'female') {
      return 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png';
    } else if (gender.toLowerCase() == 'male') {
      return 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_male.png';
    }
    return 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_other.png';
  }

  Future<void> _handlePostReaction(Map<String, dynamic>? reaction) async {
    setState(() {
      postReaction = reaction;
      if (reaction != null && !widget.likes.contains(widget.currentUserId)) {
        localLikeCount++;
      } else if (reaction == null) {
        localLikeCount--;
      }
    });

    try {
      await http.post(
        Uri.parse('$baseUrl/react-post'),
        body: jsonEncode({'postId': widget.postId, 'userId': widget.currentUserId, 'reactionType': reaction?['label'] ?? 'none'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint("React Error: $e");
    }
  }

  Future<void> _sendComment(String commentText) async {
    if (commentText.trim().isEmpty) return;
    setState(() => localCommentCount++);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment posted!")));
    
    try {
      await http.post(
        Uri.parse('$baseUrl/add-comment'),
        body: jsonEncode({'postId': widget.postId, 'userId': widget.currentUserId, 'commentText': commentText}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint("Comment Error: $e");
    }
  }

  Future<void> _executeDeletePost() async {
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted!")));
    try {
      await http.delete(Uri.parse('$baseUrl/delete-post/${widget.postId}'));
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  Future<void> _executeSavePost() async {
    setState(() => isSaved = !isSaved);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isSaved ? "Post Saved!" : "Post Unsaved")));
    try {
      await http.post(Uri.parse('$baseUrl/save-post'), body: jsonEncode({'postId': widget.postId, 'userId': widget.currentUserId}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  Future<void> _submitReport(String subject, String details) async {
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Submitted Successfully!")));
    try {
      await http.post(Uri.parse('$baseUrl/report'), body: jsonEncode({'postId': widget.postId, 'userId': widget.currentUserId, 'subject': subject, 'details': details}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      debugPrint("Report Error: $e");
    }
  }

  void _goToProfile(String id) {
    bool isOwn = id == widget.currentUserId;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: isOwn, profileUserId: id)));
  }

  void _goToComments() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommentSection()));
  }

  void _goToShare() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SharePostScreen()));
  }

  void _showDeleteConfirm() {
    Navigator.pop(context); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Post?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to proceed? This action cannot be undone.", style: TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _executeDeletePost,
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportModal(String type) {
    Navigator.pop(context); 
    TextEditingController subjectCtrl = TextEditingController();
    TextEditingController detailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Report $type", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("SUBJECT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              TextField(
                controller: subjectCtrl,
                decoration: InputDecoration(hintText: "E.g., Spam, Harassment", filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor))),
              ),
              const SizedBox(height: 15),
              const Text("DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              TextField(
                controller: detailsCtrl,
                maxLines: 4,
                decoration: InputDecoration(hintText: "Explain the issue...", filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextButton(style: TextButton.styleFrom(backgroundColor: Colors.grey[100], padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), onPressed: () => _submitReport(subjectCtrl.text, detailsCtrl.text), child: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuBottomSheet() {
    bool isOwn = widget.authorId == widget.currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.only(top: 10, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            if (isOwn) ...[
              _buildMenuItem(PhosphorIconsRegular.pushPin, "Pin Post", "Pin to top.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post Pinned!"))); }),
              _buildMenuItem(PhosphorIconsRegular.pencilSimple, "Edit Post", "Update caption.", Colors.black, onTap: () { Navigator.pop(context); }),
              _buildMenuItem(PhosphorIconsRegular.chatCircleSlash, "Turn off Commenting", "Disable comments.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comments Disabled"))); }),
              _buildMenuItem(PhosphorIconsRegular.link, "Copy Link", "Copy to clipboard.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Copied!"))); }),
              _buildMenuItem(PhosphorIconsRegular.trash, "Delete Post", "Remove permanently.", Colors.red, isDanger: true, onTap: _showDeleteConfirm),
            ] else ...[
              _buildMenuItem(PhosphorIconsRegular.eyeSlash, "Hide Post", "See fewer posts.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post Hidden from timeline"))); }),
              _buildMenuItem(PhosphorIconsRegular.userMinus, "Unfollow ${widget.authorName.split(' ')[0]}", "Stop following updates.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Unfollowed"))); }),
              _buildMenuItem(PhosphorIconsRegular.link, "Copy Link", "Copy to clipboard.", Colors.black, onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Copied!"))); }),
              _buildMenuItem(PhosphorIconsRegular.warningCircle, "Report Post", "Flag for review.", Colors.black, onTap: () => _showReportModal("Post")),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String desc, Color titleColor, {bool isDanger = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(width: 45, height: 45, decoration: BoxDecoration(color: isDanger ? Colors.red[50] : Colors.grey[50], shape: BoxShape.circle), child: Icon(icon, color: isDanger ? Colors.red : primaryColor, size: 22)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)), Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey))]))
          ],
        ),
      ),
    );
  }

  void _showReactorsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text("People who reacted", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: [
                  _buildReactorItem("Sajid Hasan", 'assets/reactions/like.png'),
                  _buildReactorItem("Sarah Jenkins", 'assets/reactions/love.png'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReactorItem(String name, String reactionAsset) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100"), radius: 18),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          Image.asset(reactionAsset, width: 20, height: 20),
        ],
      ),
    );
  }

  void _openFullscreen() {
    if (widget.postImageUrl.isEmpty) return; 
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (BuildContext context, _, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: InteractiveViewer(child: Image.network(widget.postImageUrl, width: double.infinity, fit: BoxFit.contain))),
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent])),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _fsIconButton(PhosphorIconsRegular.x, () => Navigator.pop(context)),
                      Row(
                        children: [
                          _fsIconButton(isSaved ? PhosphorIconsFill.bookmarkSimple : PhosphorIconsRegular.bookmarkSimple, _executeSavePost, color: isSaved ? primaryColor : Colors.white),
                          const SizedBox(width: 15),
                          _fsIconButton(PhosphorIconsBold.dotsThree, _showMenuBottomSheet),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 40, bottom: 30, left: 20, right: 20),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () { Navigator.pop(context); _goToProfile(widget.authorId); },
                        child: Row(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(_getAvatarUrl(widget.authorProfilePic, widget.userGender)), radius: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Text(widget.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(width: 5), const Icon(Icons.check_circle, color: Colors.blue, size: 14)]),
                                Text("${widget.timeAgo} • Public", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.textContent, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DragReactionButton(
                            reactionsList: reactionsList,
                            currentReaction: postReaction,
                            defaultIcon: PhosphorIconsRegular.thumbsUp,
                            defaultText: "$localLikeCount",
                            isDarkMode: true,
                            onReact: (reaction) { _handlePostReaction(reaction); (context as Element).markNeedsBuild(); },
                          ),
                          GestureDetector(
                            onTap: () { Navigator.pop(context); _goToComments(); },
                            child: Row(children: [const Icon(PhosphorIconsRegular.chatCircle, color: Colors.white, size: 26), const SizedBox(width: 5), Text("$localCommentCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                          ),
                          GestureDetector(
                            onTap: () { Navigator.pop(context); _goToShare(); },
                            child: const Row(children: [Icon(PhosphorIconsRegular.shareNetwork, color: Colors.white, size: 26), SizedBox(width: 5), Text("Share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    ));
  }

  Widget _fsIconButton(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(padding: const EdgeInsets.all(10), color: Colors.white.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController commentCtrl = TextEditingController();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _goToProfile(widget.authorId),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(_getAvatarUrl(widget.authorProfilePic, widget.userGender)), radius: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Text(widget.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)), const SizedBox(width: 4), const Icon(Icons.check_circle, color: Colors.blue, size: 14)]),
                          Row(children: [Text(widget.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)), const Text(" • ", style: TextStyle(color: Colors.grey, fontSize: 11)), const Icon(PhosphorIconsRegular.globe, color: Colors.grey, size: 12)])
                        ],
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: Icon(isSaved ? PhosphorIconsFill.bookmarkSimple : PhosphorIconsRegular.bookmarkSimple, color: isSaved ? primaryColor : Colors.grey, size: 24), onPressed: _executeSavePost),
                    IconButton(icon: const Icon(PhosphorIconsBold.dotsThree, color: Colors.grey, size: 28), onPressed: _showMenuBottomSheet)
                  ],
                )
              ],
            ),
          ),

          // Caption
          if (widget.textContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => setState(() => isCaptionExpanded = !isCaptionExpanded),
                child: Text(
                  widget.textContent,
                  maxLines: isCaptionExpanded ? null : 2,
                  overflow: isCaptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black87), 
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Image — নিজের সাইজে দেখাবে, সর্বোচ্চ 3:4 ratio
          if (widget.postImageUrl.isNotEmpty)
            GestureDetector(
              onTap: _openFullscreen,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      // 3:4 ratio মানে width/height = 3/4, তাই maxHeight = width * 4/3
                      maxHeight: constraints.maxWidth * 4 / 3,
                    ),
                    child: Image.network(
                      widget.postImageUrl,
                      width: constraints.maxWidth,
                      fit: BoxFit.contain, // zoom হবে না, নিজের সাইজে থাকবে
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 2)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  );
                },
              ),
            ),

          // Top Reactions & Views
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showReactorsSheet,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45, 
                        height: 20,
                        child: Stack(
                          children: [
                            Positioned(left: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Image.asset('assets/reactions/like.png', width: 16))),
                            Positioned(left: 12, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Image.asset('assets/reactions/love.png', width: 16))),
                            Positioned(left: 24, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Image.asset('assets/reactions/haha.png', width: 16))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text("$localLikeCount", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.eye, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text("${widget.views} Views", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: DragReactionButton(
                    reactionsList: reactionsList,
                    currentReaction: postReaction,
                    defaultIcon: PhosphorIconsRegular.thumbsUp,
                    defaultText: "$localLikeCount",
                    onReact: _handlePostReaction, 
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _goToComments,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.chatCircle, color: Colors.grey, size: 24),
                          const SizedBox(width: 6),
                          Text("$localCommentCount", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _goToShare,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.shareNetwork, color: Colors.grey, size: 24),
                          SizedBox(width: 6),
                          Text("Share", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Single Top Comment
          if (widget.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _goToProfile(widget.comments[0]['userId']?.toString() ?? "User"),
                    child: const CircleAvatar(backgroundImage: NetworkImage('https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png'), radius: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _goToProfile(widget.comments[0]['userId']?.toString() ?? "User"),
                                    child: Text(widget.comments[0]['userName']?.toString() ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(widget.comments[0]['commentText']?.toString() ?? "", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: -5, right: -5,
                              child: GestureDetector(
                                onTap: _showReactorsSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                                  child: Row(
                                    children: [Image.asset('assets/reactions/love.png', width: 12), const SizedBox(width: 2), const Text("2", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text("1h", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 15),
                            DragReactionButton(
                              reactionsList: reactionsList,
                              currentReaction: commentReaction,
                              defaultText: "Like",
                              isTextOnly: true,
                              onReact: (reaction) => setState(() => commentReaction = reaction),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(onTap: () {}, child: const Text("Reply", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                            const SizedBox(width: 15),
                            GestureDetector(onTap: () => _showReportModal("Comment"), child: const Text("Report", style: TextStyle(fontSize: 11, color: Colors.grey))),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

          // Comment Input Box
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15, top: 5),
            child: Row(
              children: [
                Container(width: 35, height: 35, decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle), child: Icon(PhosphorIconsRegular.plus, color: primaryColor, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15), height: 40,
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryColor)),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: commentCtrl, decoration: const InputDecoration(hintText: "Write a comment...", hintStyle: TextStyle(fontSize: 13), border: InputBorder.none, isDense: true))),
                        Icon(PhosphorIconsRegular.sticker, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _sendComment(commentCtrl.text);
                    commentCtrl.clear();
                  },
                  child: Icon(PhosphorIconsFill.paperPlaneRight, color: primaryColor, size: 24)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// FACEBOOK-STYLE DRAG-TO-REACT LOGIC WIDGET 
// ============================================================================
class DragReactionButton extends StatefulWidget {
  final List<Map<String, dynamic>> reactionsList;
  final Map<String, dynamic>? currentReaction;
  final IconData? defaultIcon;
  final String defaultText;
  final Function(Map<String, dynamic>?) onReact;
  final bool isTextOnly; 
  final bool isDarkMode; 

  const DragReactionButton({
    super.key,
    required this.reactionsList,
    required this.currentReaction,
    this.defaultIcon,
    required this.defaultText,
    required this.onReact,
    this.isTextOnly = false,
    this.isDarkMode = false,
  });

  @override
  State<DragReactionButton> createState() => _DragReactionButtonState();
}

class _DragReactionButtonState extends State<DragReactionButton> {
  OverlayEntry? _overlayEntry;
  bool _isDragging = false;
  int _hoveredIndex = -1;

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              left: offset.dx - 10, top: offset.dy - 65,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 50, padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1, offset: Offset(0, 4))]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.reactionsList.length, (index) {
                      bool isHovered = _hoveredIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150), margin: const EdgeInsets.symmetric(horizontal: 6),
                        transform: Matrix4.identity()
                          ..translate(0.0, isHovered ? -10.0 : 0.0, 0.0)
                          ..scale(isHovered ? 1.5 : 1.0, isHovered ? 1.5 : 1.0, 1.0),
                        child: Image.asset(widget.reactionsList[index]['asset'], width: 30, height: 30),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove(); _overlayEntry = null; setState(() => _hoveredIndex = -1);
  }

  void _updateDragPosition(Offset globalPosition, Offset buttonOffset) {
    double dx = globalPosition.dx - (buttonOffset.dx - 10);
    double dy = globalPosition.dy - (buttonOffset.dy - 65);
    if (dy >= -30 && dy <= 60 && dx >= 0 && dx <= (widget.reactionsList.length * 45.0)) {
      int newIndex = (dx / 42).floor(); 
      if (newIndex >= 0 && newIndex < widget.reactionsList.length) {
        if (_hoveredIndex != newIndex) { setState(() => _hoveredIndex = newIndex); _overlayEntry?.markNeedsBuild(); }
      }
    } else {
      if (_hoveredIndex != -1) { setState(() => _hoveredIndex = -1); _overlayEntry?.markNeedsBuild(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;
    if (widget.currentReaction != null) {
      buttonContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!widget.isTextOnly) ...[Image.asset(widget.currentReaction!['asset'], width: 24, height: 24), const SizedBox(width: 6)],
          Text(widget.isTextOnly ? widget.currentReaction!['label'] : widget.defaultText, style: TextStyle(color: widget.currentReaction!['color'], fontWeight: FontWeight.bold, fontSize: widget.isTextOnly ? 11 : 13))
        ],
      );
    } else {
      Color defaultColor = widget.isDarkMode ? Colors.white : Colors.grey;
      buttonContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!widget.isTextOnly && widget.defaultIcon != null) ...[Icon(widget.defaultIcon, color: defaultColor, size: 24), const SizedBox(width: 6)],
          Text(widget.defaultText, style: TextStyle(color: defaultColor, fontWeight: FontWeight.bold, fontSize: widget.isTextOnly ? 11 : 13))
        ],
      );
    }

    return GestureDetector(
      onLongPressStart: (details) { _isDragging = true; _showOverlay(context); },
      onLongPressMoveUpdate: (details) {
        if (_isDragging) { RenderBox renderBox = context.findRenderObject() as RenderBox; Offset offset = renderBox.localToGlobal(Offset.zero); _updateDragPosition(details.globalPosition, offset); }
      },
      onLongPressEnd: (details) {
        if (_isDragging) { if (_hoveredIndex != -1) widget.onReact(widget.reactionsList[_hoveredIndex]); _removeOverlay(); _isDragging = false; }
      },
      onTap: () { if (widget.currentReaction != null) widget.onReact(null); else widget.onReact(widget.reactionsList[0]); },
      child: Container(padding: widget.isTextOnly ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 10), color: Colors.transparent, child: buttonContent),
    );
  }
}