import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/task_detail_widgets.dart';

/// IndependentTaskDetailScreen — Kerangka layar detail tugas mandiri.
///
/// File ini hanya berisi logika kalkulasi progress, lalu mendelegasikan
/// rendering ke komponen di [task_detail_widgets.dart]:
/// - [IndependentTaskDetailHeader] → header navigasi (const, tidak di-rebuild)
/// - [TaskDetailCard]              → kartu info task (rebuild saat task/progress berubah)
/// - [TaskProgressCard]            → daftar subtask/progress (rebuild saat subtasks berubah)
class IndependentTaskDetailScreen extends StatefulWidget {
  const IndependentTaskDetailScreen({super.key});

  @override
  State<IndependentTaskDetailScreen> createState() =>
      _IndependentTaskDetailScreenState();
}

class _IndependentTaskDetailScreenState
    extends State<IndependentTaskDetailScreen> {

  /// Kalkulasi rata-rata progress dari semua subtask.
  double _calculateProgress(dynamic task) {
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) {
      return 0.0;
    }
    final subtasks = task['subtasks'] as List;
    double totalProgress = 0;
    for (var st in subtasks) {
      final progressList = st['subtask_progress'] as List;
      if (progressList.isNotEmpty) {
        double stAvg = progressList
            .map((p) => (p['progress'] as num).toDouble())
            .reduce((a, b) => a + b) / progressList.length;
        totalProgress += stAvg;
      }
    }
    return (totalProgress / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final task = ModalRoute.of(context)!.settings.arguments as dynamic;
    final progress = _calculateProgress(task);
    final subtasks = (task['subtasks'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header navigasi — const, tidak pernah di-rebuild
                const IndependentTaskDetailHeader(),
                const SizedBox(height: 20),
                // ✅ Kartu detail diisolasi — rebuild hanya saat task berubah
                TaskDetailCard(task: task, progress: progress),
                const SizedBox(height: 25),
                // ✅ Kartu progress diisolasi — rebuild hanya saat subtasks berubah
                TaskProgressCard(subtasks: subtasks),
                const SizedBox(height: 120),
              ],
            ),
          ),
          const AppBottomNavBar(currentIndex: -1),
        ],
      ),
    );
  }
}
