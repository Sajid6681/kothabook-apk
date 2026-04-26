import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareProfileScreen extends StatelessWidget {
  const ShareProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Share Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Share Profile Page Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}