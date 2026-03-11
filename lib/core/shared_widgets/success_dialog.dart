import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

/// Dialog popup sukses generik dengan ikon centang.
/// Digunakan di AddProjectScreen dan GroupScreen setelah operasi berhasil.
class SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onOk;

  const SuccessDialog({
    super.key,
    required this.message,
    this.onOk,
  });

  /// Tampilkan dialog dari luar menggunakan metode statis ini
  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onOk,
  }) => showDialog(
      context: context,
      builder: (ctx) => SuccessDialog(
        message: message,
        onOk: onOk ?? () => Navigator.pop(ctx),
      ),
    );

  @override
  Widget build(BuildContext context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryTeal,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'Success!',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onOk ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
}
