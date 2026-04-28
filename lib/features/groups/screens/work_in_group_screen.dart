import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/search_bar_with_button.dart';
import '../widgets/group_widgets.dart';
import '../../tasks/widgets/task_cards.dart';

/// WorkInGroupScreen â€” Kerangka layar daftar tugas grup.
///
/// File ini mengelola pengambilan data, filtering pencarian, dan kalkulasi
/// progress, lalu mendelegasikan rendering UI ke komponen di [group_widgets.dart]
/// dan [task_cards.dart]:
/// - [WorkInGroupHeader]   â†’ header navigasi (const, tidak di-rebuild)
/// - [SearchBarWithButton] â†’ search bar dari shared_widgets
/// - [WorkGroupTaskCard]   â†’ kartu per tugas grup (rebuild terisolasi per item)
class WorkInGroupScreen extends StatefulWidget {
  const WorkInGroupScreen({super.key});

  @override
  State<WorkInGroupScreen> createState() => _WorkInGroupScreenState();
}

class _WorkInGroupScreenState extends State<WorkInGroupScreen> {
  final apiClient = ApiClient();
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String _currentUserId = '';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];
      
      final resTasks = await apiClient.dio.get('/tasks/user/$userId');
      final allTasks = resTasks.data['tasks'] as List? ?? [];
      
      final groupTasksList = allTasks.where((t) => t['is_group'] == true).toList();

      if (mounted) {
        setState(() {
          _tasks = groupTasksList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Err fetching tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateProgress(dynamic task) {
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) {
      return 0.0;
    }

    final subtasks = task['subtasks'] as List;
    double totalProgress = 0;
    for (var st in subtasks) {
      final pl = st['subtask_progress'] as List? ?? [];
      if (pl.isNotEmpty) {
        totalProgress +=
            pl
                .map((p) => (p['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            pl.length;
      }
    }
    return (totalProgress / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  List<dynamic> get _filteredTasks => _searchQuery.isEmpty
      ? _tasks
      : _tasks
            .where(
              (t) => (t['title'] ?? '').toLowerCase().contains(_searchQuery),
            )
            .toList();

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgLight,
    body: Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchTasks,
          color: AppColors.primaryTeal,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // âœ… Header diisolasi â€” const, tidak pernah di-rebuild
              const SliverToBoxAdapter(child: WorkInGroupHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // âœ… SearchBarWithButton dari shared_widgets
              SliverToBoxAdapter(
                child: SearchBarWithButton(controller: _searchCtrl),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 25)),
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    )
                  : _buildTaskListSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        AppBottomNavBar(
          currentIndex: -1,
          onAddTap: () => Navigator.pushNamed(
            context,
            '/add_project',
          ).then((_) => _fetchTasks()),
        ),
      ],
    ),
  );

  Widget _buildTaskListSliver() {
    if (_filteredTasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: Colors.grey[300],
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'No group tasks yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task using the + button',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final t = _filteredTasks[index];
          final progress = _calculateProgress(t);
          final members = (t['members'] as List? ?? []); // The backend already attaches 'members' array

          String detailInfo = '';
          if (t['start_date'] != null && t['due_date'] != null) {
            final start = DateTime.parse(t['start_date']);
            final due = DateTime.parse(t['due_date']);
            detailInfo = '${_fmtDate(start)} – ${_fmtDate(due)}';
          }
          final parts = [
            t['class_name'],
            t['course_name'],
          ].where((x) => x != null && (x?.toString() ?? '').isNotEmpty).toList();
          
          if (parts.isNotEmpty) {
            detailInfo += '${detailInfo.isNotEmpty ? ' | ' : ''}${parts.join(' | ')}';
          }

          // ✅ WorkGroupTaskCard dari local widgets — rebuild terisolasi per item
          return WorkGroupTaskCard(
            task: t,
            progress: progress,
            detailInfo: detailInfo,
            members: members,
            onDetailTap: () => Navigator.pushNamed(
              context,
              '/work_in_group_detail',
              arguments: t,
            ).then((_) => _fetchTasks()),
          );
        }, childCount: _filteredTasks.length),
      ),
    );
  }
}
