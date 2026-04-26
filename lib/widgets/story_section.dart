import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Stories', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _buildCreateStoryCard(),
                const SizedBox(width: 12),
                _buildStoryCard('Ishrat', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&q=80', 'https://i.pravatar.cc/150?img=47'),
                const SizedBox(width: 12),
                _buildStoryCard('David', 'https://images.unsplash.com/photo-1518002171953-a080ee817e1f?w=300&q=80', 'https://i.pravatar.cc/150?img=33'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    return Container(
      width: 105, decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(top: 0, left: 0, right: 0, height: 100, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network('https://i.pravatar.cc/150?img=11', fit: BoxFit.cover))),
          Container(height: 45, width: double.infinity, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))), alignment: Alignment.center, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text('Create', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)))),
          Positioned(top: 85, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Container(decoration: const BoxDecoration(color: Color(0xFFFF6D00), shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.add_rounded, color: Colors.white, size: 16)))),
        ],
      ),
    );
  }

  Widget _buildStoryCard(String name, String imageUrl, String avatarUrl) {
    return Container(
      width: 105, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF6D00), width: 2)), child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(avatarUrl))),
            Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}