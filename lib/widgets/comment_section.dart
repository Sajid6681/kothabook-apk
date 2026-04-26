import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// COMMENT BOTTOM SHEET COMPONENT
// ==========================================
class CommentSheet extends StatefulWidget {
  const CommentSheet({super.key});
  @override State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final FocusNode _focusNode = FocusNode();
  void _focusInput() { FocusScope.of(context).requestFocus(_focusNode); }
  @override void dispose() { _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 16), width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Comments', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), Row(children: [const Icon(Icons.thumb_up, size: 14, color: Color(0xFFFF6D00)), const SizedBox(width: 4), Text('1.2K', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFA0A0A0))])]),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CommentItemWidget(author: 'Ishrat', content: 'This looks absolutely stunning baby! ❤️', time: '1h', avatar: 'https://i.pravatar.cc/150?img=47', onReply: _focusInput),
                CommentItemWidget(author: 'David Smith', content: 'Bro, this update is literally fire! 🔥 Keep it up!', time: '30m', avatar: 'https://i.pravatar.cc/150?img=12', onReply: _focusInput),
              ],
            ),
          ),
          // Bottom Input
          Container(
            padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 12), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')), const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      children: [
                        Expanded(child: TextField(focusNode: _focusNode, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)), decoration: InputDecoration(hintText: 'Write a comment...', hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF65676B)), border: InputBorder.none, isDense: true))),
                        const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF65676B)), const SizedBox(width: 12),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF65676B), width: 1.5), borderRadius: BorderRadius.circular(4)), child: Text('GIF', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF65676B), height: 1))), const SizedBox(width: 12),
                        const Icon(Icons.sentiment_satisfied_alt_rounded, size: 20, color: Color(0xFF65676B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFFF6D00), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// INDIVIDUAL COMMENT WIDGET
// ==========================================
class CommentItemWidget extends StatefulWidget {
  final String author; final String content; final String time; final String avatar; final VoidCallback onReply;
  const CommentItemWidget({super.key, required this.author, required this.content, required this.time, required this.avatar, required this.onReply});
  @override State<CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<CommentItemWidget> {
  String? _selectedReaction;

  void _showReactionMenu(BuildContext context, Offset position) {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "Reaction", barrierColor: Colors.transparent, transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: 40, bottom: MediaQuery.of(context).size.height - position.dy + 10,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5))]),
                    child: Row(children: [_reactionEmoji(context, '👍', 'Like'), _reactionEmoji(context, '❤️', 'Love'), _reactionEmoji(context, '😂', 'Haha'), _reactionEmoji(context, '😲', 'Wow'), _reactionEmoji(context, '😢', 'Sad'), _reactionEmoji(context, '😡', 'Angry')]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reactionEmoji(BuildContext context, String emoji, String label) {
    return GestureDetector(onTap: () { setState(() { _selectedReaction = label; }); Navigator.of(context).pop(); }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(emoji, style: const TextStyle(fontSize: 24))));
  }

  void _handleLikeClick() { setState(() { _selectedReaction = _selectedReaction != null ? null : 'Like'; }); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.avatar)), const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.author, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), Text(widget.content, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)))]),
                    ),
                    if (_selectedReaction != null) Positioned(right: -8, bottom: -10, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Text(_selectedReaction == 'Love' ? '❤️' : _selectedReaction == 'Haha' ? '😂' : _selectedReaction == 'Wow' ? '😲' : _selectedReaction == 'Sad' ? '😢' : _selectedReaction == 'Angry' ? '😡' : '👍', style: const TextStyle(fontSize: 12))))
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: Row(
                    children: [
                      Text(widget.time, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF65676B))), const SizedBox(width: 16),
                      GestureDetector(onLongPressStart: (details) => _showReactionMenu(context, details.globalPosition), onTap: _handleLikeClick, child: Text(_selectedReaction != null ? _selectedReaction! : 'React', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _selectedReaction != null ? const Color(0xFFFF6D00) : const Color(0xFF65676B)))), const SizedBox(width: 16),
                      GestureDetector(onTap: widget.onReply, child: Text('Reply', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF65676B)))), const SizedBox(width: 16),
                      Text('Report', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF65676B))),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}