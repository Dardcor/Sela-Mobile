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
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topInset + 20,
            horizontalPadding,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onProfileTap,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage:
                                  profile?['avatar_url'] != null &&
                                      profile!['avatar_url'].toString().isNotEmpty
                                  ? NetworkImage(profile!['avatar_url'])
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/images/default_profile.png',
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet
                                      ? availableWidth * 0.45
                                      : availableWidth * 0.55,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(isTablet ? 12 : 10),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: AppColors.primaryTeal,
                              size: isTablet ? 26 : 24,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                'Task Overview',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _OverviewCard(count: '$allTasksCount', label: 'All tasks'),
                    _OverviewCard(count: '$doneTasksCount', label: 'Done'),
                    _OverviewCard(
                      count: '$inProgressCount',
                      label: 'In progress',
                    ),
                    _OverviewCard(count: '$upcomingCount', label: 'Pending'),
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
  final String label;

  const _OverviewCard({required this.count, required this.label});

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
              label,
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
    String subtitleStr = 'No description';
    
    // Priority 1: Show description if available
    if (task['description'] != null && task['description'].toString().trim().isNotEmpty) {
      subtitleStr = task['description'].toString().trim();
    } 
    // Priority 2: Fallback to dates if description is empty but dates are set
    else if (task['start_date'] != null && task['due_date'] != null) {
      final start = DateTime.parse(task['start_date']);
      final due = DateTime.parse(task['due_date']);
      subtitleStr = '${_formatDate(start)} - ${_formatDate(due)}';
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
          hintText: 'Search a task....',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        ),
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width >= 600 ? 32 : 25,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: GoogleFonts.outfit(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
