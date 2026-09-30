import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // Display (32sp): Page titles, hero numbers
  static TextStyle get display => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02 * 32,
      );

  // Headline (24sp): Section headers
  static TextStyle get headline => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.01 * 24,
      );

  // Title (20sp): Card titles
  static TextStyle get title => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Body Large (16sp): Primary content
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Body Medium (14sp): Secondary content
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Label (12sp): Captions, metadata
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // Label Caps (11sp): All-caps utility labels
  static TextStyle get labelCaps => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1 * 11,
      );

  // --- Backwards Compatibility Aliases ---
  static TextStyle get displayLarge => display;
  static TextStyle get headlineMedium => headline;
  static TextStyle get headlineSmall => title;
  static TextStyle get bodySmall => bodyMedium;
}

