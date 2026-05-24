import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

void showUndoSnackBar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.clearSnackBars();
  
  final snackBar = SnackBar(
    duration: const Duration(seconds: 3),
    content: Text(
      message,
      style: GoogleFonts.outfit(color: Colors.white),
    ),
    backgroundColor: isDarkMode ? Colors.grey[800] : AppColors.primaryTeal,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: const EdgeInsets.all(15),
    action: SnackBarAction(
      label: 'Batal',
      textColor: Colors.white,
      onPressed: () {
        onUndo();
        scaffoldMessenger.hideCurrentSnackBar();
      },
    ),
  );
  
  scaffoldMessenger.showSnackBar(snackBar);
  
  // Tambahan: Force hide setelah 5 detik sebagai fallback
  Future.delayed(const Duration(seconds: 5), () {
    if (scaffoldMessenger.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
    }
  });
}
