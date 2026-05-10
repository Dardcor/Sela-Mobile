import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Search bar gaya homepage tanpa tombol search terpisah.
/// Digunakan secara konsisten di halaman daftar tugas.
class SearchBarWithButton extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearchTap;
  final Function(String)? onChanged;

  const SearchBarWithButton({
    super.key,
    required this.controller,
    this.hintText = 'Search a task...',
    this.onSearchTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width >= 600 ? 32 : 25,
      vertical: 10,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 50,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
              suffixIcon: value.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        controller.clear();
                        if (onChanged != null) onChanged!('');
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    ),
  );
}
