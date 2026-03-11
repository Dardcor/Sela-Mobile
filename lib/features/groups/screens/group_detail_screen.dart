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

  /// Kalkulasi rata-rata progress dari semua subtask.
  double _calculateProgress(dynamic task) {
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) return 0.0;
    final subtasks = task['subtasks'] as List;
    double total = 0;
    for (var st in subtasks) {
      final pl = st['subtask_progress'] as List;
      if (pl.isNotEmpty) {
        total += pl
                .map((p) => (p['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            pl.length;
      }
    }
    return (total / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  /// Hapus anggota dari grup dan refresh layar.
  Future<void> _deleteMember(dynamic memberId) async {
    await supabase.from('group_members').delete().eq('id', memberId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final task = ModalRoute.of(context)!.settings.arguments as dynamic;
    final progress = _calculateProgress(task);
    final members = (task['group_members'] as List?) ?? [];
    final subtasks = (task['subtasks'] as List?) ?? [];
    final createdBy = task['created_by'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header navigasi — const, tidak pernah di-rebuild
            const GroupDetailHeader(),
            const SizedBox(height: 20),
            // ✅ Kartu utama task — rebuild hanya saat task/progress berubah
            GroupMainCard(task: task, progress: progress),
            const SizedBox(height: 25),
            // ✅ Section progress subtask — rebuild hanya saat subtasks berubah
            GroupProgressSection(title: 'Your Progres', subtasks: subtasks),
            const SizedBox(height: 25),
            // ✅ Section member — rebuild hanya saat daftar anggota berubah
            GroupMemberSection(
              members: members,
              subtasks: subtasks,
              createdBy: createdBy,
              onDeleteMember: _deleteMember,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
