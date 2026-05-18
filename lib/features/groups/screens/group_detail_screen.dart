import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/ai_task_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/network_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../widgets/group_widgets.dart';
import '../widgets/file_link_dialog.dart';

/// GroupDetailScreen — Kerangka layar detail tugas grup.
///
/// File ini hanya berisi logika kalkulasi progress dan pengambilan data,
/// lalu mendelegasikan rendering ke komponen di [group_widgets.dart]:
/// - [GroupDetailHeader]       → header navigasi (const)
/// - [GroupMainCard]           → kartu info task utama
/// - [GroupProgressSection]    → daftar subtask + progress bar
/// - [GroupMemberSection]      → daftar anggota dengan ExpansionTile
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final apiClient = ApiClient();

  final Set<Completer<bool>> _pendingDeletes = {};

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final userDataStr = prefs.getString('user_data');
        if (userDataStr != null) {
          final userData = jsonDecode(userDataStr);
          _currentUserId = userData['id'] ?? '';
        } else {
          _currentUserId = '';
        }
      });
    }
  }

  Future<void> _forceExecutePendingDeletes() async {
    if (_pendingDeletes.isEmpty) return;
    for (var completer in _pendingDeletes) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _pendingDeletes.clear();
    ScaffoldMessenger.of(context).clearSnackBars();
    await Future.delayed(const Duration(milliseconds: 300));
  }
  dynamic _taskData;
  List<Map<String, dynamic>> _taskFiles = [];
  bool _isLoading = true;
  String _currentUserId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initUserId();
    if (_taskData == null) {
      final initialTask = ModalRoute.of(context)!.settings.arguments as dynamic;
      _fetchFullTaskData(initialTask['id']);
    }
  }

  Future<void> _fetchFullTaskData(String taskId) async {
    await _forceExecutePendingDeletes();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];

      final response = await apiClient.dio.get('/tasks/$taskId/detail/$userId');
      final data = Map<String, dynamic>.from(response.data['task'] ?? response.data);
      final extraData = response.data;
      final files =
          (extraData['files'] as List?)
              ?.map(
                (f) => {
                  'name': f['file_name'],
                  'path': f['file_path'],
                  'type': f['file_type'],
                  'size': f['file_size'],
                },
              )
              .toList() ??
          [];

      final links = extraData['links'] ?? [];
      
      final subtasks = extraData['subtasks'] ?? [];
      
      final groupMembers = extraData['members_progress'] ?? [];

      if (mounted) {
        setState(() {
          _taskData = {
            ...data,
            'task_links': links,
            'task_files': files,
            'subtasks': subtasks,
            'group_members': groupMembers,
            'current_user_is_leader': groupMembers.any((m) => m['id'] == userId && m['role'] == 'leader'),
          };
          _taskFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch full task data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
    String? assignedTo,
    String description,
  ) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Silakan masukkan judul tugas'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    if (assignedTo == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Silakan pilih anggota yang akan ditugaskan'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final taskId = _taskData['id'];
      await apiClient.dio.post('/tasks/$taskId/subtasks', data: {
        'title': title,
        'description': description,
        'user_id': assignedTo,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Tugas anggota berhasil dibuat'),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          String errorMessage = 'Failed to create subtask: ${e.toString()}';
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreateAutomatic() async {
    final members = (_taskData['group_members'] as List?) ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Tidak ada anggota dalam grup'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final taskTitle = _taskData['title'] ?? 'Task';
      final taskDescription = _taskData['description'] ?? '';

      // Collect links
      final List<String> taskLinks = (_taskData['task_links'] as List?)
              ?.map((l) => l['url']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      // Collect files names
      final List<String> taskFiles = (_taskData['task_files'] as List?)
              ?.map((f) => f['file_name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];
      final rawDocs = _taskData['task_files'] as List? ?? [];
      final List<DataPart> fileParts = [];
      
      for (final file in rawDocs) {
        final path = file['file_path']?.toString() ?? '';
        final type = file['file_type']?.toString().toLowerCase() ?? '';
        final name = file['file_name']?.toString().toLowerCase() ?? '';
        
        if (path.isNotEmpty && (type.contains('pdf') || name.endsWith('pdf'))) {
          try {
            if (path.startsWith('http')) {
              final response = await Dio().get(
                path,
                options: Options(responseType: ResponseType.bytes),
              );
              final bytes = response.data as List<int>;
              fileParts.add(DataPart('application/pdf', Uint8List.fromList(bytes)));
            }
          } catch (e) {
            debugPrint("Failed to download or parse PDF automatically: ${e}");
          }
        }
      }
      final List<dynamic> membersWithAbilities = [];
      for (final m in members) {
        final userMap = m as Map<String, dynamic>? ?? {};
        final profile = userMap['profiles'] ?? userMap;
        final userId = profile['id']?.toString() ?? '';
        List<String> abilities = [];
        if (userId.isNotEmpty) {
          try {
            final abilitiesResponse = await apiClient.dio.get('/users/$userId/abilities');
            final abilitiesData = abilitiesResponse.data['data'] ?? abilitiesResponse.data;
            abilities = (abilitiesData as List)
                .map((a) => a['ability']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          } catch (_) {
          }
        }
        membersWithAbilities.add({
          ...userMap,
          'abilities': abilities,
        });
      }

      final dividedTasks = await AutomaticTaskDivision.divideTask(
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        members: membersWithAbilities,
        links: taskLinks,
        files: taskFiles,
        fileParts: fileParts,
      );

      for (var sub in dividedTasks) {
        await apiClient.dio.post('/tasks/${_taskData['id']}/subtasks', data: {
          'title': sub['title'],
          'description': sub['description'] ?? '',
          'user_id': sub['user_id'],
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Pembagian tugas otomatis berhasil dibuat'),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
      }
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          String errorMessage = 'Gagal membagi tugas secara otomatis. Server AI sedang sibuk, silakan coba beberapa saat lagi.';
          
          if (e is DioException && e.response?.statusCode == 500) {
             errorMessage = 'Gagal menyimpan tugas. Terjadi masalah pada server. Silakan coba lagi nanti.';
          } else if (e.toString().contains('Server AI')) {
             errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteSubtask(String subtaskId) async {
    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        showNoInternetSnackBar(context);
      }
      return;
    }

    final subtasksList = _taskData['subtasks'] as List?;
    if (subtasksList == null) return;
    
    final subtaskIndex = subtasksList.indexWhere((st) => st['id'] == subtaskId);
    if (subtaskIndex == -1) return;
    
    final subtaskData = subtasksList[subtaskIndex];
    
    // Optimistic update
    setState(() {
      subtasksList.removeAt(subtaskIndex);
    });

    bool isUndone = false;
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);

    if (mounted) {
      showUndoSnackBar(context, 'Subtask berhasil dihapus', () {
        isUndone = true;
        if (!completer.isCompleted) completer.complete(true);
        if (mounted) {
          setState(() {
            subtasksList.insert(subtaskIndex, subtaskData);
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 10), () => false),
      completer.future,
    ]);
    
    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    try {
      // Hapus subtask
      await apiClient.dio.delete('/subtasks/$subtaskId');
      await _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text('Gagal menghapus subtask: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
        }
        await _fetchFullTaskData(_taskData['id']);
      }
    }
  }

  Future<void> _handleStatusChanged(String subtaskId, int progress) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr == null) return;
    final userData = jsonDecode(userDataStr);
    final userId = userData['id'];
    if (userId == null) return;
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
      await apiClient.dio.patch('/subtasks/$subtaskId/progress', data: {
        'progress': progress,
        'user_id': userId,
      });

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
              content: Text('Gagal memperbarui status: ${e.toString()}'),
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
              content: Text('Gagal membuka pratinjau file'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (_) {
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
    if (_taskData == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: AppColors.primaryTeal)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load task data',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kembali', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
        ),
      );
    }

    final task = _taskData;
    final progress = _calculateProgress(task);
    final members = (task['group_members'] as List?) ?? [];
    final subtasks = (task['subtasks'] as List?) ?? [];
    final currentUserId = _currentUserId;
    final isLeader = _taskData['current_user_is_leader'] == true;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: () => _fetchFullTaskData(task['id']),
        color: AppColors.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GroupDetailHeader(),
              const SizedBox(height: 10),
              GroupMainCard(
                task: task,
                progress: progress,
                taskFiles: _taskFiles,
                onFileTap: _handleFileTap,
                onEditTap: isLeader ? _showFileLinkDialog : null,
              ),
              const SizedBox(height: 25),
              CreateSubtaskSection(
                members: members,
                isLeader: isLeader,
                isLoading: _isLoading,
                onCreateManual: _handleCreateManual,
                onCreateAutomatic: _handleCreateAutomatic,
              ),
              const SizedBox(height: 25),
              YourProgressSection(
                taskTitle: task['title'] ?? '',
                subtasks: subtasks,
                userId: currentUserId,
                onStatusChanged: _handleStatusChanged,
              ),
              const SizedBox(height: 25),
              GroupMemberSection(
                members: members,
                subtasks: subtasks,
                createdBy: task['created_by'] ?? '',
                isLeader: isLeader,
                onDeleteSubtask: isLeader ? _handleDeleteSubtask : null,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
