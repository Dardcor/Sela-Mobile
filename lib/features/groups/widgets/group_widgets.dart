import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';


/// Kartu grup di GroupScreen yang menampilkan avatar anggota,
/// nama grup, dan tombol detail.
class GroupCard extends StatelessWidget {
  final dynamic team;
  final VoidCallback onDetailTap;

  const GroupCard({
    super.key,
    required this.team,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final members = (team['group_members'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
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
          // Avatar stack anggota
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                ...List.generate(
                  min(members.length, 3),
                  (idx) => Positioned(
                    left: idx * 24.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            members[idx]['profiles']?['avatar_url'] != null
                                ? NetworkImage(
                                        members[idx]['profiles']['avatar_url'])
                                    as ImageProvider
                                : const AssetImage('assets/images/avatar.png'),
                      ),
                    ),
                  ),
                ),
                if (members.length > 3)
                  Positioned(
                    left: 72,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        '+${members.length - 3}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            team['name'] ?? '',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grup',
            style: GoogleFonts.outfit(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${members.length} Member',
                style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
              ),
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

/// Widget section kode undangan/kuliah grup.
class GroupCodeSection extends StatelessWidget {
  final String label;
  final String? code;

  const GroupCodeSection({
    super.key,
    required this.label,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  code ?? '',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _IconActionButton(
              icon: Icons.copy_all_rounded,
              onTap: () => Clipboard.setData(ClipboardData(text: code ?? '')),
            ),
            const SizedBox(width: 10),
            _IconActionButton(
              icon: Icons.refresh_rounded,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

/// Input field dengan floating label untuk modal di GroupScreen.
class GroupInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isNum;
  final Color bgColor;

  const GroupInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isNum = false,
    this.bgColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              hintStyle: GoogleFonts.outfit(color: Colors.grey[300]),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -10,
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown field dengan floating label untuk modal di GroupScreen.
class GroupDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final Color bgColor;

  const GroupDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.bgColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.outfit(color: Colors.grey[300]),
              ),
              icon: Icon(Icons.expand_more, color: Colors.grey[300]),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(e, style: GoogleFonts.outfit(color: Colors.black)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -10,
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section progress subtask + member — digunakan di GroupDetailScreen.
class GroupProgressSection extends StatelessWidget {
  final String title;
  final List subtasks;

  const GroupProgressSection({
    super.key,
    required this.title,
    required this.subtasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 15),
          ...subtasks.map((st) => _SubtaskRow(title: st['title'], value: 50)),
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final String title;
  final double value;

  const _SubtaskRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.outfit(fontSize: 14)),
          ),
          Text(
            '${value.toInt()}%',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.grey[200],
                color: AppColors.primaryTeal,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GroupDetailHeader — Header navigasi detail tugas grup.
// Diekstrak dari GroupDetailScreen; const-safe karena hanya perlu context.
// ─────────────────────────────────────────────────────────────────────────────
class GroupDetailHeader extends StatelessWidget {
  const GroupDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Work in Group',
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          Image.asset(
            'assets/images/work_in_group.png',
            height: 100,
            errorBuilder: (_, __, ___) => const SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GroupMainCard — Kartu utama info tugas grup (ikon + judul + progress + tanggal).
// Diekstrak agar rebuild hanya terjadi saat data task berubah.
// ─────────────────────────────────────────────────────────────────────────────
class GroupMainCard extends StatelessWidget {
  final dynamic task;
  final double progress;

  const GroupMainCard({
    super.key,
    required this.task,
    required this.progress,
  });

  String _formatDate(String? s) {
    if (s == null) return '';
    final dt = DateTime.parse(s);
    return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                child: const Icon(Icons.book_outlined, color: Colors.white, size: 20),
              ),
              const Spacer(),
              // ✅ Indikator progres dari shared_widgets
              TaskProgressIndicator(progress: progress, size: 45, strokeWidth: 5, fontSize: 10),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            task['title'] ?? '',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            task['description'] ?? '',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                '${_formatDate(task['start_date'])} - ${_formatDate(task['due_date'])} | ${task['category'] ?? ''}',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Report',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────────────────────
// GroupMemberSection — Kartu "Member & Progres" di GroupDetailScreen.
// Diekstrak agar rebuild hanya terjadi saat daftar anggota berubah.
// ─────────────────────────────────────────────────────────────────────────────
class GroupMemberSection extends StatelessWidget {
  final List members;
  final List subtasks;
  final String createdBy;
  final Future<void> Function(dynamic memberId) onDeleteMember;

  const GroupMemberSection({
    super.key,
    required this.members,
    required this.subtasks,
    required this.createdBy,
    required this.onDeleteMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member & Progres',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 15),
          ...members.map(
            (m) => GroupMemberProgressTile(
              member: m,
              subtasks: subtasks,
              createdBy: createdBy,
              onDelete: () => onDeleteMember(m['id']),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GroupMemberProgressTile — Tile ekspansi untuk satu anggota beserta subtask-nya.
// Diekstrak agar setiap tile bisa di-rebuild secara independen.
// ─────────────────────────────────────────────────────────────────────────────
class GroupMemberProgressTile extends StatelessWidget {
  final dynamic member;
  final List subtasks;
  final String createdBy;
  final VoidCallback onDelete;

  const GroupMemberProgressTile({
    super.key,
    required this.member,
    required this.subtasks,
    required this.createdBy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final profile = member['profiles'];
    final isLeader = member['role'] == 'leader';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            profile?['avatar_url'] ?? 'https://via.placeholder.com/150',
          ),
        ),
        title: Text(
          profile?['full_name'] ?? 'Member',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${subtasks.length} SubTask',
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
        ),
        trailing: !isLeader
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primaryTeal,
                  size: 28,
                ),
                onPressed: onDelete,
              )
            : null,
        children: subtasks
            .map(
              (st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(st['title'], style: GoogleFonts.outfit(fontSize: 12)),
                    Text(
                      '100%',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkInGroupHeader — Header layar Work In Group (back + judul + ilustrasi).
// Diekstrak dari WorkInGroupScreen untuk isolasi rebuild.
// ─────────────────────────────────────────────────────────────────────────────
class WorkInGroupHeader extends StatelessWidget {
  const WorkInGroupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 55, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work in Group',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  Text(
                    'Your group assignments',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              Image.asset(
                'assets/images/work_group.png',
                height: 80,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: AppColors.primaryTeal,
                    size: 40,
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
