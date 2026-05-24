import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';

class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }
    return newValue;
  }
}

/// Kartu detail tugas mandiri — bagian atas (info task + progress besar).
/// Diekstrak agar jika progress berubah, hanya kartu ini yang di-rebuild.
class TaskDetailCard extends StatefulWidget {
  final dynamic task;
  final double progress;
  final List<Map<String, dynamic>> taskFiles;
  final ValueChanged<Map<String, dynamic>>? onFileTap;
  final VoidCallback? onEditTap;

  const TaskDetailCard({
    super.key,
    required this.task,
    required this.progress,
    this.taskFiles = const [],
    this.onFileTap,
    this.onEditTap,
  });

  @override
  State<TaskDetailCard> createState() => _TaskDetailCardState();
}

class _TaskDetailCardState extends State<TaskDetailCard> {
  bool _isDescExpanded = false;
  static const int _descThreshold = 120;

  String _formatDateShort(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]}';
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

  String _displayFileType(Map<String, dynamic> file) {
    final rawType = (file['type'] as String?)?.trim().toLowerCase() ?? '';
    if (rawType.isNotEmpty) {
      if (rawType.contains('pdf')) return 'pdf';
      if (rawType.startsWith('image/')) {
        return rawType.split('/').last.split('+').first.split(';').first;
      }
      if (rawType.contains('word')) return 'docx';
      if (rawType.contains('spreadsheet') || rawType.contains('excel')) {
        return 'xlsx';
      }
      if (rawType.contains('presentation') || rawType.contains('powerpoint')) {
        return 'pptx';
      }

      return rawType
          .split('/')
          .last
          .split('.')
          .last
          .split('+')
          .first
          .split(';')
          .first;
    }

    final fileName = file['name'] as String? ?? '';
    return fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    String dateRange = '';
    if (task['start_date'] != null && task['due_date'] != null) {
      dateRange =
          '${_formatDateShort(DateTime.parse(task['start_date']))} - ${_formatDateShort(DateTime.parse(task['due_date']))}';
    }
    
    final description = (task['description'] as String?) ?? '';
    final isLongDesc = description.length > _descThreshold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              TaskProgressIndicator(
                progress: widget.progress,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          if (task['category'] != null || task['subject'] != null) ...[
            const SizedBox(height: 5),
            Text(
              [
                task['category'],
                task['subject'],
              ].where((x) => x != null && (x?.toString() ?? '').isNotEmpty).join(' | '),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const SizedBox(height: 10),
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
          ] else ...[
            Text(
              'Tidak ada deskripsi yang tersedia untuk tugas ini.',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 15),
          // Links dari task_links
          if (task['task_links'] != null &&
              (task['task_links'] as List).isNotEmpty)
            ...(task['task_links'] as List).map(
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
                      Icon(
                        Icons.link_rounded,
                        color: Colors.blue[400],
                        size: 14,
                      ),
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
              final ext = _displayFileType(file);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onFileTap == null ? null : () => widget.onFileTap!(file),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
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
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
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
                  dateRange,
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onEditTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onEditTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Edit Tugas',
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

/// Kartu daftar progress/subtask dari tugas mandiri.
/// Diisolasi sehingga hanya bagian ini yang di-rebuild saat data subtask berubah.
class TaskProgressCard extends StatefulWidget {
  final String taskTitle;
  final List subtasks;
  final String userId;
  final Function(String, int) onStatusChanged;

  const TaskProgressCard({
    super.key,
    required this.taskTitle,
    required this.subtasks,
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  State<TaskProgressCard> createState() => _TaskProgressCardState();
}

class _TaskProgressCardState extends State<TaskProgressCard> {
  // Local state untuk optimasi UI
  late Map<String, int> _localProgresses;

  @override
  void initState() {
    super.initState();
    _initLocalProgress();
  }

  @override
  void didUpdateWidget(TaskProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtasks != widget.subtasks) {
      _initLocalProgress();
    }
  }

  void _initLocalProgress() {
    _localProgresses = {};
    for (var st in widget.subtasks) {
      final progressList = st['progress_entries'] as List?;
      final progressData = progressList?.firstWhere(
        (p) => p['user_id'].toString().toLowerCase() == widget.userId.toString().toLowerCase(),
        orElse: () => null,
      );
      _localProgresses[st['id'].toString()] = (progressData?['progress'] as num?)?.toInt() ?? 0;
    }
  }

  void _showDetailDialog(
    BuildContext context,
    String title,
    String description,
  ) {
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
                widget.taskTitle,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          const SizedBox(height: 20),
          if (widget.subtasks.isEmpty)
            Center(
              child: Text(
                'No progress items yet',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ...widget.subtasks.map((st) {
              final subtaskId = st['id'].toString();
              final prog = _localProgresses[subtaskId] ?? 0;

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
                              st['title'] ?? '',
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
                            onTap: () => _showDetailDialog(
                              context,
                              st['title'] ?? '',
                              st['description'] ?? '',
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primaryTeal,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: prog == 100,
                      activeColor: AppColors.primaryTeal,
                      checkColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.primaryTeal,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        final newProg = val == true ? 100 : 0;
                        
                        // 1. Update UI secara instan (Optimistic UI lokal)
                        setState(() {
                          _localProgresses[subtaskId] = newProg;
                        });

                        // 2. Kirim update ke backend tanpa menunggu proses selesai (Fire-and-forget)
                        widget.onStatusChanged(subtaskId, newProg);
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}


class IndependentCreateSubtaskSection extends StatefulWidget {
  final Function(String, String?, String) onCreateManual;
  final VoidCallback onCreateAutomatic;
  final bool isLoading;
  final String aiThinkingText;

  const IndependentCreateSubtaskSection({
    super.key,
    required this.onCreateManual,
    required this.onCreateAutomatic,
    this.isLoading = false,
    this.aiThinkingText = '',
  });

  @override
  State<IndependentCreateSubtaskSection> createState() =>
      _IndependentCreateSubtaskSectionState();
}

class _IndependentCreateSubtaskSectionState
    extends State<IndependentCreateSubtaskSection> {
  final PageController _pageController = PageController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _activeTab = 0;

  void _switchTab(int index) {
    setState(() => _activeTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
          Text(
            'Buat Sub-Tugas',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _IndieTabItem(
                  title: 'Otomatis',
                  active: _activeTab == 0,
                  onTap: () => _switchTab(0),
                ),
                _IndieTabItem(
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
              // Menyesuaikan dengan tinggi masing-masing tab internal seperti di Group Task
              height: _activeTab == 0 ? (widget.isLoading ? 180 : (widget.aiThinkingText.isNotEmpty ? 230 : 115)) : 245,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.antiAlias,
                onPageChanged: (i) => setState(() => _activeTab = i),
                children: [
                  // Automatic Tab
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        if (widget.isLoading || widget.aiThinkingText.isNotEmpty)
                          Container(
                            height: 140,
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.primaryTeal.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.isLoading) ...[
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryTeal,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ] else ...[
                                      const Icon(
                                        Icons.psychology_alt_rounded,
                                        color: AppColors.primaryTeal,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      widget.isLoading ? 'SELA Thinking...' : 'Hasil Pemikiran SELA',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryTeal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.aiThinkingText.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        widget.aiThinkingText,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              '*tugas akan dibagi otomatis sesuai dengan kemampuan Anda',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        if (!widget.isLoading)
                          GestureDetector(
                            onTap: widget.onCreateAutomatic,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.aiThinkingText.isNotEmpty ? 'Buat Ulang dengan AI ✨' : 'Buat dengan AI ✨',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Manual Tab
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _CreateSubtaskField(
                          label: 'Judul sub-tugas',
                          hint: 'Judul sub-tugas',
                          controller: _titleCtrl,
                          inputFormatters: [NoLeadingSpaceFormatter()],
                        ),
                        const SizedBox(height: 20),
                        _CreateSubtaskField(
                          label: 'Description',
                          hint: 'description',
                          controller: _descCtrl,
                          lines: 3,
                          inputFormatters: [NoLeadingSpaceFormatter()],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: widget.isLoading
                              ? null
                              : () {
                                  widget.onCreateManual(
                                    _titleCtrl.text,
                                    null,
                                    _descCtrl.text,
                                  );
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
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}

class _IndieTabItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _IndieTabItem({
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

class _CreateSubtaskField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int lines;
  final List<TextInputFormatter>? inputFormatters;

  const _CreateSubtaskField({
    required this.label,
    required this.hint,
    required this.controller,
    this.lines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            maxLines: lines,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: GoogleFonts.outfit(color: Colors.grey[300]),
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
                  'Grup',
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
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.onTap,
    this.lines = 1,
    this.bgColor = AppColors.bgLight,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: lines == 1 ? 45 : null,
              padding: const EdgeInsets.only(left: 16, right: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hasError ? Colors.red : AppColors.primaryTeal,
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: lines,
                readOnly: onTap != null,
                onTap: onTap,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.only(
                    right: icon == null ? 16 : 0,
                    top: lines > 1 ? 16 : 14, // Adjusted for single line vertical centering
                    bottom: lines > 1 ? 16 : 14, // Adjusted for single line vertical centering
                  ),
                  suffixIcon: icon != null
                      ? Transform.translate(
                          offset: const Offset(4, 0),
                          child: Icon(icon, color: Colors.grey[400]),
                        )
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
                    color: hasError ? Colors.red : AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LinkListSection — Mendukung penambahan banyak link secara dinamis.
// Setiap link yang ditambahkan muncul di atas kolom input.
// ─────────────────────────────────────────────────────────────────────────────
class LinkListSection extends StatefulWidget {
  final List<String> links;
  final Function(List<String>) onLinksChanged;
  final Color? bgColor;

  const LinkListSection({
    super.key,
    required this.links,
    required this.onLinksChanged,
    this.bgColor,
  });

  @override
  State<LinkListSection> createState() => _LinkListSectionState();
}

class _LinkListSectionState extends State<LinkListSection> {
  final _ctrl = TextEditingController();
  String? _error;

  void _addLink() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Link is required');
      return;
    }
    
    final updated = [...widget.links, text];
    widget.onLinksChanged(updated);
    _ctrl.clear();
    if (_error != null) setState(() => _error = null);
  }

  void _removeLink(int index) {
    final updated = List<String>.from(widget.links)..removeAt(index);
    widget.onLinksChanged(updated);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daftar link yang sudah ditambahkan — ditampilkan di atas kolom input
        if (widget.links.isNotEmpty) ...[
          Column(
            children: widget.links.asMap().entries.map((entry) {
              final idx = entry.key;
              final link = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: AppColors.primaryTeal,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeLink(idx),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        // Baris input link + tombol Add
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledInputField(
                label: 'Tautan',
                hint: 'Masukkan tautan (link)',
                controller: _ctrl,
                errorText: _error,
                bgColor: widget.bgColor ?? AppColors.bgLight,
                onChanged: (val) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addLink,
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  'Tambah',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FileUploadSection — Upload file dengan batasan tipe: PDF, Word, Excel, PPT, Gambar.
// Menampilkan daftar file yang sudah diupload dan memungkinkan penghapusan tiap file.
// ─────────────────────────────────────────────────────────────────────────────
class FileUploadSection extends StatefulWidget {
  final List<PlatformFile> files;
  final Function(List<PlatformFile>) onFilesChanged;

  const FileUploadSection({
    super.key,
    required this.files,
    required this.onFilesChanged,
  });

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  static const _allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  IconData _iconForFile(String ext) {
    switch (ext.toLowerCase()) {
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

  Color _colorForFile(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Colors.red[400]!;
      case 'doc':
      case 'docx':
        return Colors.blue[600]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[600]!;
      case 'ppt':
      case 'pptx':
        return Colors.orange[600]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple[400]!;
      default:
        return Colors.grey[500]!;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true, // WAJIB untuk web/mobile jika menggunakan uploadBinary
    );
    if (result == null || result.files.isEmpty) return;
    final updated = [...widget.files, ...result.files];
    widget.onFilesChanged(updated);
  }

  void _removeFile(int index) {
    final updated = List<PlatformFile>.from(widget.files)..removeAt(index);
    widget.onFilesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daftar file yang sudah dipilih
        if (widget.files.isNotEmpty)
          Column(
            children: widget.files.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;
              final ext = (file.extension ?? '').toLowerCase();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForFile(ext),
                      color: _colorForFile(ext),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (file.size > 0)
                            Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeFile(idx),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        // Area drop/pick file
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
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
                  'Unggah file Anda di sini',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF • Word • Excel • PPT • Gambar',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Telusuri',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
    child: Center(
      child: Container(
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
          'Tambah Tugas',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
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
  final String? errorText;

  const AddTaskGroupDropdown({
    super.key,
    required this.userGroups,
    required this.selectedGroup,
    required this.onChanged,
    this.bgColor = AppColors.bgLight,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
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
                  color: hasError ? Colors.red : AppColors.primaryTeal,
                  width: 1.2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<String>(
                    width: constraints.maxWidth,
                    initialSelection: selectedGroup?['id'] as String?,
                    onSelected: (v) {
                      if (v != null) {
                        onChanged(userGroups.firstWhere((g) => g['id'] == v));
                      }
                    },
                    trailingIcon: Transform.translate(
                      offset: const Offset(4, 0),
                      child: Icon(Icons.expand_more_rounded, color: Colors.grey[400]),
                    ),
                    selectedTrailingIcon: Transform.translate(
                      offset: const Offset(4, 0),
                      child: Icon(Icons.expand_less_rounded, color: Colors.grey[400]),
                    ),
                    textStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.only(left: 16, bottom: 8),
                    ),
                    hintText: 'Select a group',
                    dropdownMenuEntries: userGroups
                        .map((g) => g as Map<String, dynamic>)
                        .map(
                          (e) => DropdownMenuEntry<String>(
                            value: e['id'] as String,
                            label: e['name'] ?? '',
                            style: MenuItemButton.styleFrom(
                              textStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
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
                    color: hasError ? Colors.red : AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(color: Colors.white),
    padding: EdgeInsets.fromLTRB(
      25,
      MediaQuery.of(context).padding.top + 5,
      5,
      10,
    ),
    child: Column(
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Independent\nTask',
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                  height: 1.1,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-20, -10),
              child: Image.asset(
                'assets/images/independent_task.png',
                height: 95,
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, s) => const SizedBox(height: 95),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
