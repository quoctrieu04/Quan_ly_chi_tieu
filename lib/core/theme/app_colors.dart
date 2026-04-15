import 'package:flutter/material.dart';

/// Hệ màu thống nhất cho ứng dụng quản lý chi tiêu
/// Phong cách: Mint/Teal – hiện đại, sáng, nhẹ mắt
abstract class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────
  static const primary      = Color(0xFF2EC4B6); // mint/teal – màu chủ đạo
  static const primaryDark  = Color(0xFF1A9E92); // text trên nền sáng
  static const primaryLight = Color(0xFF5DE8DA); // gradient end / highlight

  // ── Tint surfaces ─────────────────────────────────
  static const primarySurface = Color(0xFFE6FAF7); // tinted surface

  // ── Layout ────────────────────────────────────────
  static const background  = Color(0xFFF5F7FA); // nền toàn app
  static const surface     = Color(0xFFFFFFFF); // card, sheet
  static const border      = Color(0xFFE8ECF0); // viền card nhẹ

  // ── Text ──────────────────────────────────────────
  static const textMain    = Color(0xFF1A2332); // chữ chính
  static const textSub     = Color(0xFF94A3B8); // chữ phụ

  // ── Status ────────────────────────────────────────
  static const warning     = Color(0xFFF59E0B); // cảnh báo
  static const danger      = Color(0xFFEF4444); // vượt mức

  // ── Dark mode equivalents ─────────────────────────
  static const darkBackground = Color(0xFF0F1419);
  static const darkSurface    = Color(0xFF1C2530);
  static const darkBorder     = Color(0xFF2A3544);
  static const darkTextMain   = Color(0xFFE8ECF0);
  static const darkTextSub    = Color(0xFF7B8794);
}
