import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../widgets/task_detail_widgets.dart';

/// AddProjectScreen — Kerangka layar tambah tugas (grup/individual).
///
/// Mendukung:
/// - Multiple links (disimpan ke tabel task_links)
/// - Upload file (PDF, Word, Excel, PPT, Gambar) ke Supabase storage
class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final supabase = Supabase.instance.client;
  bool isGroup = true;
  final titleCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Multiple links
  List<String> _links = [];

  // Multiple files
  List<PlatformFile> _files = [];

  List<dynamic> userGroups = [];
  dynamic selectedGroup;
  bool isLoading = false;
  final PageController pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    pageController.dispose();
    titleCtrl.dispose();
    dateCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    final res = await supabase
        .from('groups')
        .select('*, group_members!inner(user_id)')
        .eq('group_members.user_id', supabase.auth.currentUser!.id);
    if (mounted) setState(() => userGroups = res);
  }

  Future<void> _save() async {
    if (titleCtrl.text.isEmpty) return;
    if (isGroup && selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group')),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      // 1. Simpan task ke tabel tasks
      final taskRes = await supabase.from('tasks').insert({
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'due_date': dateCtrl.text.isNotEmpty
            ? DateFormat('MM/dd/yyyy').parse(dateCtrl.text).toIso8601String()
            : null,
        'is_group': isGroup,
        'group_id': isGroup ? selectedGroup['id'] : null,
        'created_by': supabase.auth.currentUser!.id,
      }).select().single();

      final taskId = taskRes['id'] as String;

      // 2. Simpan multiple links ke tabel task_links
      for (final link in _links) {
        if (link.trim().isNotEmpty) {
          await supabase.from('task_links').insert({
            'task_id': taskId,
            'url': link.trim(),
          });
        }
      }

      // 3. Upload files ke Supabase storage bucket "task-files"
      for (final file in _files) {
        if (file.bytes != null) {
          final path = '$taskId/${file.name}';
          await supabase.storage
              .from('task-files')
              .uploadBinary(path, file.bytes!);
        }
      }

      if (mounted) {
        setState(() => isLoading = false);
        SuccessDialog.show(
          context,
          message: 'Task successfully added',
          onOk: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Header navigasi — const, tidak pernah di-rebuild
              const AddTaskTopBar(),
              const SizedBox(height: 30),
              // Toggle Grup/Individual
              TaskTypeToggle(
                isGroup: isGroup,
                onGroupTap: () {
                  if (!isGroup) {
                    pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
                onIndividualTap: () {
                  if (isGroup) {
                    pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
              ),
              const SizedBox(height: 30),
              Expanded(
                child: PageView(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      isGroup = index == 0;
                    });
                  },
                  children: [
                    _buildForm(true),
                    _buildForm(false),
                  ],
                ),
              ),
            ],
          ),
          const AppBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildForm(bool forGroup) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 15),
            LabeledInputField(
              label: 'Title',
              hint: 'Enter a task title',
              controller: titleCtrl,
            ),
            const SizedBox(height: 25),
            LabeledInputField(
              label: 'Due Date',
              hint: 'mm/dd/yyyy',
              controller: dateCtrl,
              icon: Icons.calendar_today_rounded,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  dateCtrl.text = DateFormat('MM/dd/yyyy').format(d);
                }
              },
            ),
            const SizedBox(height: 25),
            if (forGroup) ...[
              AddTaskGroupDropdown(
                userGroups: userGroups,
                selectedGroup: selectedGroup,
                onChanged: (v) => setState(() => selectedGroup = v),
              ),
              const SizedBox(height: 25),
            ],
            LabeledInputField(
              label: 'Description',
              hint: 'Description',
              controller: descCtrl,
              lines: 4,
            ),
            const SizedBox(height: 30),
            // Divider "Support"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Support',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            // ✅ Multi-link section — link muncul di atas kolom input
            LinkListSection(
              links: _links,
              onLinksChanged: (updated) => setState(() => _links = updated),
            ),
            const SizedBox(height: 25),
            // ✅ Upload file section — hanya PDF, Word, Excel, PPT, Gambar
            FileUploadSection(
              files: _files,
              onFilesChanged: (updated) => setState(() => _files = updated),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
