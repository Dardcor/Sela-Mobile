import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class IndependentTaskScreen extends StatefulWidget {
  const IndependentTaskScreen({super.key});

  @override
  State<IndependentTaskScreen> createState() => _IndependentTaskScreenState();
}

class _IndependentTaskScreenState extends State<IndependentTaskScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase.from('tasks').select('*').eq('is_group', false).order('created_at', ascending: false);

      setState(() {
        _tasks = data as List;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Err Independent: $e');
      setState(() => _isLoading = false);
    }
  }

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
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 0), 
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, size: 22))), 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), 
          child: Text('Independent Task', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal))
        ), 
        const SizedBox(width: 44)
      ])
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
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
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(50), child: Text('No independent tasks available', style: GoogleFonts.outfit(color: Colors.grey))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
    );
  }

  Widget _buildTaskCard(dynamic t) {
    int daysLeft = 0;
    if (t['due_date'] != null) {
      final due = DateTime.parse(t['due_date']);
      daysLeft = due.difference(DateTime.now()).inDays;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.book_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['title'] ?? '', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$daysLeft days left', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                        const SizedBox(width: 15),
                        const Icon(Icons.bar_chart_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Priority: ${t['priority'] ?? 'Medium'}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1), // Using normal divider for simplicity, or dashed if needed
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.5), width: 1, style: BorderStyle.solid), // Dash effect not built-in, using solid
                ),
                child: Text(t['category'] ?? 'General', style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/independent_task_detail', arguments: t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12)),
                  child: Text('Detail', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
