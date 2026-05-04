import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class LecturerNotificationScreen extends StatelessWidget {
  const LecturerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data Notifikasi Dosen
    final List<Map<String, String>> notifications = [
      {
        'title': 'Tugas Selesai',
        'message': 'Kelompok 1 (2 D3 IT B) telah menyelesaikan tugas "Makalah AWS".',
        'time': '10 menit yang lalu',
        'icon': 'task_alt',
      },
      {
        'title': 'Tugas Selesai',
        'message': 'Kelompok 3 (1 D3 IT A) telah menyelesaikan tugas "Implementasi Jaringan".',
        'time': '1 jam yang lalu',
        'icon': 'task_alt',
      },
      {
        'title': 'Subtask Selesai',
        'message': 'Syahrul (Kelompok 1) menyelesaikan subtask "Bab 2: bagaimana cara daftar akun aws".',
        'time': '2 jam yang lalu',
        'icon': 'check_circle_outline',
      },
      {
        'title': 'Tugas Selesai',
        'message': 'Kelompok 2 (2 D3 IT B) telah menyelesaikan tugas "Setup Docker Compose".',
        'time': '1 hari yang lalu',
        'icon': 'task_alt',
      },
      {
        'title': 'Peringatan Tenggat',
        'message': 'Tugas "Makalah AWS" (2 D3 IT B) akan ditutup dalam 12 Hari.',
        'time': '2 hari yang lalu',
        'icon': 'warning_amber_rounded',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Notifications',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Notification List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      
                      // Menentukan ikon berdasarkan tipe string
                      IconData iconData = Icons.notifications;
                      Color iconColor = AppColors.primaryTeal;
                      if (notif['icon'] == 'task_alt') {
                        iconData = Icons.task_alt;
                        iconColor = Colors.green;
                      } else if (notif['icon'] == 'check_circle_outline') {
                        iconData = Icons.check_circle_outline;
                        iconColor = Colors.blue;
                      } else if (notif['icon'] == 'warning_amber_rounded') {
                        iconData = Icons.warning_amber_rounded;
                        iconColor = Colors.orange;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title']!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        notif['time']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    notif['message']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}