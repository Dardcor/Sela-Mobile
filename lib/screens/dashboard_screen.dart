import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

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

  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch Profile
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // 2. Fetch group tasks — RLS sudah handle filter by membership
      // Fetch members separately to avoid nested join recursion
      List groupTasksList = [];
      try {
        final gData = await supabase
            .from('tasks')
            .select('*, groups(id, name, course_name, class_name, group_number), subtasks(*, subtask_progress(*))')
            .eq('is_group', true)
            .order('created_at', ascending: false);
        groupTasksList = gData as List;

        // Fetch member info for each unique group_id
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

      // 3. Fetch independent tasks
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
        backgroundColor: Color(0xFFF1F8F9),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 25),
                  _buildSectionHeader('Work in Group',
                      () => Navigator.pushNamed(context, '/work_in_group').then((_) => _fetchData())),
                  const SizedBox(height: 15),
                  _buildWorkInGroupList(),
                  const SizedBox(height: 25),
                  _buildSectionHeader('Independent Task',
                      () => Navigator.pushNamed(context, '/independent_task').then((_) => _fetchData())),
                  const SizedBox(height: 15),
                  _buildIndependentTaskList(),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
          _buildGlobalNav(context, 0),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final profile = _cachedProfile;
    final name = profile?['full_name'] ?? profile?['username'] ?? 'User';
    final role = profile?['class_name'] ?? 'Mahasiswa';

    final allTasks = (_cachedGroups?.length ?? 0) + (_cachedIndependent?.length ?? 0);
    final doneTasks = (_cachedGroups?.where((t) => t['status'] == 'Done').length ?? 0) +
        (_cachedIndependent?.where((t) => t['status'] == 'Done').length ?? 0);
    final inProgress = (_cachedGroups?.where((t) => t['status'] == 'In Progress').length ?? 0) +
        (_cachedIndependent?.where((t) => t['status'] == 'In Progress').length ?? 0);
    final upcoming = (_cachedGroups?.where((t) => t['status'] == 'Upcoming').length ?? 0) +
        (_cachedIndependent?.where((t) => t['status'] == 'Upcoming').length ?? 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(25, MediaQuery.of(context).padding.top + 20, 25, 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: profile?['avatar_url'] != null
                          ? NetworkImage(profile!['avatar_url'])
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Text(role, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.notifications_outlined, color: AppColors.primaryTeal, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text('Task Overview', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _overviewCard('$allTasks', 'All tasks'),
              _overviewCard('$doneTasks', 'Done'),
              _overviewCard('$inProgress', 'In progress'),
              _overviewCard('$upcoming', 'Upcoming'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(String count, String label) {
    return Container(
      width: 85, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(count, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search a task....',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        ),
      ),
    ),
  );

  Widget _buildSectionHeader(String t, VoidCallback tap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      GestureDetector(
        onTap: tap,
        child: Text('See all', style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    ]),
  );

  // Work in Group — shows GROUP TASKS (task.is_group == true)
  Widget _buildWorkInGroupList() {
    if (_cachedGroups == null || _cachedGroups!.isEmpty) {
      return Container(
        height: 130,
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.assignment_outlined, color: Colors.grey[300], size: 40),
          const SizedBox(height: 8),
          Text('No group tasks yet', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
          Text('Create a group & add tasks first', style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 11)),
        ]),
      );
    }
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 25),
        itemCount: _cachedGroups!.length,
        itemBuilder: (context, index) => _groupCard(_cachedGroups![index]),
      ),
    );
  }

  Widget _groupCard(dynamic t) {
    final progress = _calculateProgress(t);
    final members = (t['_members'] as List? ?? []);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/work_in_group_detail', arguments: t),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.book_outlined, color: Colors.white, size: 18),
            ),
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                height: 38, width: 38,
                child: CircularProgressIndicator(
                  value: progress, strokeWidth: 3.5,
                  backgroundColor: Colors.grey[200], color: AppColors.primaryTeal,
                ),
              ),
              Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
            ]),
          ]),
          const SizedBox(height: 10),
          Text(t['title'] ?? '', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(t['description'] ?? '', maxLines: 2, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SizedBox(
              width: 75, height: 25,
              child: Stack(children: List.generate(
                members.isEmpty ? 0 : min(members.length, 4),
                (idx) {
                  if (idx == 3 && members.length > 3) {
                    return Positioned(left: 45, child: CircleAvatar(
                      radius: 11, backgroundColor: Colors.grey[300],
                      child: Text('+${members.length - 3}', style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold)),
                    ));
                  }
                  final avatarUrl = members[idx]['profiles']?['avatar_url'];
                  return Positioned(left: idx * 15.0, child: CircleAvatar(
                    radius: 11, backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                  ));
                },
              )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)),
              child: Text('detail', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    );
  }

  // Independent Tasks
  Widget _buildIndependentTaskList() {
    if (_cachedIndependent == null || _cachedIndependent!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Container(
          height: 80, alignment: Alignment.center,
          child: Text('No independent tasks yet', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(children: _cachedIndependent!.map((t) => _independentTaskItem(t)).toList()),
    );
  }

  Widget _independentTaskItem(dynamic t) {
    String dateStr = 'No date set';
    if (t['start_date'] != null && t['due_date'] != null) {
      final start = DateTime.parse(t['start_date']);
      final due = DateTime.parse(t['due_date']);
      dateStr = '${_formatDate(start)} - ${_formatDate(due)}';
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/independent_task_detail', arguments: t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.book_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['title'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(dateStr, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
        ]),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildGlobalNav(BuildContext context, int index) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 85, margin: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(45),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navIcon(context, Icons.home_filled, index == 0, '/dashboard'),
          _navIcon(context, Icons.calendar_month_rounded, index == 1, '/calendar'),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/add_project').then((_) => _fetchData()),
            child: Container(height: 60, width: 60, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 35)),
          ),
          _navIcon(context, Icons.people_rounded, index == 2, '/team'),
          _navIcon(context, Icons.person_rounded, index == 3, '/profile'),
        ]),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, bool active, String route) => GestureDetector(
    onTap: active ? null : () => Navigator.pushReplacementNamed(context, route),
    child: Icon(icon, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 32),
  );
}
