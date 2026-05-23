import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';
import '../../../core/shared_widgets/member_avatar_stack.dart';

/// Header dashboard yang menampilkan:
/// - Avatar & nama pengguna
/// - Badge kelas/role
/// - Tombol notifikasi
/// - Kartu ringkasan tugas (overview cards)
///
/// Diekstrak dari DashboardScreen untuk mengisolasi rebuild dari
/// perubahan data profil atau tugas.
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final int allTasksCount;
  final int doneTasksCount;
  final int inProgressCount;
  final int upcomingCount;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.profile,
    required this.allTasksCount,
    required this.doneTasksCount,
    required this.inProgressCount,
    required this.upcomingCount,
    this.unreadCount = 0,
    required this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?['full_name'] ?? profile?['username'] ?? 'User';
    final role = profile?['class_name'] ?? 'Mahasiswa';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final isTablet = screenWidth >= 600;
    final horizontalPadding = isTablet ? 32.0 : 25.0;
    final avatarRadius = isTablet ? 30.0 : 26.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Top row: Profil & Notifikasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: profile?['avatar_url'] != null && profile!['avatar_url'].toString().isNotEmpty && !profile!['avatar_url'].toString().endsWith('/')
                            ? NetworkImage(profile!['avatar_url'])
                            : const AssetImage('assets/images/default_profile.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $name!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: onNotificationTap,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'Ringkasan Tugas',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          // Scrollable Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _OverviewCard(
                  title: 'Semua Tugas',
                  count: allTasksCount.toString(),
                  icon: Icons.list_alt_rounded,
                  color: Colors.white,
                  textColor: AppColors.primaryTeal,
                ),
                _OverviewCard(
                  title: 'Selesai',
                  count: doneTasksCount.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFFE8F5E9),
                  textColor: Colors.green[700]!,
                ),
                _OverviewCard(
                  title: 'Sedang Proses',
                  count: inProgressCount.toString(),
                  icon: Icons.autorenew_rounded,
                  color: const Color(0xFFFFF3E0),
                  textColor: Colors.orange[800]!,
                ),
                _OverviewCard(
                  title: 'Tertunda',
                  count: upcomingCount.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFFFEBEE),
                  textColor: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

/// Kartu angka ringkasan tugas (All tasks / Done / In progress / Upcoming).
class _OverviewCard extends StatelessWidget {
  final String count;
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _OverviewCard({
    required this.count, 
    required this.title,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 85,
    height: 84,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 16,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Kartu tugas grup di scroll horizontal dashboard.
/// Diekstrak agar rebuild list tidak mempengaruhi DashboardHeader.
class GroupTaskCard extends StatelessWidget {
  final dynamic task;
  final double progress;
  final VoidCallback onTap;

  const GroupTaskCard({
    super.key,
    required this.task,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final members = (task['members'] as List? ?? []);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * (screenWidth >= 600 ? 0.38 : 0.62))
        .clamp(190.0, 320.0)
        .toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                TaskProgressIndicator(
                  progress: progress,
                  size: 38,
                  strokeWidth: 3.5,
                  fontSize: 9,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task['title'] ?? '',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              task['description'] ?? '',
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: MemberAvatarStack(
                    members: members,
                    maxVisible: 4,
                    avatarRadius: 11,
                    overlap: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'detail',
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Item tugas mandiri dalam daftar list di dashboard.
class IndependentTaskItem extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const IndependentTaskItem({
    super.key,
    required this.task,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    String subtitleStr = 'Tidak ada deskripsi';
    
    final desc = task['description']?.toString().trim();
    
    // Priority 1: Show description if available
    if (desc != null && desc.isNotEmpty && desc != 'null') {
      subtitleStr = desc;
    } 
    // Priority 2: Fallback to due date if description is empty
    else if (task['due_date'] != null) {
      try {
        final due = DateTime.parse(task['due_date'].toString());
        subtitleStr = 'Tenggat: ${_formatDate(due)}';
      } catch (_) {
        // Ignore parse error
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardSearchBar — Search bar tugas di layar dashboard.
// Diekstrak agar rebuild search bar tidak memicu rebuild header atau list tugas.
// ─────────────────────────────────────────────────────────────────────────────
class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const DashboardSearchBar({super.key, required this.controller});

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
            maxLength: 50,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Search a task...',
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

// ─────────────────────────────────────────────────────────────────────────────
// DashboardSectionHeader — Header seksi dengan judul + tombol "See all".
// Diekstrak agar setiap header seksi dapat di-rebuild secara mandiri.
// ─────────────────────────────────────────────────────────────────────────────
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'Lihat Semua',
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
