import 'dart:ui';
import 'package:flutter/material.dart';

class AppDesign {
  // Premium Pastel Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F7FA), // Light Cyan
      Color(0xFFE8F5E9), // Light Green
      Color(0xFFF3E5F5), // Light Purple
    ],
  );

  // Glassmorphism Decoration
  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.5)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  // Logo Text Style
  static const TextStyle logoTextStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.teal,
    letterSpacing: 1.2,
  );
}
