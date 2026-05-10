import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';
import '../../tasks/widgets/task_detail_widgets.dart';

/// Kartu grup di GroupScreen yang menampilkan avatar anggota,
/// nama grup, dan tombol detail.
class GroupCard extends StatelessWidget {
  final dynamic team;
  final VoidCallback onDetailTap;

  const GroupCard({super.key, required this.team, required this.onDetailTap});

  @override
  Widget build(BuildContext context) {
    final members = (team['members'] as List?) ?? [];
    final totalMember = team['total_member'] ?? members.length;

    String groupTag = 'Kelompok -';
    if (team['group_number'] != null &&
        team['group_number'].toString().isNotEmpty &&
        team['group_number'].toString() != 'null') {
      groupTag = 'Kelompok ${team['group_number']}';
    } else {
      final gn = team['name']?.toString() ?? '';
      if (gn.toLowerCase().contains('kelompok')) {
        final parts = gn.split(RegExp(r'kelompok', caseSensitive: false));
        if (parts.length > 1) {
          groupTag = 'Kelompok ${parts[1].trim()}';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTag,
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      team['class_name'] ?? team['name'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            team['course_name'] != null &&
                    team['course_name'].toString().isNotEmpty
                ? '$totalMember Member | ${team['course_name']}'
                : '$totalMember Member',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar Stack
              SizedBox(
                width: 100,
                height: 30,
                child: Stack(
                  children: [
                    ...List.generate(
                      min(members.length, 3),
                      (idx) => Positioned(
                        left: idx * 20.0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child:
                                members[idx]['avatar_url'] != null &&
                                    members[idx]['avatar_url']
                                        .toString()
                                        .startsWith('http')
                                ? Image.network(
                                    members[idx]['avatar_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => Image.asset(
                                          'assets/images/default_profile.png',
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                : Image.asset(
                                    'assets/images/default_profile.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (members.length > 3)
                      Positioned(
                        left: 60,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '+${members.length - 3}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Detail',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
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
}

/// Widget section kode undangan/kuliah grup.
class GroupCodeSection extends StatelessWidget {
  final String label;
  final String? code;

  const GroupCodeSection({super.key, required this.label, required this.code});

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
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
            AnimatedCopyButton(textToCopy: code ?? '', isCircle: false),
          ],
        ),
      ],
    );
  }
}

/// Animated copy button that transitions to a checkmark when pressed
class AnimatedCopyButton extends StatefulWidget {
  final String textToCopy;
  final bool isCircle;

  const AnimatedCopyButton({
    super.key,
    required this.textToCopy,
    this.isCircle = false,
  });

  @override
  State<AnimatedCopyButton> createState() => _AnimatedCopyButtonState();
}

class _AnimatedCopyButtonState extends State<AnimatedCopyButton> {
  bool _isCopied = false;

  void _handleCopy() async {
    if (_isCopied) return;

    await Clipboard.setData(ClipboardData(text: widget.textToCopy));

    if (mounted) {
      setState(() => _isCopied = true);
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isCopied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleCopy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: widget.isCircle
            ? const EdgeInsets.all(8)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(12),
          boxShadow: widget.isCircle
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            _isCopied ? Icons.check_rounded : Icons.copy_all_rounded,
            key: ValueKey<bool>(_isCopied),
            color: Colors.white,
            size: widget.isCircle ? 20 : 24,
          ),
        ),
      ),
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
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const GroupInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isNum = false,
    this.bgColor = Colors.white,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasError
                        ? Colors.red
                        : enabled
                        ? AppColors.primaryTeal
                        : Colors.grey[300]!,
                    width: 1.2,
                  ),
                  color: enabled ? Colors.transparent : Colors.grey[50],
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  onChanged: onChanged,
                  keyboardType: isNum
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters:
                      inputFormatters ??
                      (isNum ? [FilteringTextInputFormatter.digitsOnly] : null),
                  style: GoogleFonts.outfit(
                    color: enabled ? Colors.black : Colors.grey,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    hintStyle: GoogleFonts.outfit(
                      color: enabled ? Colors.grey[300] : Colors.grey[200],
                    ),
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
                      color: hasError
                          ? Colors.red
                          : enabled
                          ? AppColors.primaryTeal
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Text(
                errorText!,
                style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dropdown field dengan floating label untuk modal di GroupScreen.
/// Kini mendukung pencarian/search.
class GroupDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final Color bgColor;
  final String? errorText;

  const GroupDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.bgColor = Colors.white,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final validValue = items.contains(value) ? value : null;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 55,
                  padding: const EdgeInsets.only(left: 18, right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: hasError ? Colors.red : AppColors.primaryTeal,
                      width: 1.2,
                    ),
                    color: Colors.transparent,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: validValue,
                      hint: Text(
                        hint,
                        style: GoogleFonts.outfit(
                          color: Colors.grey[700],
                          fontSize: 15,
                        ),
                      ),
                      items: items.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: Colors.grey,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      menuMaxHeight: 250,
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  top: -11,
                  child: Container(
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: hasError ? Colors.red : AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  errorText!,
                  style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YourProgressSection — Daftar subtask milik user yang login.
// ─────────────────────────────────────────────────────────────────────────────
class YourProgressSection extends StatelessWidget {
  final String taskTitle;
  final List subtasks;
  final String userId;
  final Function(String subtaskId, int progress) onStatusChanged;

  const YourProgressSection({
    super.key,
    required this.taskTitle,
    required this.subtasks,
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Filter subtask yang progresnya milik user ini
    final userSubtasks = subtasks.where((st) {
      final progressList = (st['progress_entries'] as List?);
      return progressList?.any(
            (p) =>
                p['user_id'].toString().toLowerCase() ==
                userId.toString().toLowerCase(),
          ) ??
          false;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
            ],
          ),
          const SizedBox(height: 15),
          if (userSubtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No assigned subtasks',
                  style: GoogleFonts.outfit(color: Colors.grey[400]),
                ),
              ),
            )
          else
            ...userSubtasks.map((st) {
              final progressData = (st['progress_entries'] as List?)
                  ?.firstWhere(
                    (p) =>
                        p['user_id'].toString().toLowerCase() ==
                        userId.toString().toLowerCase(),
                    orElse: () => null,
                  );
              final currentProgress =
                  (progressData?['progress'] as num?)?.toInt() ?? 0;

              return _YourSubtaskItem(
                taskTitle: taskTitle,
                title: st['title'] ?? '',
                description: st['description'] ?? '',
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
  final String taskTitle;
  final String title;
  final String description;
  final int progress;
  final Function(int) onChanged;

  const _YourSubtaskItem({
    required this.taskTitle,
    required this.title,
    required this.description,
    required this.progress,
    required this.onChanged,
  });

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                taskTitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail:',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description.isEmpty
                    ? 'No description available for this subtask.'
                    : description,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Close',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showDetailDialog(context),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryTeal,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: progress == 100,
            activeColor: AppColors.primaryTeal,
            checkColor: Colors.white,
            side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) {
              if (val == true) {
                onChanged(100);
              } else {
                onChanged(0);
              }
            },
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        // Garis lurus sesuai permintaan sebelumnya
      ),
      padding: EdgeInsets.fromLTRB(
        25,
        MediaQuery.of(context).padding.top + 5,
        0,
        5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol Kembali
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Group Task', // Berubah dari Work in Group
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              // Ilustrasi sesuai Gambar 2 - Geser sedikit ke kiri dan atas
              Transform.translate(
                offset: const Offset(-30, -10),
                child: Image.asset(
                  'assets/images/group_task.png',
                  height: 85,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 85),
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
// GroupMainCard — Kartu utama info tugas grup (ikon + judul + progress + tanggal).
// Diekstrak agar rebuild hanya terjadi saat data task berubah.
// ─────────────────────────────────────────────────────────────────────────────
class GroupMainCard extends StatefulWidget {
  final dynamic task;
  final double progress;
  final List<Map<String, dynamic>> taskFiles;
  final Function(Map<String, dynamic> file)? onFileTap;
  final VoidCallback? onEditTap;

  const GroupMainCard({
    super.key,
    required this.task,
    required this.progress,
    this.taskFiles = const [],
    this.onFileTap,
    this.onEditTap,
  });

  @override
  State<GroupMainCard> createState() => _GroupMainCardState();
}

class _GroupMainCardState extends State<GroupMainCard> {
  bool _isDescExpanded = false;
  static const int _descThreshold = 120;

  String _formatDate(String? s) {
    if (s == null) return '';
    try {
      final dt = DateTime.parse(s);
      return '${dt.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForFileExt(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _colorForFileExt(String ext) {
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _resolveFileExt(Map<String, dynamic> file, String fileName) {
    final type = (file['type'] as String?)?.trim().toLowerCase() ?? '';
    if (type.isNotEmpty) {
      return type.startsWith('.') ? type.substring(1) : type;
    }
    return fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final links = (task['task_links'] as List?) ?? [];
    final description = (task['description'] as String?) ?? '';
    final isLongDesc = description.length > _descThreshold;

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
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              TaskProgressIndicator(
                progress: widget.progress,
                size: 55,
                strokeWidth: 6,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task['title'] ?? '',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),
          // Description dengan see more / see less
          if (description.isNotEmpty) ...[
            GestureDetector(
              onTap: isLongDesc
                  ? () => setState(() => _isDescExpanded = !_isDescExpanded)
                  : null,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: (!isLongDesc || _isDescExpanded)
                          ? description
                          : '${description.substring(0, _descThreshold)}...',
                    ),
                    if (isLongDesc)
                      TextSpan(
                        text: _isDescExpanded ? ' see less' : ' see more...',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 15),
          // Links
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: InkWell(
                onTap: () async {
                  String urlString = link['url'] ?? '';
                  if (urlString.isEmpty) return;
                  if (!urlString.startsWith('http://') &&
                      !urlString.startsWith('https://')) {
                    urlString = 'https://$urlString';
                  }
                  await launchUrl(
                    Uri.parse(urlString),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: Colors.blue[400], size: 14),
                    const SizedBox(width: 6),
                    Expanded(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Files yang dilampirkan
          if (widget.taskFiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...widget.taskFiles.map((file) {
              final fileName = file['name'] as String? ?? 'file';
              final ext = _resolveFileExt(file, fileName);
              return InkWell(
                onTap: widget.onFileTap == null
                    ? null
                    : () => widget.onFileTap!(file),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForFileExt(ext),
                        color: _colorForFileExt(ext),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${_formatDate(task['start_date'])} - ${_formatDate(task['due_date'])} | ${task['class_name'] ?? ''} | ${task['course_name'] ?? ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onEditTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onEditTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Edit Task',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
  final bool isLeader;
  final bool isLoading;
  final Function(String title, String? assignedTo, String description)
  onCreateManual;
  final VoidCallback onCreateAutomatic;

  const CreateSubtaskSection({
    super.key,
    required this.members,
    required this.isLeader,
    this.isLoading = false,
    required this.onCreateManual,
    required this.onCreateAutomatic,
  });

  @override
  State<CreateSubtaskSection> createState() => _CreateSubtaskSectionState();
}

class _CreateSubtaskSectionState extends State<CreateSubtaskSection> {
  int _activeTab = 0;
  final PageController _pageController = PageController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedMemberId;

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showLeaderOnlySnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1500),
          content: Text('Only group leaders can create subtasks'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _switchTab(int index) {
    setState(() => _activeTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Row(
            children: [
              Text(
                'Create Subtask',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              if (!widget.isLeader) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  'Leader only',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 15),
          // Tab bar — semua user bisa klik untuk pindah tab
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _TabItem(
                  title: 'Automatic',
                  active: _activeTab == 0,
                  onTap: () => _switchTab(0),
                ),
                _TabItem(
                  title: 'Manual',
                  active: _activeTab == 1,
                  onTap: () => _switchTab(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _activeTab == 0 ? 115 : 225,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.antiAlias,
                onPageChanged: (i) => setState(() => _activeTab = i),
                children: [_buildAutomatic(), _buildManual()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatic() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            '*Tasks will be automatically divided among each member evenly according to their abilities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          // Tombol Create — hanya ini yang diblokir untuk member
          GestureDetector(
            onTap: () {
              if (widget.isLoading) return;
              if (widget.isLeader) {
                widget.onCreateAutomatic();
              } else {
                _showLeaderOnlySnackBar();
              }
            },
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
                  if (!widget.isLoading) ...[
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Create',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManual() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: !widget.isLeader ? _showLeaderOnlySnackBar : null,
                  child: GroupInputField(
                    label: 'Subtask title',
                    hint: 'subtask title',
                    controller: _titleCtrl,
                    enabled: widget.isLeader,
                    inputFormatters: [NoLeadingSpaceFormatter()],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: !widget.isLeader ? _showLeaderOnlySnackBar : null,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AbsorbPointer(
                      absorbing: !widget.isLeader,
                      child: _DropdownPerson(
                        label: 'Assign to',
                        hint: 'pick the person',
                        value: _selectedMemberId,
                        members: widget.members,
                        enabled: widget.isLeader,
                        onChanged: widget.isLeader
                            ? (v) => setState(() => _selectedMemberId = v)
                            : (v) {},
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: !widget.isLeader ? _showLeaderOnlySnackBar : null,
            child: GroupInputField(
              label: 'Description',
              hint: 'description',
              controller: _descCtrl,
              enabled: widget.isLeader,
              inputFormatters: [NoLeadingSpaceFormatter()],
            ),
          ),
          const SizedBox(height: 20),
          // Tombol Create
          GestureDetector(
            onTap: () {
              if (widget.isLoading) return;
              if (widget.isLeader) {
                widget.onCreateManual(
                  _titleCtrl.text,
                  _selectedMemberId,
                  _descCtrl.text,
                );
                _titleCtrl.clear();
                _descCtrl.clear();
                setState(() => _selectedMemberId = null);
              } else {
                _showLeaderOnlySnackBar();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primaryTeal : Colors.transparent,
                width: 2.5,
              ),
            ),
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
  final bool enabled;

  const _DropdownPerson({
    required this.label,
    required this.hint,
    required this.value,
    required this.members,
    required this.onChanged,
    this.enabled = true,
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
            border: Border.all(
              color: enabled ? AppColors.primaryTeal : Colors.grey[300]!,
              width: 1.2,
            ),
            color: enabled ? Colors.transparent : Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.outfit(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
              icon: Icon(
                Icons.expand_more_rounded,
                color: enabled ? Colors.grey[300] : Colors.grey[200],
              ),
              items: members.map((m) {
                return DropdownMenuItem<String>(
                  value: m['id'] ?? m['user_id'],
                  child: Text(
                    m['full_name'] ?? m['username'] ?? 'Member',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
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
              style: GoogleFonts.outfit(
                color: enabled ? AppColors.primaryTeal : Colors.grey,
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
// GroupMemberSection — Kartu "Member & Progres" di GroupDetailScreen.
// Diekstrak agar rebuild hanya terjadi saat daftar anggota berubah.
// ─────────────────────────────────────────────────────────────────────────────
class GroupMemberSection extends StatelessWidget {
  final List members;
  final List subtasks;
  final String createdBy;
  final bool isLeader;
  final Function(String subtaskId)? onDeleteSubtask;

  const GroupMemberSection({
    super.key,
    required this.members,
    required this.subtasks,
    required this.createdBy,
    this.isLeader = false,
    this.onDeleteSubtask,
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
            'Member & Progress',
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
              isLeader: isLeader,
              onDeleteSubtask: onDeleteSubtask,
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
  final bool isLeader;
  final Function(String subtaskId)? onDeleteSubtask;

  const GroupMemberProgressTile({
    super.key,
    required this.member,
    required this.allSubtasks,
    this.isLeader = false,
    this.onDeleteSubtask,
  });

  @override
  State<GroupMemberProgressTile> createState() =>
      _GroupMemberProgressTileState();
}

class _GroupMemberProgressTileState extends State<GroupMemberProgressTile> {
  bool _isExpanded = false;

  /// Hitung status aggregat member berdasarkan subtask-nya.
  ({String text, Color color}) _computeMemberStatus(
    List userSubtasks,
    String userId,
  ) {
    if (userSubtasks.isEmpty) {
      return (text: 'No Task', color: Colors.grey);
    }

    int doneCount = 0;
    int inProgressCount = 0;
    for (var st in userSubtasks) {
      final progressData = (st['progress_entries'] as List?)?.firstWhere(
        (p) =>
            p['user_id'].toString().toLowerCase() ==
            userId.toString().toLowerCase(),
        orElse: () => null,
      );
      final progress = (progressData?['progress'] as num?)?.toInt() ?? 0;
      if (progress >= 100) {
        doneCount++;
      } else if (progress > 0) {
        inProgressCount++;
      }
    }

    if (doneCount == userSubtasks.length) {
      return (text: 'Done', color: AppColors.primaryTeal);
    } else if (inProgressCount > 0 || doneCount > 0) {
      return (text: 'In Progress', color: AppColors.accentTeal);
    }
    return (text: 'Pending', color: AppColors.lightTeal);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String subtaskId,
    String subtaskTitle,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Subtask',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$subtaskTitle"?',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteSubtask?.call(subtaskId);
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.member['id'];

    final userSubtasks = widget.allSubtasks.where((st) {
      final progress = (st['progress_entries'] as List?);
      return progress?.any((p) => p['user_id'] == userId) ?? false;
    }).toList();

    final memberStatus = _computeMemberStatus(userSubtasks, userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isExpanded ? AppColors.lightTeal : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: _isExpanded
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (val) => setState(() => _isExpanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isExpanded
                    ? Colors.white
                    : AppColors.primaryTeal.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.member['avatar_url'] != null &&
                      widget.member['avatar_url'].toString().isNotEmpty
                  ? NetworkImage(widget.member['avatar_url']) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  widget.member['full_name'] ??
                      widget.member['username'] ??
                      'Member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isExpanded ? Colors.white : AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isExpanded
                      ? Colors.white.withOpacity(0.2)
                      : memberStatus.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memberStatus.text,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isExpanded ? Colors.white : memberStatus.color,
                  ),
                ),
              ),
            ],
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
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: userSubtasks.map((st) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            st['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (widget.isLeader && widget.onDeleteSubtask != null)
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(
                              context,
                              st['id'],
                              st['title'] ?? '',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        // Lengkungan dihapus, sekarang garis lurus
      ),
      padding: EdgeInsets.fromLTRB(
        25,
        MediaQuery.of(context).padding.top + 5,
        0,
        5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol Kembali
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
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              // Gambar digeser lebih ke kiri (offset -30)
              Transform.translate(
                offset: const Offset(-30, -10),
                child: Image.asset(
                  'assets/images/group_task.png',
                  height: 85,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
