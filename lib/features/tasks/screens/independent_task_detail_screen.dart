import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/network_utils.dart';
import '../widgets/task_detail_widgets.dart';
import '../../groups/widgets/file_link_dialog.dart';
import '../../../core/services/ai_task_service.dart';

class IndependentTaskDetailScreen extends StatefulWidget {
  const IndependentTaskDetailScreen({super.key});

  @override
  State<IndependentTaskDetailScreen> createState() =>
      _IndependentTaskDetailScreenState();
}

class _IndependentTaskDetailScreenState
    extends State<IndependentTaskDetailScreen> {
  dynamic _taskData;
  List<Map<String, dynamic>> _taskFiles = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String _aiThinkingText = '';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      if (mounted) {
        setState(() {
          _userId = userData['id'].toString();
        });
      }
    }
  }

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
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];

      final response = await ApiClient().dio.get('/tasks/$taskId/detail/$userId');
      final data = response.data['task'] ?? response.data;
      final extraData = response.data;
      final files =
          (extraData['files'] as List?)
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

      final links = extraData['links'] ?? [];
      final subtasks = extraData['subtasks'] ?? [];

      if (mounted) {
        setState(() {
          _taskData = {
            ...data,
            'task_links': links,
            'task_files': files,
            'subtasks': subtasks,
          };
          _taskFiles = files;
          _isLoading = false;
          _isCreating = false;
        });
      }
    } catch (e) {
      debugPrint('Failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCreating = false;
        });
      }
    }
  }

  double _calculateProgress(dynamic task) {
    if (task == null ||
        task['subtasks'] == null ||
        (task['subtasks'] as List).isEmpty) {
      return 0.0;
    }
    final subtasks = task['subtasks'] as List;
    double total = 0;
    for (var st in subtasks) {
      final pl = st['progress_entries'] as List? ?? [];
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
            content: Text('Silakan masukkan judul sub-tugas'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    if (_userId == null) return;
    final userId = _userId!;

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() => _isCreating = true);
    try {
      final taskId = _taskData['id'];
      await ApiClient().dio.post('/tasks/$taskId/subtasks', data: {
        'title': title,
        'description': description,
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Sub-tugas berhasil dibuat'),
              backgroundColor: Colors.green,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed: ${e.toString()}';
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
        }
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleCreateAutomatic() async {
    if (_userId == null) return;
    final userId = _userId!;

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() {
      _isCreating = true;
      _aiThinkingText = '';
    });
    try {
      final taskTitle = _taskData['title'] ?? 'Task';
      final taskDescription = _taskData['description'] ?? '';

      // Collect links
      final List<String> taskLinks =
          (_taskData['task_links'] as List?)
              ?.map((l) => l['url']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      // Collect files
      final List<String> taskFiles =
          (_taskData['task_files'] as List?)
              ?.map((f) => f['file_name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];
      List<String> userAbilities = [];
      try {
        final abilitiesResponse = await ApiClient().dio.get(
          '/profile_abilities',
          queryParameters: {'user_id': userId},
        );
        final abilitiesData = abilitiesResponse.data;
        userAbilities = (abilitiesData as List)
            .map((a) => a['ability']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } catch (_) {
      }

      final arrangedTasks = await AutomaticTaskDivision.arrangeIndependentTask(
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        userId: userId,
        links: taskLinks,
        files: taskFiles,
        abilities: userAbilities,
        onStream: (text) {
          if (mounted) {
            setState(() {
              _aiThinkingText = text;
            });
          }
        },
      );

      for (var sub in arrangedTasks) {
        await ApiClient().dio.post('/tasks/${_taskData['id']}/subtasks', data: {
          'title': sub['title'],
          'description': sub['description'] ?? '',
          'user_id': userId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Susunan tugas otomatis berhasil dibuat'),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal menyusun tugas secara otomatis. Server AI sedang sibuk, silakan coba beberapa saat lagi.';
        
        if (e is DioException && e.response?.statusCode == 500) {
           errorMessage = 'Gagal menyimpan tugas. Terjadi masalah pada server. Silakan coba lagi nanti.';
        } else if (e.toString().contains('Server AI')) {
           errorMessage = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('VALIDATION_ERROR:')) {
           errorMessage = e.toString().split('VALIDATION_ERROR:').last.trim();
        }

        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 3000),
                content: Text(errorMessage),
                backgroundColor: Colors.red.shade700,
              ),
            );
        }
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleStatusChanged(String subtaskId, int progress) async {
    if (_userId == null) return;
    final userId = _userId!;
    setState(() {
      if (_taskData != null && _taskData['subtasks'] != null) {
        for (var st in _taskData['subtasks']) {
          if (st['id'] == subtaskId) {
            final progressList = st['progress_entries'] as List?;
            if (progressList != null) {
              for (var p in progressList) {
                if (p['user_id'].toString().toLowerCase() == userId.toString().toLowerCase()) {
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
      await ApiClient().dio.patch('/subtasks/$subtaskId/progress', data: {
        'progress': progress,
        'user_id': userId,
      });

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
            content: Text('Lokasi file tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    try {
      final uri = Uri.tryParse(path);

      if (uri == null) {
        throw Exception('Invalid URL');
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
              content: Text('Gagal membuka pratinjau file'),
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

  void _showFileLinkDialog() {
    if (_taskData == null) return;
    showDialog(
      context: context,
      builder: (context) => FileLinkDialog(
        taskId: _taskData['id'],
        currentTask: _taskData,
        currentLinks: _taskData['task_links'] ?? [],
        currentFiles: _taskFiles,
        onRefresh: () {
          _fetchFullTaskData(_taskData['id']);
        },
      ),
    );
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
    final currentUserId = _userId ?? '';

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
                    onEditTap: _showFileLinkDialog,
                  ),
                  const SizedBox(height: 25),
                  IndependentCreateSubtaskSection(
                    isLoading: _isCreating,
                    aiThinkingText: _aiThinkingText,
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
