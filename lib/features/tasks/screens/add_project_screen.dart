import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../../../core/services/connectivity_service.dart';
import '../../auth/utils/auth_error_utils.dart';
import '../widgets/task_detail_widgets.dart';

/// AddProjectScreen — Kerangka layar tambah tugas (grup/individual).
///
/// Mendukung:
/// - Multiple links (disimpan ke tabel task_links)
/// - Upload file via ApiClient
class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  bool isGroup = true;
  final titleCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Error states
  String? titleError;
  String? dateError;
  String? descError;
  String? groupError;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user_data') ?? '{}');
      final userId = userData['id'];

      final res = await ApiClient().dio.get('/groups/user/$userId');

      if (mounted) {
        setState(() {
          final allGroups = res.data['groups'] ?? res.data['data'] ?? res.data;
          userGroups = (allGroups as List).where((g) => g['role'] == 'leader').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching groups: $e');
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      titleError = null;
      dateError = null;
      descError = null;
      groupError = null;
    });

    bool hasError = false;

    if (titleCtrl.text.isEmpty) {
      titleError = 'Title is required';
      hasError = true;
    }
    if (dateCtrl.text.isEmpty) {
      dateError = 'Due Date is required';
      hasError = true;
    }
    if (descCtrl.text.isEmpty) {
      descError = 'Description is required';
      hasError = true;
    }
    if (isGroup && selectedGroup == null) {
      groupError = 'Please select a group';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user_data') ?? '{}');
      final userId = userData['id'];

      // 1. Simpan task ke tabel tasks via API
      final taskRes = await ApiClient().dio.post('/tasks', data: {
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'due_date': dateCtrl.text.isNotEmpty
            ? DateFormat('MM/dd/yyyy').parse(dateCtrl.text).toIso8601String()
            : null,
        'is_group': isGroup,
        'group_id': isGroup ? selectedGroup['id'] : null,
        'created_by': userId,
        'category': userData['class_name'] ?? null,
      });

      final taskId = taskRes.data['data']['id'].toString();

      // 2. Simpan multiple links ke tabel task_links via API
      for (final link in _links) {
        if (link.trim().isNotEmpty) {
          // If the link doesn't have http/https, we add it to pass URL validation
          String url = link.trim();
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }
          await ApiClient().dio.post('/tasks/$taskId/links', data: {
            'url': url,
          });
        }
      }

      // 3. Upload files via API
      for (final file in _files) {
        final formData = FormData.fromMap({
          'file': file.bytes != null
              ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
              : await MultipartFile.fromFile(file.path!, filename: file.name),
        });

        final uploadRes = await ApiClient().dio.post('/upload/task-file', data: formData);
        
        if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
            await ApiClient().dio.post('/tasks/$taskId/files', data: {
                'file_name': file.name,
                'file_path': uploadRes.data['url'],
                'file_type': file.extension ?? '',
                'file_size': file.size ?? 0,
            });
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
      if (isNetworkErrorMessage(e.toString())) {
        if (mounted) {
          showNoInternetSnackBar(context);
        }
      } else {
        String errorMessage = 'Error: $e';
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text(errorMessage),
              ),
            );
        }
      }
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
                    pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onIndividualTap: () {
                  if (isGroup) {
                    pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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
                      titleError = null;
                      dateError = null;
                      descError = null;
                      groupError = null;
                    });
                  },
                  children: [_buildForm(true), _buildForm(false)],
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
      key: ValueKey(forGroup),
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
              errorText: titleError,
              inputFormatters: [NoLeadingSpaceFormatter()],
              onChanged: (val) {
                if (titleError != null) setState(() => titleError = null);
              },
            ),
            const SizedBox(height: 25),
            LabeledInputField(
              label: 'Due Date',
              hint: 'mm/dd/yyyy',
              controller: dateCtrl,
              icon: Icons.calendar_month_rounded,
              errorText: dateError,
              onTap: () async {
                if (dateError != null) setState(() => dateError = null);
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
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
                errorText: groupError,
                onChanged: (v) {
                  if (groupError != null) setState(() => groupError = null);
                  setState(() => selectedGroup = v);
                },
              ),
              const SizedBox(height: 25),
            ],
            LabeledInputField(
              label: 'Description',
              hint: 'Description',
              controller: descCtrl,
              lines: 4,
              errorText: descError,
              inputFormatters: [NoLeadingSpaceFormatter()],
              onChanged: (val) {
                if (descError != null) setState(() => descError = null);
              },
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
                  disabledBackgroundColor: AppColors.primaryTeal,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create',
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
