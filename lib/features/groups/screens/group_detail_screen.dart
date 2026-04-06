import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../model/automatic.dart';
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
  final supabase = Supabase.instance.client;
  dynamic _taskData;
  List<Map<String, dynamic>> _taskFiles = [];
  bool _isLoading = true;

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
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tasks')
          .select(
            '*, groups(*), subtasks(*, subtask_progress(*, profiles(*))), task_links(*), task_files(*)',
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
                  'size': f['file_size'],
                },
              )
              .toList() ??
          [];

      // Fetch group members separately to get member list for dropdown
      final groupId = data['group_id'];
      List membersData = [];
      bool isLeaderFromDb = false;

      if (groupId != null) {
        membersData = await supabase
            .from('group_members')
            .select('*, profiles(*)')
            .eq('group_id', groupId);

        // Cek secara langsung dari DB apakah user ini adalah leader di grup ini
        final leaderCheck = await supabase
            .from('group_members')
            .select('role')
            .eq('group_id', groupId)
            .eq('user_id', user.id)
            .maybeSingle();

        isLeaderFromDb =
            leaderCheck != null && leaderCheck['role'] == 'leader';
      }

      if (mounted) {
        setState(() {
          _taskData = {
            ...data,
            'group_members': membersData,
            'current_user_is_leader': isLeaderFromDb,
          };
          _taskFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Err GroupDetail fetch: $e');
      if (mounted) setState(() => _isLoading = false);
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
    String? assignedTo,
    String description,
  ) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Please enter subtask title'),
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
            content: Text('Please select a member'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    setState(() => _isLoading = true);
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
        'user_id': assignedTo,
        'progress': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Subtask created successfully'),
              backgroundColor: AppColors.primaryTeal,
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
              content: Text('Failed to create subtask: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
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

    setState(() => _isLoading = true);
    try {
      final taskTitle = _taskData['title'] ?? 'Task';
      final taskDescription = _taskData['description'] ?? '';

      // Collect links
      final List<String> taskLinks = (_taskData['task_links'] as List?)
              ?.map((l) => l['url'] as String)
              .toList() ??
          [];

      // Collect files
      final List<String> taskFiles = (_taskData['task_files'] as List?)
              ?.map((f) => f['file_name'] as String)
              .toList() ??
          [];

      // Fetch abilities untuk setiap anggota dari profile_abilities
      final List<dynamic> membersWithAbilities = [];
      for (final m in members) {
        final profile = m['profiles'] ?? {};
        final userId = profile['id'] ?? '';
        List<String> abilities = [];
        if (userId.isNotEmpty) {
          try {
            final abilitiesData = await supabase
                .from('profile_abilities')
                .select('ability')
                .eq('user_id', userId);
            abilities = (abilitiesData as List)
                .map((a) => a['ability'] as String)
                .toList();
          } catch (_) {
            // Jika gagal fetch abilities, lanjut dengan list kosong
          }
        }
        membersWithAbilities.add({
          ...Map<String, dynamic>.from(m as Map),
          'abilities': abilities,
        });
      }

      final dividedTasks = await AutomaticTaskDivision.divideTask(
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        members: membersWithAbilities,
        links: taskLinks,
        files: taskFiles,
      );

      for (var sub in dividedTasks) {
        final st = await supabase
            .from('subtasks')
            .insert({
              'task_id': _taskData['id'],
              'title': sub['title'],
              'description': sub['description'] ?? '',
            })
            .select()
            .single();

        await supabase.from('subtask_progress').insert({
          'subtask_id': st['id'],
          'user_id': sub['user_id'],
          'progress': 0,
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
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 3000),
              content: Text('Server is busy try again later'),
              backgroundColor: Colors.red,
            ),
          );
        setState(() => _isLoading = false);
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
                      child: const Text('Go Back', style: TextStyle(color: Colors.white)),
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
    final currentUserId = supabase.auth.currentUser?.id ?? '';
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
              // ✅ New Create Subtask Section (Gambar 1 & 2)
              CreateSubtaskSection(
                members: members,
                isLeader: isLeader,
                isLoading: _isLoading,
                onCreateManual: _handleCreateManual,
                onCreateAutomatic: _handleCreateAutomatic,
              ),
              const SizedBox(height: 25),
              // ✅ Your Progres (Gambar 1)
              YourProgressSection(
                taskTitle: task['title'] ?? '',
                subtasks: subtasks,
                userId: currentUserId,
                onStatusChanged: _handleStatusChanged,
              ),
              const SizedBox(height: 25),
              // ✅ Member & Progres (Gambar 1)
              GroupMemberSection(
                members: members,
                subtasks: subtasks,
                createdBy: task['created_by'] ?? '',
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
