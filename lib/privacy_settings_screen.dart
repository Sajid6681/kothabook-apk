import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Privacy Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Privacy Settings Page Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}