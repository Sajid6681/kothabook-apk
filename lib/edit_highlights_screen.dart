import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditHighlightsScreen extends StatelessWidget {
  const EditHighlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Highlights', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Edit Highlights Page Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}