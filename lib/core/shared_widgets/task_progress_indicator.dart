import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

/// Indikator progres melingkar dengan persentase di tengah.
/// Digunakan di kartu tugas grup, detail tugas mandiri, dan detail grup.
class TaskProgressIndicator extends StatelessWidget {
  final double progress; // Nilai 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final double fontSize;

  const TaskProgressIndicator({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) => Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
      ],
    );
}
