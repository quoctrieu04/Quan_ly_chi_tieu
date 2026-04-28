import 'package:flutter/material.dart';

/// He mau thong nhat cho ung dung quan ly chi tieu.
/// Phong cach: sky blue/cyan, sang va nhe mat.
abstract class AppColors {
  AppColors._();

  static const primary = Color(0xFF5EA6F2);
  static const primaryDark = Color(0xFF2F6FAF);
  static const primaryLight = Color(0xFF56DCCB);

  static const primarySurface = Color(0xFFEAF5FF);

  static const background = Color(0xFFF6FBFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2EEF8);

  static const textMain = Color(0xFF172033);
  static const textSub = Color(0xFF7A8BA3);

  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFE85D75);

  static const darkBackground = Color(0xFF0E1723);
  static const darkSurface = Color(0xFF172536);
  static const darkBorder = Color(0xFF26384D);
  static const darkTextMain = Color(0xFFEAF3FA);
  static const darkTextSub = Color(0xFF8EA4B8);
}
