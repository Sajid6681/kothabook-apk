import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopNavBar extends StatelessWidget {
  final VoidCallback onMenuTap;

  const TopNavBar({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 🚀 ERROR FIXED: Cannot provide both a color and a decoration. তাই color রিমুভ করা হলো।
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white, // কালার এখন শুধু ডেকোরেশনের ভেতরেই থাকবে
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28, color: Color(0xFF1A1A1A)),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          Text('KOTHABOOK', style: GoogleFonts.righteous(fontSize: 22, color: const Color(0xFFFF6D00), letterSpacing: 1.5)),
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 26, color: Color(0xFF1A1A1A)), const SizedBox(width: 12),
              Stack(clipBehavior: Clip.none, children: [const Icon(Icons.people_outline_rounded, size: 26, color: Color(0xFF1A1A1A)), Positioned(right: -2, top: -2, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFFF6D00), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1))))) ]), const SizedBox(width: 12),
              Stack(clipBehavior: Clip.none, children: [const Icon(Icons.notifications_none_rounded, size: 26, color: Color(0xFF1A1A1A)), Positioned(right: -2, top: -2, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFFF6D00), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1))))) ]),
            ],
          ),
        ],
      ),
    );
  }
}