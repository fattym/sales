import 'package:flutter/material.dart';

class AppColors {
  // Core Primary (Your main green)
  static const Color primaryGreen = Color(0xFF80AC4A);

  // Monochromatic Flow (Shades of Primary for depth and gradients)
  static const Color primaryDark = Color(
    0xFF5A7C32,
  ); // For pressed states, app bars, and rich gradients
  static const Color primaryLight = Color(
    0xFFB1D288,
  ); // For subtle highlights and soft gradients
  static const Color primaryPale = Color(
    0xFFEAF2E0,
  ); // For backgrounds, list items, and inputs

  // Accents (Complementary colors to make the UI pop)
  static const Color accentOrange = Color(
    0xFFE88D41,
  ); // Warm contrast for call-to-actions
  static const Color softGold = Color(0xFFF4C244); // Attention/Warning
  static const Color errorRed = Color(0xFFD9534F); // Alerts/Errors
  static const Color infoBlue = Color(0xFF4A90E2); // Links/Info tags

  // Earthy Neutrals (Grays with a slight green undertone for harmony)
  static const Color textDark = Color(
    0xFF2C3325,
  ); // Main text (easier on the eyes than pure black)
  static const Color textMuted = Color(0xFF6E7866); // Subtitles/Hint text
  static const Color borderGrey = Color(0xFFD4DAD0); // Borders and dividers
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Cards and Dialogs

  // Original & Legacy definitions (Kept to prevent breaking existing code)
  static const Color longhornMaroon = primaryGreen;
  static const Color charcoalGrey = textDark;
  static const Color leafGreen = Color(0xFF7DBB42);
  static const Color sageGreyGreen = Color(0xFFA8B892);
  static const Color accentYellow = softGold;
  static const Color secondaryOrange = accentOrange;
}
