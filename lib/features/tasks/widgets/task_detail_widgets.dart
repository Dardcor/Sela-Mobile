import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';

/// Kartu detail tugas mandiri — bagian atas (info task + progress besar).
/// Diekstrak agar jika progress berubah, hanya kartu ini yang di-rebuild.
class TaskDetailCard extends StatelessWidget {
  final dynamic task;
  final double progress;

  const TaskDetailCard({
    super.key,
    required this.task,
    required this.progress,
  });

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = '';
    if (task['start_date'] != null && task['due_date'] != null) {
      dateRange =
          '${_formatDateShort(DateTime.parse(task['start_date']))} - ${_formatDateShort(DateTime.parse(task['due_date']))}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              TaskProgressIndicator(
                progress: progress,
                size: 60,
                strokeWidth: 6,
                fontSize: 14,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            task['title'] ?? '',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task['description'] ?? '',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 15),
          if (task['link'] != null && task['link'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                task['link'],
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$dateRange | ${task['category'] ?? ''} | ${task['subject'] ?? ''}',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Report',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
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

/// Kartu daftar progress/subtask dari tugas mandiri.
/// Diisolasi sehingga hanya bagian ini yang di-rebuild saat data subtask berubah.
class TaskProgressCard extends StatelessWidget {
  final List subtasks;

  const TaskProgressCard({super.key, required this.subtasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          Text(
            'Your Progres',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          if (subtasks.isEmpty)
            Center(
              child: Text(
                'No progress items yet',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ...subtasks.map((st) {
              final progressList = st['subtask_progress'] as List;
              final prog = progressList.isNotEmpty
                  ? (progressList[0]['progress'] as num).toDouble()
                  : 0.0;
              return _ProgressRow(
                title: st['title'],
                value: prog,
              );
            }),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final double value;

  const _ProgressRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value.toInt()}%',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  left: (value / 100 *
                              (MediaQuery.of(context).size.width * 0.3))
                          .clamp(0.0, MediaQuery.of(context).size.width * 0.3) -
                      6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}

/// Toggle Group / Individual di AddProjectScreen.
class TaskTypeToggle extends StatelessWidget {
  final bool isGroup;
  final VoidCallback onGroupTap;
  final VoidCallback onIndividualTap;

  const TaskTypeToggle({
    super.key,
    required this.isGroup,
    required this.onGroupTap,
    required this.onIndividualTap,
  });

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onGroupTap,
              child: Container(
                decoration: BoxDecoration(
                  color: isGroup ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Center(
                  child: Text(
                    'Group',
                    style: GoogleFonts.outfit(
                      color: isGroup ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onIndividualTap,
              child: Container(
                decoration: BoxDecoration(
                  color: !isGroup ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Center(
                  child: Text(
                    'Individual',
                    style: GoogleFonts.outfit(
                      color: !isGroup ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
}

/// Input field dengan label floating untuk AddProjectScreen.
class LabeledInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final VoidCallback? onTap;
  final int lines;
  final Color bgColor;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.onTap,
    this.lines = 1,
    this.bgColor = const Color(0xFFF1F8F9),
  });

  @override
  Widget build(BuildContext context) => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: lines == 1 ? 52 : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            maxLines: lines,
            readOnly: onTap != null,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
              suffixIcon: icon != null
                  ? Icon(icon, color: Colors.grey[400])
                  : null,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -10,
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
}

/// Section upload file di AddProjectScreen.
class FileUploadSection extends StatelessWidget {
  const FileUploadSection({super.key});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
        borderRadius: BorderRadius.circular(25),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_rounded,
            color: AppColors.primaryTeal,
            size: 45,
          ),
          const SizedBox(height: 10),
          Text(
            'Upload your file here',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse',
            style: GoogleFonts.outfit(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// AddTaskTopBar — Header navigasi layar "Add Task" (back + judul "Add Task").
// Diekstrak dari AddProjectScreen agar header bersifat const dan tidak di-rebuild.
// ─────────────────────────────────────────────────────────────────────────────
class AddTaskTopBar extends StatelessWidget {
  const AddTaskTopBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(25, 55, 25, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'Add Task',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// AddTaskGroupDropdown — Dropdown pemilih grup dengan floating label.
// Diekstrak dari AddProjectScreen untuk isolasi rebuild saat grup dipilih.
// ─────────────────────────────────────────────────────────────────────────────
class AddTaskGroupDropdown extends StatelessWidget {
  final List<dynamic> userGroups;
  final dynamic selectedGroup;
  final ValueChanged<dynamic> onChanged;
  final Color bgColor;

  const AddTaskGroupDropdown({
    super.key,
    required this.userGroups,
    required this.selectedGroup,
    required this.onChanged,
    this.bgColor = const Color(0xFFF1F8F9),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedGroup?['id'] as String?,
              hint: Text('Select a group', style: GoogleFonts.outfit(color: Colors.grey[400])),
              icon: Icon(Icons.expand_more, color: Colors.grey[300]),
              items: userGroups
                  .map((g) => g as Map<String, dynamic>)
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['id'] as String,
                      child: Text(
                        e['name'] ?? '',
                        style: GoogleFonts.outfit(color: Colors.black),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onChanged(userGroups.firstWhere((g) => g['id'] == v));
                }
              },
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -10,
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Grup',
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IndependentTaskDetailHeader — Header navigasi layar detail tugas mandiri.
// Diekstrak agar header bersifat const dan tidak ikut di-rebuild saat progress
// atau subtask berubah di bawah.
// ─────────────────────────────────────────────────────────────────────────────
class IndependentTaskDetailHeader extends StatelessWidget {
  const IndependentTaskDetailHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
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
              const Text(
                'Independent\nTask',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                  height: 1.1,
                ),
              ),
            ],
          ),
          Image.asset(
            'assets/images/independent_task.png',
            height: 100,
            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
          ),
        ],
      ),
    );
}
