import 'package:flutter/material.dart';

class AppColors {
  // Warm Light Palette
  static const Color lightBg = Color(0xFFF9F8F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = lightSurface;
  static const Color lightSurfaceSubtle = Color(0xFFF3EFE7);
  static const Color lightBorder = Color(0xFFE5E0D5);
  static const Color lightTextPrimary = Color(0xFF1E1D1B);
  static const Color lightTextSecondary = Color(0xFF6B6862);
  static const Color lightTextMuted = Color(0xFF9E9A91);

  // Warm Dark Palette (Fixed, clean, beautiful warm dark mode)
  static const Color darkBg = Color(0xFF181716);
  static const Color darkSurface = Color(0xFF242220);
  static const Color darkCard = darkSurface;
  static const Color darkSurfaceSubtle = Color(0xFF2C2A27);
  static const Color darkBorder = Color(0x38FFFFFF);
  static const Color darkTextPrimary = Color(0xFFEDEAE3);
  static const Color darkTextSecondary = Color(0xFFA8A49C);
  static const Color darkTextMuted = Color(0xFF747067);

  // User requested accents
  // 1. Iris Pastel: "change the iris purple name to Iris Pastel and use #8764B8 as its colour"
  static const Color irisPastel = Color(0xFF8764B8);
  static const Color irisPurple = irisPastel; // Backward compat alias
  // 2. Blue: "make the colour blue a bit more sky blue"
  static const Color skyBlue = Color(0xFF38BDF8);
  // 3. Pastel Red: "remove the teal option and add a Pastel red instead"
  static const Color pastelRed = Color(0xFFF87171);
  // 4. Pink: "change the pink to baby pin (dont change the name of the colours just the shade itself)"
  static const Color babyPink = Color(0xFFF9A8D4);
  // 5. Emerald
  static const Color emerald = Color(0xFF10B981);
  // 6. Amber
  static const Color amber = Color(0xFFF59E0B);

  // Status Colors
  static const Color present = Color(0xFF10B981); // Emerald
  static const Color late = Color(0xFFF59E0B);    // Amber
  static const Color absent = Color(0xFFEF4444);  // Red
  static const Color holiday = Color(0xFF8B5CF6); // Violet

  // Warning & Below-par Alert Red
  static const Color alertRed = Color(0xFFE11D48);
  static const Color alertRedBg = Color(0xFFFEE2E2);
  static const Color alertRedBgDark = Color(0xFF450A0A);
}
