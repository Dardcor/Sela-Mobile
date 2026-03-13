import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/task_progress_indicator.dart';
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
          .select('*, groups(*), subtasks(*, subtask_progress(*, profiles(*))), task_links(*)')
          .eq('id', taskId)
          .single();

      // Fetch group members separately to get member list for dropdown
      final groupId = data['group_id'];
      final membersData = await supabase
          .from('group_members')
          .select('*, profiles(*)')
          .eq('group_id', groupId);

      if (mounted) {
        setState(() {
          _taskData = {
            ...data,
            'group_members': membersData,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateProgress(dynamic task) {
    if (task == null || task['subtasks'] == null || (task['subtasks'] as List).isEmpty) return 0.0;
    final subtasks = task['subtasks'] as List;
    double total = 0;
    for (var st in subtasks) {
      final pl = st['subtask_progress'] as List? ?? [];
      if (pl.isNotEmpty) {
        total += pl
                .map((p) => (p['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            pl.length;
      }
    }
    return (total / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  Future<void> _handleCreateManual(String title, String? assignedTo, String description) async {
    if (title.isEmpty || assignedTo == null) return;
    
    try {
      final st = await supabase.from('subtasks').insert({
        'task_id': _taskData['id'],
        'title': title,
      }).select().single();

      await supabase.from('subtask_progress').insert({
        'subtask_id': st['id'],
        'user_id': assignedTo,
        'progress': 0,
      });

      _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      // error handle
    }
  }

  Future<void> _handleCreateAutomatic() async {
    // Basic automatic division: distribute subtasks evenly
    // For now, let's just add a sample "Auto Task" to each member
    final members = _taskData['group_members'] as List;
    if (members.isEmpty) return;

    try {
      for (int i = 0; i < members.length; i++) {
        final st = await supabase.from('subtasks').insert({
          'task_id': _taskData['id'],
          'title': 'Auto Task ${i + 1}',
        }).select().single();

        await supabase.from('subtask_progress').insert({
          'subtask_id': st['id'],
          'user_id': members[i]['profiles']['id'],
          'progress': 0,
        });
      }
      _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      // error handle
    }
  }

  Future<void> _handleStatusChanged(String subtaskId, int progress) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('subtask_progress').upsert({
        'subtask_id': subtaskId,
        'user_id': user.id,
        'progress': progress,
      });
      _fetchFullTaskData(_taskData['id']);
    } catch (e) {
      // error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_taskData == null && _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)));
    }

    final task = _taskData;
    final progress = _calculateProgress(task);
    final members = (task['group_members'] as List?) ?? [];
    final subtasks = (task['subtasks'] as List?) ?? [];
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GroupDetailHeader(),
            const SizedBox(height: 10),
            GroupMainCard(task: task, progress: progress),
            const SizedBox(height: 25),
            // ✅ New Create Subtask Section (Gambar 1 & 2)
            CreateSubtaskSection(
              members: members,
              onCreateManual: _handleCreateManual,
              onCreateAutomatic: _handleCreateAutomatic,
            ),
            const SizedBox(height: 25),
            // ✅ Your Progres (Gambar 1)
            YourProgressSection(
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
    );
  }
}

