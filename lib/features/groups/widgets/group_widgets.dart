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

// ─────────────────────────────────────────────────────────────────────────────
// YourProgressSection — Daftar subtask milik user yang login.
// ─────────────────────────────────────────────────────────────────────────────
class YourProgressSection extends StatelessWidget {
  final List subtasks;
  final String userId;
  final Function(String subtaskId, int progress) onStatusChanged;

  const YourProgressSection({
    super.key,
    required this.subtasks,
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Filter subtask yang progresnya milik user ini (atau semua jika logikanya berbeda)
    // Di screenshot, ini menampilkan 'Your Progres'
    final userSubtasks = subtasks; // Placeholder, idealnya filter by userId

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progres',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              // Ikon status kecil di pojok (opsional, sesuai gambar 1)
              Image.asset('assets/images/google_icon.png', height: 40, opacity: const AlwaysStoppedAnimation(0.1)),
            ],
          ),
          const SizedBox(height: 15),
          ...userSubtasks.map((st) {
            final progressData = (st['subtask_progress'] as List?)?.firstWhere(
              (p) => p['user_id'] == userId,
              orElse: () => null,
            );
            final currentProgress = (progressData?['progress'] as num?)?.toInt() ?? 0;

            return _YourSubtaskItem(
              title: st['title'],
              progress: currentProgress,
              onChanged: (val) => onStatusChanged(st['id'], val),
            );
          }),
        ],
      ),
    );
  }
}

class _YourSubtaskItem extends StatelessWidget {
  final String title;
  final int progress;
  final Function(int) onChanged;

  const _YourSubtaskItem({
    required this.title,
    required this.progress,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String statusText = 'Upcoming';
    if (progress >= 100) statusText = 'Done';
    else if (progress > 0) statusText = 'In Progress';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, color: Colors.white, size: 14),
              ],
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
            'assets/images/group_task.png',
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
    try {
      final dt = DateTime.parse(s);
      return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final links = (task['task_links'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
              ),
              const Spacer(),
              TaskProgressIndicator(
                progress: progress,
                size: 55,
                strokeWidth: 6,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task['title'] ?? '',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            task['description'] ?? '',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          // Link docs (Gambar 1 & 2)
          ...links.map((link) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              link['url'] ?? '',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatDate(task['start_date'])} - ${_formatDate(task['due_date'])} | ${task['subject'] ?? ''} | ${task['groups']?['course_name'] ?? ''}',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Report',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
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
// CreateSubtaskSection — Tabs Automatic/Manual untuk membuat subtask.
// ─────────────────────────────────────────────────────────────────────────────
class CreateSubtaskSection extends StatefulWidget {
  final List members;
  final Function(String title, String? assignedTo, String description) onCreateManual;
  final VoidCallback onCreateAutomatic;

  const CreateSubtaskSection({
    super.key,
    required this.members,
    required this.onCreateManual,
    required this.onCreateAutomatic,
  });

  @override
  State<CreateSubtaskSection> createState() => _CreateSubtaskSectionState();
}

class _CreateSubtaskSectionState extends State<CreateSubtaskSection> {
  int _activeTab = 0; // 0=Automatic, 1=Manual
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedMemberId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Subtask',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 15),
          // Tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _TabItem(title: 'Automatic', active: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
                _TabItem(title: 'Manual', active: _activeTab == 1, onTap: () => setState(() => _activeTab = 1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _activeTab == 0 ? _buildAutomatic() : _buildManual(),
        ],
      ),
    );
  }

  Widget _buildAutomatic() {
    return Column(
      children: [
        Text(
          '*Tasks will be automatically divided among each member evenly according to their abilities.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: widget.onCreateAutomatic,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Create',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: GroupInputField(label: 'Subtask title', hint: 'subtask title', controller: _titleCtrl),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 2,
              child: _DropdownPerson(
                label: 'Subject',
                hint: 'pick the person',
                value: _selectedMemberId,
                members: widget.members,
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GroupInputField(label: 'Description', hint: 'description', controller: _descCtrl),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: () {
            widget.onCreateManual(_titleCtrl.text, _selectedMemberId, _descCtrl.text);
            _titleCtrl.clear();
            _descCtrl.clear();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Create',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? AppColors.primaryTeal : Colors.transparent, width: 2.5)),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.black : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownPerson extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List members;
  final Function(String?) onChanged;

  const _DropdownPerson({
    required this.label,
    required this.hint,
    required this.value,
    required this.members,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.only(left: 14, right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 12)),
              icon: Icon(Icons.expand_more_rounded, color: Colors.grey[300]),
              items: members.map((m) {
                final p = m['profiles'];
                return DropdownMenuItem<String>(
                  value: p['id'],
                  child: Text(p['full_name'] ?? 'Member', style: GoogleFonts.outfit(fontSize: 13)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -10,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
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

  const GroupMemberSection({
    super.key,
    required this.members,
    required this.subtasks,
    required this.createdBy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 15),
          ...members.map(
            (m) => GroupMemberProgressTile(
              member: m,
              allSubtasks: subtasks,
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
class GroupMemberProgressTile extends StatefulWidget {
  final dynamic member;
  final List allSubtasks;

  const GroupMemberProgressTile({
    super.key,
    required this.member,
    required this.allSubtasks,
  });

  @override
  State<GroupMemberProgressTile> createState() => _GroupMemberProgressTileState();
}

class _GroupMemberProgressTileState extends State<GroupMemberProgressTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.member['profiles'];
    final userId = profile['id'];
    
    final userSubtasks = widget.allSubtasks.where((st) {
      final progress = (st['subtask_progress'] as List?);
      return progress?.any((p) => p['user_id'] == userId) ?? false;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isExpanded ? const Color(0xFF8BB7BB) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: _isExpanded ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (val) => setState(() => _isExpanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _isExpanded ? Colors.white : AppColors.primaryTeal.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                profile?['avatar_url'] ?? 'https://via.placeholder.com/150',
              ),
            ),
          ),
          title: Text(
            profile?['full_name'] ?? 'Member',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, 
              fontSize: 16, 
              color: _isExpanded ? Colors.white : AppColors.primaryTeal,
            ),
          ),
          subtitle: Text(
            '${userSubtasks.length} SubTask',
            style: GoogleFonts.outfit(
              fontSize: 12, 
              color: _isExpanded ? Colors.white.withOpacity(0.8) : Colors.grey,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, 
            color: _isExpanded ? Colors.white : Colors.grey,
          ),
          children: [
            Container(
              color: Colors.white, // Isi selalu putih
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: userSubtasks.map((st) {
                  final progressData = (st['subtask_progress'] as List?)?.firstWhere(
                    (p) => p['user_id'] == userId,
                    orElse: () => null,
                  );
                  final progress = (progressData?['progress'] as num?)?.toInt() ?? 0;
                  String statusText = 'Upcoming';
                  Color statusColor = Colors.blue;
                  if (progress >= 100) { statusText = 'Done'; statusColor = AppColors.primaryTeal; }
                  else if (progress > 0) { statusText = 'In progress'; statusColor = Colors.orange; }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          st['title'],
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
          // Tombol Kembali melingkar dengan latar belakang teal (Gambar 2)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Group Task',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              // Ilustrasi sesuai Gambar 2 (assets/images/group_task.png)
              Image.asset(
                'assets/images/group_task.png',
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 100),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

