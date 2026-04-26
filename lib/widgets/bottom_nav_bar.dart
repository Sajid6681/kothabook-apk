import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  final VoidCallback onProfileTap;

  const BottomNavBar({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 8))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', isActive: true),
          _buildNavItem(Icons.slow_motion_video_rounded, 'Reels'),
          
          // Center Action Button (Add Post/Upload)
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 56, height: 56, 
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00), 
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.white, width: 4), 
                boxShadow: [BoxShadow(color: const Color(0xFFFF6D00).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
              ), 
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32)
            )
          ),
          
          _buildMessageItem('Message'),
          
          // Profile Button (Instead of Menu)
          GestureDetector(
            onTap: onProfileTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24, height: 24, 
                  margin: const EdgeInsets.only(bottom: 4), 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: Colors.grey.shade300, width: 2), 
                    image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?img=11'), fit: BoxFit.cover)
                  )
                ),
                Text('Profile', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFA0A0A0), fontWeight: FontWeight.w500))
              ]
            )
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(icon, color: isActive ? const Color(0xFFFF6D00) : const Color(0xFFA0A0A0), size: 26), 
        const SizedBox(height: 2), 
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isActive ? const Color(0xFFFF6D00) : const Color(0xFFA0A0A0), fontWeight: isActive ? FontWeight.bold : FontWeight.w500))
      ]
    );
  }

  Widget _buildMessageItem(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Stack(
          clipBehavior: Clip.none, 
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFA0A0A0), size: 26), 
            Positioned(
              right: -4, top: -4, 
              child: Container(
                width: 18, height: 18, 
                decoration: BoxDecoration(color: const Color(0xFFFF6D00), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), 
                child: const Center(child: Text('5', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1)))
              )
            ) 
          ]
        ), 
        const SizedBox(height: 2), 
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFA0A0A0), fontWeight: FontWeight.w500))
      ]
    );
  }
}