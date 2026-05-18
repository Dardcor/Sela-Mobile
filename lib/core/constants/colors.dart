import 'package:flutter/material.dart';

class AppColors {
  // Warna utama — header, tombol, ikon (BIRU-TEAL)
  static const Color primaryTeal   = Color(0xFF0089A5);
  // Warna gelap — teks judul, border, label
  static const Color darkTeal      = Color(0xFF006CA5);
  // Warna cerah — status "In Progress", progress bar
  static const Color accentTeal    = Color(0xFF00A3C4);
  // Background utama seluruh halaman
  static const Color bgLight       = Color(0xFFF1F8F9);
  // Background teal muda untuk chip/badge
  static const Color lightTealBg   = Color(0xFFE2EFF1);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryTeal, darkTeal],
  );
}
