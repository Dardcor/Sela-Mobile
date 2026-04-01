import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../widgets/group_widgets.dart';

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
                },
              )
              .toList() ??
          [];

      // Fetch group members separately to get member list for dropdown
      final groupId = data['group_id'];
      final membersData = await supabase
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

      final isLeaderFromDb =
          leaderCheck != null && leaderCheck['role'] == 'leader';

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
              content: Text('Failed to create subtask: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreateAutomatic() async {
    final members = _taskData['group_members'] as List;
    if (members.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('No members in group'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    setState(() => _isLoading = true);
    try {
      for (int i = 0; i < members.length; i++) {
        final st = await supabase
            .from('subtasks')
            .insert({'task_id': _taskData['id'], 'title': 'Auto Task ${i + 1}'})
            .select()
            .single();

        await supabase.from('subtask_progress').insert({
          'subtask_id': st['id'],
          'user_id': members[i]['profiles']['id'],
          'progress': 0,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Subtasks created automatically'),
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
