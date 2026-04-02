import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Search bar gaya homepage tanpa tombol search terpisah.
/// Digunakan secara konsisten di halaman daftar tugas.
class SearchBarWithButton extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearchTap;

  const SearchBarWithButton({
    super.key,
    required this.controller,
    this.hintText = 'Search a task....',
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width >= 600 ? 32 : 25,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        ),
      ),
    ),
  );
}
