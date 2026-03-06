import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class WorkInGroupScreen extends StatefulWidget {
  const WorkInGroupScreen({super.key});

  @override
  State<WorkInGroupScreen> createState() => _WorkInGroupScreenState();
}

class _WorkInGroupScreenState extends State<WorkInGroupScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Step 1: Get all group_ids the user belongs to
      final memberData = await supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', user.id);

      final groupIds = (memberData as List).map((m) => m['group_id'] as String).toList();

      if (groupIds.isEmpty) {
        if (mounted) setState(() { _tasks = []; _isLoading = false; });
        return;
      }

      // Step 2: Fetch tasks belonging to those groups
      final data = await supabase
          .from('tasks')
          .select('*, groups(id, name, course_name, class_name, group_number), subtasks(*, subtask_progress(*))')
          .eq('is_group', true)
          .inFilter('group_id', groupIds)
          .order('created_at', ascending: false);

      // Step 3: Fetch group members separately for avatars
      final membersData = await supabase
          .from('group_members')
          .select('group_id, profiles(*)')
          .inFilter('group_id', groupIds);

      // Map members by group_id
      final membersByGroup = <String, List>{};
      for (final m in membersData as List) {
        final gid = m['group_id'] as String;
        membersByGroup.putIfAbsent(gid, () => []).add(m);
      }

      // Attach members to each task
      final enrichedTasks = (data as List).map((task) {
        final gid = task['group_id'] as String?;
        return {
          ...Map<String, dynamic>.from(task),
          '_members': gid != null ? (membersByGroup[gid] ?? []) : [],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _tasks = enrichedTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Err WIG: $e');
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
        double stAvg = progressList.map((p) => (p['progress'] as num).toDouble()).reduce((a, b) => a + b) / progressList.length;
        totalProgress += stAvg;
      }
    }
    return (totalProgress / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  List<dynamic> get _filteredTasks => _searchQuery.isEmpty
      ? _tasks
      : _tasks.where((t) => (t['title'] ?? '').toLowerCase().contains(_searchQuery)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchTasks,
            color: AppColors.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: AppColors.primaryTeal)))
                      : _buildTaskList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 55, 25, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Work in Group', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
            Text('Your group assignments', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500])),
          ]),
          Image.asset('assets/images/work_group.png', height: 80, errorBuilder: (_, __, ___) => 
            Container(
              height: 80, width: 100,
              decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.people_rounded, color: AppColors.primaryTeal, size: 40),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search', border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
        ),
      ]),
    );
  }

  Widget _buildTaskList() {
    if (_filteredTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(children: [
            Icon(Icons.assignment_outlined, color: Colors.grey[300], size: 60),
            const SizedBox(height: 16),
            Text('No group tasks yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Add a task using the + button', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
          ]),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(_filteredTasks[index]),
    );
  }

  Widget _buildTaskCard(dynamic t) {
    final progress = _calculateProgress(t);
    final members = (t['_members'] as List? ?? []);
    final group = t['groups'] as Map<String, dynamic>?;

    String detailInfo = '';
    if (t['start_date'] != null && t['due_date'] != null) {
      final start = DateTime.parse(t['start_date']);
      final due = DateTime.parse(t['due_date']);
      detailInfo = '${_fmtDate(start)} – ${_fmtDate(due)}';
    }
    if (group != null) {
      final parts = [group['class_name'], group['course_name']].where((x) => x != null && (x as String).isNotEmpty).toList();
      if (parts.isNotEmpty) detailInfo += '${detailInfo.isNotEmpty ? ' | ' : ''}${parts.join(' | ')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.book_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['title'] ?? '', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            Text(t['description'] ?? '', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 10),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                strokeWidth: 4,
              ),
            ),
            Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
          ]),
        ]),
        if (detailInfo.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(detailInfo, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400])),
          ),
        ],
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SizedBox(
            height: 30, width: 110,
            child: Stack(children: List.generate(
              min(members.length, 4),
              (idx) {
                if (idx == 3 && members.length > 3) {
                  return Positioned(left: 54, child: CircleAvatar(
                    radius: 13, backgroundColor: const Color(0xFFE0E0E0),
                    child: Text('+${members.length - 3}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
                  ));
                }
                final avatarUrl = members[idx]['profiles']?['avatar_url'];
                return Positioned(left: idx * 18.0, child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('assets/images/avatar.png') as ImageProvider,
                  ),
                ));
              },
            )),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/work_in_group_detail', arguments: t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
              decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12)),
              child: Text('Detail', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 85, margin: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(45),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navIcon(context, Icons.home_filled, false, '/dashboard'),
          _navIcon(context, Icons.calendar_month_rounded, false, '/calendar'),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/add_project').then((_) => _fetchTasks()),
            child: Container(height: 60, width: 60, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 35)),
          ),
          _navIcon(context, Icons.people_rounded, false, '/team'),
          _navIcon(context, Icons.person_rounded, false, '/profile'),
        ]),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, bool active, String route) => GestureDetector(
    onTap: active ? null : () => Navigator.pushReplacementNamed(context, route),
    child: Icon(icon, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 32),
  );
}
