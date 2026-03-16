import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

/// Header generik yang tampil di atas layar sub-halaman.
/// Terdiri dari tombol back (lingkaran putih), judul terpusat, dan spacer kanan.
class ScreenHeaderBar extends StatelessWidget {
  final String title;
  final double titleFontSize;
  final Color titleColor;
  final VoidCallback? onBack;

  const ScreenHeaderBar({
    super.key,
    required this.title,
    this.titleFontSize = 24,
    this.titleColor = AppColors.primaryTeal,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(25, 55, 25, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
}
