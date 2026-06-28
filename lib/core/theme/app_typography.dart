import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextStyle get displayLarge =>
      GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w600);

  static TextStyle get headlineMedium =>
      GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700);

  static TextStyle get headlineSmall =>
      GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get labelCaps => GoogleFonts.spaceGrotesk(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
  );
}
