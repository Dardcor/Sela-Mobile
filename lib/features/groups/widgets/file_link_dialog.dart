import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/network_utils.dart';
import '../../tasks/widgets/task_detail_widgets.dart';

class FileLinkDialog extends StatefulWidget {
  final String taskId;
  final dynamic currentTask;
  final List<dynamic> currentLinks;
  final List<dynamic> currentFiles;
  final VoidCallback onRefresh;

  const FileLinkDialog({
    super.key,
    required this.taskId,
    required this.currentTask,
    required this.currentLinks,
    required this.currentFiles,
    required this.onRefresh,
  });

  @override
  State<FileLinkDialog> createState() => _FileLinkDialogState();
}

class _FileLinkDialogState extends State<FileLinkDialog> {
  final apiClient = ApiClient();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _dateCtrl;
  
  List<String> _links = [];
  List<PlatformFile> _files = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.currentTask['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.currentTask['description'] ?? '');
    
    // Convert existing due_date
    String dateText = '';
    if (widget.currentTask['due_date'] != null) {
      try {
        final d = DateTime.parse(widget.currentTask['due_date']);
        dateText = DateFormat('MM/dd/yyyy').format(d);
      } catch (_) {}
    }
    _dateCtrl = TextEditingController(text: dateText);
    
    // Convert existing links
    _links = widget.currentLinks.map((l) => l['url'] as String).toList();
    
    // Convert existing files to PlatformFile representation
    _files = widget.currentFiles.map<PlatformFile>((f) {
      return PlatformFile(
        name: f['name'] ?? 'file',
        size: f['size'] ?? 0,
        path: f['path'], // Using path to store Supabase path for existing files
      );
    }).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (_titleCtrl.text.isEmpty) return;

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Update Title, Description, and Due Date in tasks table
      final updateData = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
      };
      
      if (_dateCtrl.text.isNotEmpty) {
        try {
          updateData['due_date'] = DateFormat('MM/dd/yyyy').parse(_dateCtrl.text).toIso8601String();
        } catch (_) {}
      }

      await apiClient.dio.put('/tasks/${widget.taskId}', data: updateData);

      // 2. Sync Links
      // Delete old links
      await apiClient.dio.delete('/tasks/${widget.taskId}/links');
      // Insert new/kept links
      for (final rawLink in _links) {
        if (rawLink.trim().isNotEmpty) {
          String finalUrl = rawLink.trim();
          if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
            finalUrl = 'https://$finalUrl';
          }
          await apiClient.dio.post('/tasks/${widget.taskId}/links', data: {
            'task_id': widget.taskId,
            'url': finalUrl,
          });
        }
      }

      // 3. Sync Files
      // Get IDs and paths of existing files to compare
      final existingFilePaths = widget.currentFiles.map((f) => f['path'] as String).toList();
      final keptFilePaths = _files
          .where((f) => f.path != null && existingFilePaths.contains(f.path))
          .map((f) => f.path!)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      String uploadedById = '';
      if (userStr != null) {
        final userData = jsonDecode(userStr);
        uploadedById = userData['id']?.toString() ?? '';
      }
      
      // Determine which files to delete
      final filesToDelete = existingFilePaths.where((path) => !keptFilePaths.contains(path)).toList();
      for (final path in filesToDelete) {
        await apiClient.dio.delete('/upload/task-file', data: {'path': path});
        // Let API handle db deletion
      }

      // Upload new files
      final newFiles = _files.where((f) => f.path == null || !existingFilePaths.contains(f.path)).toList();
      for (final file in newFiles) {
        bool uploadSuccess = false;
        String? serverFileUrl;

        if (file.bytes != null) {
          final formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
          });
          final response = await apiClient.dio.post('/upload/task-file', data: formData);
          if (response.statusCode == 200) {
            serverFileUrl = response.data['url'];
            uploadSuccess = true;
          }
        } else if (file.path != null) {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.path!, filename: file.name),
          });
          final response = await apiClient.dio.post('/upload/task-file', data: formData);
          if (response.statusCode == 200) {
            serverFileUrl = response.data['url'];
            uploadSuccess = true;
          }
        }

        if (uploadSuccess && serverFileUrl != null) {
           await apiClient.dio.post('/tasks/${widget.taskId}/files', data: {
            'task_id': widget.taskId,
            'file_name': file.name,
            'file_path': serverFileUrl,
            'file_type': file.extension,
            'file_size': file.size,
            'uploaded_by': uploadedById,
          });
        }
      }

      widget.onRefresh();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diperbarui'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          String errorMessage = 'Error updating task: $e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Task',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Colors.black12),
            
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledInputField(
                      label: 'Title',
                      hint: 'Enter a task title',
                      controller: _titleCtrl,
                      bgColor: Colors.white,
                      inputFormatters: [NoLeadingSpaceFormatter()],
                    ),
                    const SizedBox(height: 10),
                    LabeledInputField(
                      label: 'Due Date',
                      hint: 'mm/dd/yyyy',
                      controller: _dateCtrl,
                      icon: Icons.calendar_month_rounded,
                      bgColor: Colors.white,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          _dateCtrl.text = DateFormat('MM/dd/yyyy').format(d);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    LabeledInputField(
                      label: 'Description',
                      hint: 'Description',
                      controller: _descCtrl,
                      lines: 4,
                      bgColor: Colors.white,
                      inputFormatters: [NoLeadingSpaceFormatter()],
                    ),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 5),
                    LinkListSection(
                      links: _links,
                      onLinksChanged: (updated) => setState(() => _links = updated),
                      bgColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    FileUploadSection(
                      files: _files,
                      onFilesChanged: (updated) => setState(() => _files = updated),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Update',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
