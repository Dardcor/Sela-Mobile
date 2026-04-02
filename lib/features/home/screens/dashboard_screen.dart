import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
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
  Map<String, dynamic>? _cachedProfile;
  List<dynamic>? _cachedGroups;
  List<dynamic>? _cachedIndependent;

  // Realtime channel
  RealtimeChannel? _realtimeChannel;

  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // Rebuild with filtered lists
  }

  void _setupRealtimeListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // ✅ Single Channel untuk semua perubahan database
    _realtimeChannel = supabase.channel('dashboard-db-changes-${user.id}');

    // 1. Listen Profile changes
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: user.id,
      ),
      callback: (payload) {
        debugPrint('Realtime: Profile updated!');
        if (mounted) {
          setState(() => _cachedProfile = payload.newRecord);
        }
      },
    );

    // 2. Listen Tasks changes (INSERT/UPDATE/DELETE)
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      callback: (payload) {
        debugPrint(
          'Realtime: Task changed (${payload.eventType})! Refreshing...',
        );
        _fetchData();
      },
    );

    // 3. Listen Subtasks changes
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'subtasks',
      callback: (payload) {
        debugPrint('Realtime: Subtask changed! Refreshing...');
        _fetchData();
      },
    );

    // 4. Listen Notifications changes
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (payload) {
        debugPrint('Realtime: Notifications updated!');
        _fetchNotificationsCount();
      },
    );

    _realtimeChannel!.subscribe((status, [error]) {
      debugPrint('Realtime Status: $status');
      if (error != null) debugPrint('Realtime Error: $error');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchContent(), _fetchNotificationsCount()]);
  }

  Future<void> _fetchNotificationsCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = res.count;
        });
      }
    } catch (e) {
      debugPrint('Err Notifications Count: $e');
    }
  }

  Future<void> _fetchContent() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      debugPrint('Dashboard: Profile fetch done for ${user.id}');

      List groupTasksList = [];
      try {
        final gData = await supabase
            .from('tasks')
            .select(
              '*, groups(id, name, course_name, class_name, group_number), subtasks(*, subtask_progress(*))',
            )
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
      } catch (e, stack) {
        debugPrint('Group tasks fetch err: $e');
        debugPrint(stack.toString());
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
        debugPrint(
          'Dashboard: Successfully loaded ${_cachedGroups?.length} group tasks and ${_cachedIndependent?.length} independent tasks',
        );
      }
    } catch (e) {
      debugPrint('Err Dashboard: $e');
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
      final progressList = st['subtask_progress'] as List? ?? [];
      if (progressList.isNotEmpty) {
        double stAvg =
            progressList
                .map((p) => (p['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            progressList.length;
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    final query = _searchCtrl.text.trim().toLowerCase();

    final groups = (_cachedGroups ?? []).where((t) {
      if (query.isEmpty) return true;
      final title = (t['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();

    final independent = (_cachedIndependent ?? []).where((t) {
      if (query.isEmpty) return true;
      final title = (t['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();

    final allTasksCount =
        (_cachedGroups?.length ?? 0) + (_cachedIndependent?.length ?? 0);

    int doneTasksCount = 0;
    int inProgressCount = 0;
    int upcomingCount = 0;

    void countTask(dynamic t) {
      final subtasks = t['subtasks'] as List? ?? [];
      if (subtasks.isNotEmpty) {
        final progress = _calculateProgress(t);
        if (progress >= 1.0) {
          doneTasksCount++;
        } else if (progress > 0.0) {
          inProgressCount++;
        } else {
          upcomingCount++;
        }
      } else {
        final status = t['status'] ?? 'Upcoming';
        if (status == 'Done') {
          doneTasksCount++;
        } else if (status == 'In Progress' || status == 'In progress') {
          inProgressCount++;
        } else {
          upcomingCount++;
        }
      }
    }

    (_cachedGroups ?? []).forEach(countTask);
    (_cachedIndependent ?? []).forEach(countTask);

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomSpacing = bottomInset + 96;

    return RefreshIndicator(
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
              unreadCount: _unreadNotificationsCount,
              onNotificationTap: () =>
                  Navigator.pushNamed(context, '/notifications'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ✅ Search bar diisolasi — rebuild hanya saat input berubah
          SliverToBoxAdapter(
            child: DashboardSearchBar(controller: _searchCtrl),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          // ✅ Header seksi diisolasi — const-friendly, rebuild hanya saat navigasi
          SliverToBoxAdapter(
            child: DashboardSectionHeader(
              title: 'Group Task',
              onSeeAll: () => Navigator.pushNamed(
                context,
                '/work_in_group',
              ).then((_) => _fetchData()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(child: _buildWorkInGroupList(groups)),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          SliverToBoxAdapter(
            child: DashboardSectionHeader(
              title: 'Independent Task',
              onSeeAll: () => Navigator.pushNamed(
                context,
                '/independent_task',
              ).then((_) => _fetchData()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          _buildIndependentTaskListSliver(independent),
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
        ],
      ),
    );
  }

  Widget _buildWorkInGroupList(List<dynamic> groups) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 600 ? 32.0 : 25.0;

    if (groups.isEmpty) {
      return Container(
        height: screenWidth >= 600 ? 150 : 130,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            Text(
              'No group tasks yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            Text(
              'Create a group & add tasks first',
              style: TextStyle(color: Colors.grey[300], fontSize: 11),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: screenWidth >= 600 ? 205 : 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: groups.length,
        // ✅ Setiap kartu adalah widget terpisah — rebuild terisolasi per item
        itemBuilder: (context, index) => GroupTaskCard(
          task: groups[index],
          progress: _calculateProgress(groups[index]),
          onTap: () => Navigator.pushNamed(
            context,
            '/work_in_group_detail',
            arguments: groups[index],
          ),
        ),
      ),
    );
  }

  Widget _buildIndependentTaskListSliver(List<dynamic> independent) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 32.0
        : 25.0;

    if (independent.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          // ✅ Setiap item adalah widget terpisah — rebuild terisolasi per item
          (context, index) => IndependentTaskItem(
            task: independent[index],
            onTap: () => Navigator.pushNamed(
              context,
              '/independent_task_detail',
              arguments: independent[index],
            ),
          ),
          childCount: independent.length,
        ),
      ),
    );
  }
}
