import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // 📝 Heading
  static TextStyle heading1(Color color) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: color,
  );

  // 📝 Body Text
  static TextStyle bodyText(Color color) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color,
  );

  // 📝 Sub Text (Time, Mutual friends)
  static TextStyle subText(Color color) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
  );
}