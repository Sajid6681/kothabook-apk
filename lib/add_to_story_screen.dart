import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddToStoryScreen extends StatelessWidget {
  const AddToStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add to Story', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Add to Story Page Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}