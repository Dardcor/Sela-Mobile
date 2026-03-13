import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/dashboard_widgets.dart';

/// Semua rendering UI didelegasikan ke [dashboard_widgets.dart]:
/// - [DashboardHeader]        → avatar + statistik task (rebuild saat data berubah)
/// - [DashboardSearchBar]     → search bar (rebuild terisolasi dari list)
/// - [DashboardSectionHeader] → judul seksi + "See all"
/// - [GroupTaskCard]          → kartu tugas grup (rebuild terisolasi per item)
/// - [IndependentTaskItem]    → item tugas mandiri (rebuild terisolasi per item)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  static Map<String, dynamic>? _cachedProfile;
  static List<dynamic>? _cachedGroups;
  static List<dynamic>? _cachedIndependent;
  
  // Realtime subscription
  RealtimeChannel? _profileSubscription;

  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _profileSubscription = supabase
        .channel('public:profiles:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: user.id,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _cachedProfile = payload.newRecord;
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_profileSubscription != null) {
      supabase.removeChannel(_profileSubscription!);
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      List groupTasksList = [];
      try {
        final gData = await supabase
            .from('tasks')
            .select('*, groups(id, name, course_name, class_name, group_number), subtasks(*, subtask_progress(*))')
            .eq('is_group', true)
            .order('created_at', ascending: false);
        groupTasksList = gData as List;

        final groupIds = groupTasksList
            .map((t) => t['group_id'])
            .where((id) => id != null)
            .toSet()
            .toList();

        if (groupIds.isNotEmpty) {
          final membersData = await supabase
              .from('group_members')
              .select('group_id, profiles(*)')
              .inFilter('group_id', groupIds);

          final membersByGroup = <String, List>{};
          for (final m in membersData as List) {
            final gid = m['group_id'] as String;
            membersByGroup.putIfAbsent(gid, () => []).add(m);
          }

          groupTasksList = groupTasksList.map((task) {
            final gid = task['group_id'] as String?;
            return {
              ...Map<String, dynamic>.from(task),
              '_members': gid != null ? (membersByGroup[gid] ?? []) : [],
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('Group tasks fetch err: $e');
      }

      final independentData = await supabase
          .from('tasks')
          .select('*, subtasks(*, subtask_progress(*))')
          .eq('is_group', false)
          .eq('created_by', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cachedProfile = profileData;
          _cachedGroups = groupTasksList;
          _cachedIndependent = independentData as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Err Dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateProgress(dynamic task) {
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) return 0.0;
    final subtasks = task['subtasks'] as List;
    double totalProgress = 0;
    for (var st in subtasks) {
      final progressList = st['subtask_progress'] as List? ?? [];
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
    if (_isLoading && _cachedProfile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      );
    }

    final groups = _cachedGroups ?? [];
    final independent = _cachedIndependent ?? [];

    final allTasksCount = groups.length + independent.length;
    final doneTasksCount = groups.where((t) => t['status'] == 'Done').length +
        independent.where((t) => t['status'] == 'Done').length;
    final inProgressCount = groups.where((t) => t['status'] == 'In Progress').length +
        independent.where((t) => t['status'] == 'In Progress').length;
    final upcomingCount = groups.where((t) => t['status'] == 'Upcoming').length +
        independent.where((t) => t['status'] == 'Upcoming').length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.primaryTeal,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ✅ Header diisolasi — rebuild hanya saat profil/stats berubah
                SliverToBoxAdapter(
                  child: DashboardHeader(
                    profile: _cachedProfile,
                    allTasksCount: allTasksCount,
                    doneTasksCount: doneTasksCount,
                    inProgressCount: inProgressCount,
                    upcomingCount: upcomingCount,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // ✅ Search bar diisolasi — rebuild hanya saat input berubah
                SliverToBoxAdapter(child: DashboardSearchBar(controller: _searchCtrl)),
                const SliverToBoxAdapter(child: SizedBox(height: 25)),
                // ✅ Header seksi diisolasi — const-friendly, rebuild hanya saat navigasi
                SliverToBoxAdapter(
                  child: DashboardSectionHeader(
                    title: 'Group Task',
                    onSeeAll: () => Navigator.pushNamed(context, '/work_in_group')
                        .then((_) => _fetchData()),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 15)),
                SliverToBoxAdapter(child: _buildWorkInGroupList()),
                const SliverToBoxAdapter(child: SizedBox(height: 25)),
                SliverToBoxAdapter(
                  child: DashboardSectionHeader(
                    title: 'Independent Task',
                    onSeeAll: () => Navigator.pushNamed(context, '/independent_task')
                        .then((_) => _fetchData()),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 15)),
                _buildIndependentTaskListSliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          AppBottomNavBar(
            currentIndex: 0,
            onAddTap: () => Navigator.pushNamed(context, '/add_project').then((_) => _fetchData()),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkInGroupList() {
    if (_cachedGroups == null || _cachedGroups!.isEmpty) {
      return Container(
        height: 130,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            Text('No group tasks yet', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('Create a group & add tasks first', style: TextStyle(color: Colors.grey[300], fontSize: 11)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 25),
        physics: const BouncingScrollPhysics(),
        itemCount: _cachedGroups!.length,
        // ✅ Setiap kartu adalah widget terpisah — rebuild terisolasi per item
        itemBuilder: (context, index) => GroupTaskCard(
          task: _cachedGroups![index],
          progress: _calculateProgress(_cachedGroups![index]),
          onTap: () => Navigator.pushNamed(context, '/work_in_group_detail', arguments: _cachedGroups![index]),
        ),
      ),
    );
  }

  Widget _buildIndependentTaskListSliver() {
    if (_cachedIndependent == null || _cachedIndependent!.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Container(
            height: 80,
            alignment: Alignment.center,
            child: Text(
              'No independent tasks yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          // ✅ Setiap item adalah widget terpisah — rebuild terisolasi per item
          (context, index) => IndependentTaskItem(
            task: _cachedIndependent![index],
            onTap: () => Navigator.pushNamed(context, '/independent_task_detail', arguments: _cachedIndependent![index]),
          ),
          childCount: _cachedIndependent!.length,
        ),
      ),
    );
  }
}
