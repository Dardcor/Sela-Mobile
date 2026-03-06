import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final task = ModalRoute.of(context)!.settings.arguments as dynamic;
    final progress = _calculateProgress(task);
    final members = (task['group_members'] as List?) ?? [];
    final subtasks = (task['subtasks'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, task),
            const SizedBox(height: 20),
            _buildMainCard(task, progress),
            const SizedBox(height: 25),
            _buildProgressSection('Your Progres', subtasks), // Needs refinement for "your" progress
            const SizedBox(height: 25),
            _buildMemberSection(members, subtasks),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(dynamic task) {
    if (task['subtasks'] == null || (task['subtasks'] as List).isEmpty) return 0.0;
    final subtasks = task['subtasks'] as List;
    double totalProgress = 0;
    for (var st in subtasks) {
      final progressList = st['subtask_progress'] as List;
      if (progressList.isNotEmpty) {
        double stAvg = progressList.map((p) => (p['progress'] as num).toDouble()).reduce((a, b) => a + b) / progressList.length;
        totalProgress += stAvg;
      }
    }
    return (totalProgress / (subtasks.length * 100)).clamp(0.0, 1.0);
  }

  Widget _buildHeader(BuildContext context, dynamic task) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              Text('Work in Group', style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
            ],
          ),
          Image.asset('assets/images/work_in_group.png', height: 100, errorBuilder: (_, __, ___) => const SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMainCard(dynamic t, double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.book_outlined, color: Colors.white, size: 20)),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progress, backgroundColor: Colors.grey[100], color: AppColors.primaryTeal, strokeWidth: 5)),
                  Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(t['title'] ?? '', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(t['description'] ?? '', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 15),
          // Links would go here
          Row(children: [Text('${_formatDate(t['start_date'])} - ${_formatDate(t['due_date'])} | ${t['category'] ?? ''}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400])), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)), child: Text('Report', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))]),
        ],
      ),
    );
  }

  Widget _buildProgressSection(String title, List subtasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
          const SizedBox(height: 15),
          ...subtasks.map((st) => _buildSubtaskRow(st['title'], 50)), // Placeholder 50%
        ],
      ),
    );
  }

  Widget _buildSubtaskRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 14))),
          Text('${value.toInt()}%', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: value/100, backgroundColor: Colors.grey[200], color: AppColors.primaryTeal, minHeight: 6))),
        ],
      ),
    );
  }

  Widget _buildMemberSection(List members, List subtasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Member & Progres', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
          const SizedBox(height: 15),
          ...members.map((m) => _buildMemberProgressTile(m, subtasks)),
        ],
      ),
    );
  }

  Widget _buildMemberProgressTile(dynamic m, List subtasks) {
    final profile = m['profiles'];
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundImage: NetworkImage(profile?['avatar_url'] ?? 'https://via.placeholder.com/150')),
        title: Text(profile?['full_name'] ?? 'Member', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${subtasks.length} SubTask', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
        children: subtasks.map((st) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(st['title'], style: GoogleFonts.outfit(fontSize: 12)),
              Text('100%', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    final dt = DateTime.parse(s);
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m-1];
}
