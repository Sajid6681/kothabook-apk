import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comment_section.dart';
import 'custom_dialog.dart'; 
import '../profile_screen.dart'; // 🚀 প্রোফাইল ইম্পোর্ট করা হলো

class PostWidget extends StatefulWidget {
  final bool isOwnPost;
  final String authorName;
  final String avatarImg;
  final String time;
  final String content;
  final String? postImg;

  const PostWidget({super.key, required this.isOwnPost, required this.authorName, required this.avatarImg, required this.time, required this.content, this.postImg});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  String? _selectedReaction; 
  
  void _showReactionMenu(BuildContext context, Offset position) {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "Reaction", barrierColor: Colors.transparent, transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: 20, bottom: MediaQuery.of(context).size.height - position.dy + 20,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5))]),
                    // 🚀 Image Asset Reactions
                    child: Row(children: [
                      _reactionEmoji(context, 'like', 'Like'), 
                      _reactionEmoji(context, 'love', 'Love'), 
                      _reactionEmoji(context, 'haha', 'Haha'), 
                      _reactionEmoji(context, 'wow', 'Wow'), 
                      _reactionEmoji(context, 'sad', 'Sad'), 
                      _reactionEmoji(context, 'angry', 'Angry')
                    ]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🚀 Changed from Text Emoji to Image Asset
  Widget _reactionEmoji(BuildContext context, String assetName, String label) {
    return GestureDetector(
      onTap: () { setState(() { _selectedReaction = label; }); Navigator.of(context).pop(); }, 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6), 
        child: Image.asset('assets/reactions/$assetName.png', width: 32, height: 32, errorBuilder: (c, e, s) => const Icon(Icons.thumb_up, color: Color(0xFFFF6D00))) // Fallback icon
      )
    );
  }

  void _handleLikeClick() { setState(() { _selectedReaction = _selectedReaction != null ? null : 'Like'; }); }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.isOwnPost 
            ? [ 
                _buildMenuOption(Icons.bookmark_border_rounded, 'Save Post', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.push_pin_outlined, 'Pin Post', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.edit_outlined, 'Edit Post', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.link_rounded, 'Copy Link', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.visibility_off_outlined, 'Hide from Timeline', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.comments_disabled_outlined, 'Turn off Comment', () => Navigator.pop(context)), 
                const Divider(), 
                _buildMenuOption(Icons.delete_outline_rounded, 'Delete Post', () {
                  Navigator.pop(context); 
                  CustomDialog.show(context: context, title: 'Delete Post?', message: 'Are you sure you want to delete this post?', confirmText: 'Delete', isDestructive: true, onConfirm: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post Deleted!'))); });
                }, color: Colors.red), 
              ] 
            : [ 
                _buildMenuOption(Icons.bookmark_border_rounded, 'Save Post', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.link_rounded, 'Copy Link', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.person_remove_outlined, 'Unfollow ${widget.authorName.split(' ')[0]}', () => Navigator.pop(context)), 
                _buildMenuOption(Icons.visibility_off_outlined, 'Hide this post', () => Navigator.pop(context)), 
                const Divider(), 
                _buildMenuOption(Icons.flag_outlined, 'Report Post', () => Navigator.pop(context), color: Colors.red), 
              ],
          ),
        );
      }
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {Color color = const Color(0xFF1A1A1A)}) { 
    return ListTile(leading: Icon(icon, color: color), title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color)), onTap: onTap, dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)); 
  }

  void _showCommentSheet(BuildContext context) { 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const CommentSheet()); 
  }

  // 🚀 Go to Profile Method
  void _goToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(isOwnProfile: widget.isOwnPost)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14), 
            child: Row(
              children: [
                // 🚀 Clickable Avatar & Name
                Expanded(
                  child: GestureDetector(
                    onTap: _goToProfile,
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.avatarImg)), 
                          const SizedBox(width: 12), 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Row(
                                children: [
                                  Text(widget.authorName, style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                                  const SizedBox(width: 4),
                                  // Show custom verified badge
                                  Image.asset('assets/verified_badge.png', width: 14, height: 14, errorBuilder: (c, e, s) => const SizedBox())
                                ],
                              ), 
                              Row(children: [Text('${widget.time} • ', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E8E8E), fontWeight: FontWeight.w500)), const Icon(Icons.public, size: 12, color: Color(0xFF8E8E8E))])
                            ]
                          ),
                        ],
                      ),
                    ),
                  ),
                ), 
                IconButton(icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF8E8E8E)), onPressed: () => _showPostMenu(context))
              ]
            )
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(widget.content, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)))), const SizedBox(height: 10),
          if (widget.postImg != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.postImg!, width: double.infinity, height: 260, fit: BoxFit.cover))),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [SizedBox(width: 42, height: 18, child: Stack(children: [_buildSmallReactionIcon('like', 0), _buildSmallReactionIcon('love', 12), _buildSmallReactionIcon('haha', 24)])), Text('1.2K', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B6B6B)))]),
                Row(children: [const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF8E8E8E)), const SizedBox(width: 4), Text('230', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E8E))), const SizedBox(width: 14), const Icon(Icons.share_rounded, size: 13, color: Color(0xFF8E8E8E)), const SizedBox(width: 4), Text('45', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E8E))), const SizedBox(width: 14), const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF8E8E8E)), const SizedBox(width: 4), Text('10.5K', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E8E)))]),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(onLongPressStart: (details) => _showReactionMenu(context, details.globalPosition), onTap: _handleLikeClick, child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: _getReactionWidget())),
                GestureDetector(onTap: () => _showCommentSheet(context), child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: const Icon(Icons.chat_bubble_outline_rounded, size: 24, color: Color(0xFF6B6B6B)))),
                GestureDetector(onTap: () {}, child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: const Icon(Icons.share_rounded, size: 24, color: Color(0xFF6B6B6B)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallReactionIcon(String assetName, double leftPos) { 
    return Positioned(left: leftPos, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)), child: Center(child: Image.asset('assets/reactions/$assetName.png', width: 12, height: 12, errorBuilder: (c, e, s) => const SizedBox())))); 
  }
  
  Widget _getReactionWidget() {
    if (_selectedReaction == null) return const Icon(Icons.thumb_up_alt_outlined, size: 24, color: Color(0xFF6B6B6B));
    String assetName = 'like'; 
    if (_selectedReaction == 'Love') assetName = 'love'; 
    if (_selectedReaction == 'Haha') assetName = 'haha'; 
    if (_selectedReaction == 'Wow') assetName = 'wow'; 
    if (_selectedReaction == 'Sad') assetName = 'sad'; 
    if (_selectedReaction == 'Angry') assetName = 'angry';
    return Image.asset('assets/reactions/$assetName.png', width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.thumb_up, color: Color(0xFFFF6D00)));
  }
}