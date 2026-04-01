import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/task_detail_widgets.dart';

class IndependentTaskDetailScreen extends StatefulWidget {
  const IndependentTaskDetailScreen({super.key});

  @override
  State<IndependentTaskDetailScreen> createState() =>
      _IndependentTaskDetailScreenState();
}

class _IndependentTaskDetailScreenState
    extends State<IndependentTaskDetailScreen> {
  final supabase = Supabase.instance.client;
  dynamic _taskData;
  List<Map<String, dynamic>> _taskFiles = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_taskData == null) {
      final initialTask = ModalRoute.of(context)!.settings.arguments as dynamic;
      _fetchFullTaskData(initialTask['id']);
    }
  }

  Future<void> _fetchFullTaskData(String taskId) async {
    try {
      final data = await supabase
          .from('tasks')
          .select(
            '*, subtasks(*, subtask_progress(*, profiles(*))), task_links(*), task_files(*)',
          )
          .eq('id', taskId)
          .single();

      // Data task_files yang otomatis terambil dari relasi database
      final files =
          (data['task_files'] as List?)
              ?.map(
                (f) => {
                  'name': f['file_name'],
                  'path': f['file_path'],
                  'type': f['file_type'],
                },
              )
              .toList()
              .cast<Map<String, dynamic>>() ??
          [];

      if (mounted) {
        setState(() {
          _taskData = data;
          _taskFiles = files;
          _isLoading = false;
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isCreating = false;
        });
    }
  }

  double _calculateProgress(dynamic task) {
    if (task == null ||
        task['subtasks'] == null ||
        (task['subtasks'] as List).isEmpty)
      return 0.0;
    final subtasks = task['subtasks'] as List;
    double total = 0;
    for (var st in subtasks) {
      final pl = st['subtask_progress'] as List? ?? [];
      if (pl.isNotEmpty) {
        total +=
            pl
                .map((p) => (p['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            pl.length;
      }
    }
    return (total / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  Future<void> _handleCreateManual(
    String title,
    String? _,
    String description,
  ) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Please enter a subtask title'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final st = await supabase
          .from('subtasks')
          .insert({
            'task_id': _taskData['id'],
            'title': title,
            'description': description,
          })
          .select()
          .single();

      await supabase.from('subtask_progress').insert({
        'subtask_id': st['id'],
        'user_id': user.id,
        'progress': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Subtask created successfully'),
              backgroundColor: Colors.green,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleCreateAutomatic() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final st = await supabase
          .from('subtasks')
          .insert({
            'task_id': _taskData['id'],
            'title': 'Auto Task 1',
            'description': 'Automatically generated task',
          })
          .select()
          .single();

      await supabase.from('subtask_progress').insert({
        'subtask_id': st['id'],
        'user_id': user.id,
        'progress': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Subtask created automatically'),
              backgroundColor: Colors.green,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleStatusChanged(String subtaskId, int progress) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // --- OPTIMISTIC UI UPDATE: Ubah status secara instan tanpa menunggu database ---
    setState(() {
      if (_taskData != null && _taskData['subtasks'] != null) {
        for (var st in _taskData['subtasks']) {
          if (st['id'] == subtaskId) {
            final progressList = st['subtask_progress'] as List?;
            if (progressList != null) {
              for (var p in progressList) {
                if (p['user_id'] == user.id) {
                  p['progress'] = progress;
                  break;
                }
              }
            }
            break;
          }
        }
      }
    });

    try {
      await supabase
          .from('subtask_progress')
          .update({'progress': progress})
          .eq('subtask_id', subtaskId)
          .eq('user_id', user.id);

      // Ambil data lagi di background tanpa menghalangi UI
      _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      // Jika gagal, revert ke data aslinya
      _fetchFullTaskData(_taskData['id']);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('Failed to update status: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  Future<void> _handleFileTap(Map<String, dynamic> file) async {
    final path = (file['path'] as String?)?.trim() ?? '';
    if (path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('File path is missing'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    try {
      final signedUrl = await supabase.storage
          .from('task-files')
          .createSignedUrl(path, 300);
      final uri = Uri.tryParse(signedUrl);

      if (uri == null) {
        throw Exception('Invalid preview URL');
      }

      var opened = false;
      try {
        opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        opened = false;
      }

      if (!opened) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Failed to open file preview'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Failed to open file preview'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_taskData == null && _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    final task = _taskData;
    final progress = _calculateProgress(task);
    final subtasks = (task['subtasks'] as List?) ?? [];
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetchFullTaskData(task['id']),
            color: AppColors.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IndependentTaskDetailHeader(),
                  const SizedBox(height: 10),
                  TaskDetailCard(
                    task: task,
                    progress: progress,
                    taskFiles: _taskFiles,
                    onFileTap: _handleFileTap,
                  ),
                  const SizedBox(height: 25),
                  IndependentCreateSubtaskSection(
                    isLoading: _isCreating,
                    onCreateManual: _handleCreateManual,
                    onCreateAutomatic: _handleCreateAutomatic,
                  ),
                  const SizedBox(height: 25),
                  TaskProgressCard(
                    taskTitle: task['title'] ?? '',
                    subtasks: subtasks,
                    userId: currentUserId,
                    onStatusChanged: _handleStatusChanged,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          const AppBottomNavBar(currentIndex: -1),
        ],
      ),
    );
  }
}
