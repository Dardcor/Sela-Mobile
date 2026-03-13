import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../widgets/task_detail_widgets.dart';

/// AddProjectScreen — Kerangka layar tambah tugas (grup/individual).
///
/// File ini mengelola form state dan proses penyimpanan ke Supabase.
/// Rendering UI didelegasikan ke komponen di [task_detail_widgets.dart]:
/// - [AddTaskTopBar]         → header navigasi (const, tidak di-rebuild)
/// - [TaskTypeToggle]        → toggle Grup/Individual (rebuild saat toggle berubah)
/// - [LabeledInputField]     → field input dengan floating label
/// - [AddTaskGroupDropdown]  → dropdown pilih grup (rebuild saat grup dipilih)
/// - [FileUploadSection]     → section upload file (const, statis)
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
  final linkCtrl = TextEditingController();

  List<dynamic> userGroups = [];
  dynamic selectedGroup;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    dateCtrl.dispose();
    descCtrl.dispose();
    linkCtrl.dispose();
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
      await supabase.from('tasks').insert({
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'due_date': dateCtrl.text.isNotEmpty
            ? DateFormat('MM/dd/yyyy').parse(dateCtrl.text).toIso8601String()
            : null,
        'link': linkCtrl.text,
        'is_group': isGroup,
        'group_id': isGroup ? selectedGroup['id'] : null,
        'created_by': supabase.auth.currentUser!.id,
      });
      if (mounted) {
        setState(() => isLoading = false);
        // ✅ Menggunakan SuccessDialog reusable dari shared_widgets
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ✅ Header navigasi — const, tidak pernah di-rebuild
                const AddTaskTopBar(),
                const SizedBox(height: 30),
                // ✅ Toggle Grup/Individual — rebuild hanya saat toggle berubah
                TaskTypeToggle(
                  isGroup: isGroup,
                  onGroupTap: () => setState(() => isGroup = true),
                  onIndividualTap: () => setState(() => isGroup = false),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      // ✅ Field dengan floating label dari local widgets
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
                      if (isGroup) ...[
                        // ✅ Dropdown grup diisolasi — rebuild hanya saat grup dipilih
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: LabeledInputField(
                              label: 'Link',
                              hint: 'Enter a link',
                              controller: linkCtrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 12,
                              ),
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
                                'Add',
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
                      const SizedBox(height: 25),
                      // ✅ Upload section — const, tidak pernah di-rebuild
                      const FileUploadSection(),
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
              ],
            ),
          ),
          const AppBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }
}
