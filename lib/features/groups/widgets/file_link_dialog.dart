import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
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
  final _supabase = Supabase.instance.client;
  
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  
  List<String> _links = [];
  List<PlatformFile> _files = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.currentTask['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.currentTask['description'] ?? '');
    
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
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (_titleCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Update Title and Description in tasks table
      await _supabase.from('tasks').update({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
      }).eq('id', widget.taskId);

      // 2. Sync Links
      // Delete old links
      await _supabase.from('task_links').delete().eq('task_id', widget.taskId);
      // Insert new/kept links
      for (final link in _links) {
        if (link.trim().isNotEmpty) {
          await _supabase.from('task_links').insert({
            'task_id': widget.taskId,
            'url': link.trim(),
          });
        }
      }

      // 3. Sync Files
      // Get IDs and paths of existing files to compare
      final existingFilePaths = widget.currentFiles.map((f) => f['path'] as String).toList();
      final keptFilePaths = _files.where((f) => f.path != null && f.path!.startsWith('${widget.taskId}/')).map((f) => f.path!).toList();
      
      // Determine which files to delete
      final filesToDelete = existingFilePaths.where((path) => !keptFilePaths.contains(path)).toList();
      for (final path in filesToDelete) {
        await _supabase.storage.from('task-files').remove([path]);
        await _supabase.from('task_files').delete().eq('file_path', path);
      }

      // Upload new files
      final newFiles = _files.where((f) => f.path == null || !f.path!.startsWith('${widget.taskId}/')).toList();
      for (final file in newFiles) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = '${widget.taskId}/$fileName';
        bool uploadSuccess = false;

        if (file.bytes != null) {
          await _supabase.storage.from('task-files').uploadBinary(path, file.bytes!);
          uploadSuccess = true;
        } else if (file.path != null) {
          await _supabase.storage.from('task-files').upload(path, File(file.path!));
          uploadSuccess = true;
        }

        if (uploadSuccess) {
           await _supabase.from('task_files').insert({
            'task_id': widget.taskId,
            'file_name': file.name,
            'file_path': path,
            'file_type': file.extension,
            'file_size': file.size,
            'uploaded_by': _supabase.auth.currentUser!.id,
          });
        }
      }

      widget.onRefresh();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
