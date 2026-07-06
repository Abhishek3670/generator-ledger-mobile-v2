import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary (unchanged)
  static const primary = Color(0xFF0F172A);
  static const primaryDark = Color(0xFF1E293B);
  
  // Accent (unchanged)
  static const accent = Color(0xFFFBBF24);
  static const accentDark = Color(0xFFF59E0B);
  
  // Semantic Success
  static const success = Color(0xFF10B981); // Emerald-500
  static const successLight = Color(0xFFD1FAE5); // Emerald-100
  static const successText = Color(0xFF047857); // Emerald-700
  
  // Semantic Warning
  static const warning = Color(0xFFF59E0B); // Amber-500
  static const warningLight = Color(0xFFFEF3C7); // Amber-100
  static const warningText = Color(0xFFD97706); // Amber-600
  
  // Semantic Error / Danger
  static const danger = Color(0xFFDC2626); // Keep for compatibility
  static const error = Color(0xFFEF4444); // Red-500
  static const errorLight = Color(0xFFFEE2E2); // Red-100
  static const errorText = Color(0xFFDC2626); // Red-600
  
  // Semantic Info
  static const info = Color(0xFF3B82F6); // Blue-500
  static const infoLight = Color(0xFFDBEAFE); // Blue-100
  static const infoText = Color(0xFF2563EB); // Blue-600
  
  // Neutral Palette (refined)
  static const background = Color(0xFFFAFAFA); // Off-white
  static const surface = Color(0xFFFFFFFF); // Pure white
  static const surfaceVariant = Color(0xFFF8F9FA); // Subtle off-white
  static const divider = Color(0xFFE5E7EB); // Light gray
  static const border = Color(0xFFCBD5E1); // Border gray (Slate-300)
  static const outline = Color(0xFF94A3B8); // Slate-400
  static const textPrimary = Color(0xFF0F172A); // Primary
  static const textSecondary = Color(0xFF64748B); // Slate-500
  static const textTertiary = Color(0xFF94A3B8); // Slate-400
  static const textDisabled = Color(0xFFCBD5E1); // Slate-300
  
  // Overlay System
  static const scrim = Color(0x990F172A); // 60% opacity
  static const overlayLight = Color(0xE6FFFFFF); // 90% white
  static const overlayDark = Color(0xE60F172A); // 90% dark

  // --- Backwards Compatibility Getters/Fields ---
  static const successBg = successLight;
  static const warningBg = warningLight;
  static const dangerBg = errorLight;
  static const dangerText = errorText;
  static const onSurface = Color(0xFF1A1C1C);
  static const surfaceContainer = Color(0xFFF3F3F3);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const tertiaryFixed = Color(0xFFFFDF9F);
  static const onTertiaryFixed = Color(0xFF261A00);
  static const slate400 = Color(0xFF94A3B8);
  static const shadowSoft = Color(0x0D0F172A);
}
