import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportProfileScreen extends StatelessWidget {
  const ReportProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Report Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(child: Text('Report Options Coming Soon!', style: GoogleFonts.poppins())),
    );
  }
}