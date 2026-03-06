import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class IndependentTaskDetailScreen extends StatefulWidget {
  const IndependentTaskDetailScreen({super.key});

  @override
  State<IndependentTaskDetailScreen> createState() => _IndependentTaskDetailScreenState();
}

class _IndependentTaskDetailScreenState extends State<IndependentTaskDetailScreen> {
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
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildTaskCard(task, progress),
                const SizedBox(height: 25),
                _buildProgressCard(subtasks),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildBottomNavBar(context),
        ],
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

  Widget _buildHeader(BuildContext context) {
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
              Text(
                'Independent\nTask',
                style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primaryTeal, height: 1.1),
              ),
            ],
          ),
          Image.asset(
            'assets/images/independent_task.png',
            height: 100,
            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic t, double progress) {
    String dateRange = '';
    if (t['start_date'] != null && t['due_date'] != null) {
      dateRange = '${_formatDateShort(DateTime.parse(t['start_date']))} - ${_formatDateShort(DateTime.parse(t['due_date']))}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.book_outlined, color: Colors.white, size: 24),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 60, width: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[100],
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(t['title'] ?? '', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Text(t['description'] ?? '', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 15),
          if (t['link'] != null && t['link'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(t['link'], style: GoogleFonts.outfit(fontSize: 10, color: Colors.blue, decoration: TextDecoration.underline)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('$dateRange | ${t['category'] ?? ''} | ${t['subject'] ?? ''}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12)),
                child: Text('Report', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(List subtasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Progres', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
          const SizedBox(height: 20),
          if (subtasks.isEmpty)
            Center(child: Text('No progress items yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)))
          else
            ...subtasks.map((st) {
              final progressList = st['subtask_progress'] as List;
              double prog = 0;
              if (progressList.isNotEmpty) {
                prog = (progressList[0]['progress'] as num).toDouble();
              }
              return _buildProgressRow(st['title'], prog);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500))),
          Text('${value.toInt()}%', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 8, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10))),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(height: 8, decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10))),
                ),
                Positioned(
                  left: (value / 100 * (MediaQuery.of(context).size.width * 0.3)).clamp(0.0, MediaQuery.of(context).size.width * 0.3) - 6,
                  child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.primaryTeal, width: 2.5))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 85,
        margin: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(context, Icons.home_filled, false, '/dashboard'),
            _navIcon(context, Icons.calendar_month_rounded, false, '/calendar'),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add_project'),
              child: Container(
                height: 60, width: 60,
                decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
              ),
            ),
            _navIcon(context, Icons.people_rounded, false, '/team'),
            _navIcon(context, Icons.person_rounded, false, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, bool active, String route) => GestureDetector(
    onTap: active ? null : () => Navigator.pushReplacementNamed(context, route),
    child: Icon(icon, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 32),
  );
}
