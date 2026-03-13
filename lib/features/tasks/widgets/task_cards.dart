import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';
import '../../../core/shared_widgets/member_avatar_stack.dart';

/// Kartu tugas grup untuk layar WorkInGroupScreen.
/// Menampilkan judul, deskripsi, info tanggal/grup, tumpukan avatar, dan tombol detail.
class WorkGroupTaskCard extends StatelessWidget {
  final dynamic task;
  final double progress;
  final String detailInfo;
  final List members;
  final VoidCallback onDetailTap;

  const WorkGroupTaskCard({
    super.key,
    required this.task,
    required this.progress,
    required this.detailInfo,
    required this.members,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon dengan latar belakang lingkaran teal (Gambar 2)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  task['title'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // Indikator progres melingkar
              TaskProgressIndicator(
                progress: progress,
                size: 50,
                strokeWidth: 5,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Deskripsi tugas (Gambar 2 menggunakan teks placeholder yang panjang)
          Text(
            task['description'] ?? '',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (detailInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detailInfo,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tumpukan avatar anggota
              MemberAvatarStack(
                members: members,
                maxVisible: 3,
                avatarRadius: 15,
                overlap: 22,
              ),
              // Tombol Detail teal yang lebih menonjol
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Detail',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
}


/// Kartu tugas mandiri untuk layar IndependentTaskScreen.
class IndependentTaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onDetailTap;

  const IndependentTaskCard({
    super.key,
    required this.task,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    int daysLeft = 0;
    if (task['due_date'] != null) {
      final due = DateTime.parse(task['due_date']);
      daysLeft = due.difference(DateTime.now()).inDays;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$daysLeft days left',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priority: ${task['priority'] ?? 'Medium'}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  task['category'] ?? 'General',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Detail',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
