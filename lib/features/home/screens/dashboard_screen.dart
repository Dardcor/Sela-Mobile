import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../widgets/dashboard_widgets.dart';

/// Semua rendering UI didelegasikan ke [dashboard_widgets.dart]:
/// - [DashboardHeader]        → avatar + statistik task (rebuild saat data berubah)
/// - [DashboardSearchBar]     → search bar (rebuild terisolasi dari list)
/// - [DashboardSectionHeader] → judul seksi + "See all"
/// - [GroupTaskCard]          → kartu tugas grup (rebuild terisolasi per item)
/// - [IndependentTaskItem]    → item tugas mandiri (rebuild terisolasi per item)
class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _cachedProfile;
  List<dynamic>? _cachedGroups;
  List<dynamic>? _cachedIndependent;

  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  int _unreadNotificationsCount = 0;

  @override
  bool get wantKeepAlive => true; // Mencegah rebuild saat swipe PageView

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // Rebuild with filtered lists
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchContent(), _fetchNotificationsCount()]);
  }

  Future<void> _fetchNotificationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];

      final res = await ApiClient().dio.get(
        '/notifications',
        queryParameters: {'user_id': userId, 'is_read': false},
      );

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = (res.data['notifications'] as List).length;
        });
      }
    } catch (e) {
      debugPrint('Err Notifications Count: $e');
    }
  }

  Future<void> _fetchContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];

      final resProfile = await ApiClient().dio.get('/me');
      final profileData = resProfile.data['user'];
      debugPrint('Dashboard: Profile fetch done for $userId');

      List groupTasksList = [];
      List independentTasksList = [];
      try {
        final resTasks = await ApiClient().dio.get('/tasks/user/$userId');
        final allTasks = resTasks.data['tasks'] as List? ?? [];
        
        groupTasksList = allTasks.where((t) => t['is_group'] == true).toList();
        independentTasksList = allTasks.where((t) => t['is_group'] == false || t['is_group'] == null).toList();
        
      } catch (e, stack) {
        debugPrint('Dashboard tasks fetch err: $e');
        debugPrint(stack.toString());
      }

      if (mounted) {
        setState(() {
          _cachedProfile = profileData;
          _cachedGroups = groupTasksList;
          _cachedIndependent = independentTasksList;
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
    if (task['progress'] != null) {
      // Backend (Laravel) already calculates this for us via TaskService -> getTasksByUser!
      return ((task['progress'] as num).toDouble() / 100).clamp(0.0, 1.0);
    }
    
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) {
      return 0.0;
    }

    final subtasks = task['subtasks'] as List;
    double totalProgress = 0;

    for (var st in subtasks) {
      final progressList = st['progress_entries'] as List? ?? [];
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
      final progress = _calculateProgress(t);
      if (progress >= 1.0) {
        doneTasksCount++;
      } else if (progress > 0.0) {
        inProgressCount++;
      } else {
        upcomingCount++;
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
              onProfileTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(4); // Navigasi via navbar ke tab profil
                } else {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
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
              title: 'Tugas Kelompok',
              onSeeAll: () => Navigator.pushNamed(
                context,
                '/work_in_group',
              ).then((_) => _fetchData()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(child: _buildWorkInGroupList(groups.take(5).toList())),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          SliverToBoxAdapter(
            child: DashboardSectionHeader(
              title: 'Tugas Mandiri',
              onSeeAll: () => Navigator.pushNamed(
                context,
                '/independent_task',
              ).then((_) => _fetchData()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          _buildIndependentTaskListSliver(independent.take(5).toList()),
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
          ).then((_) => _fetchData()),
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
            ).then((_) => _fetchData()),
          ),
          childCount: independent.length,
        ),
      ),
    );
  }
}
