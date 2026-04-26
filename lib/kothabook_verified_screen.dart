import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KothabookVerifiedScreen extends StatelessWidget {
  const KothabookVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('KothaBook Verified', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Get Verified Page Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}