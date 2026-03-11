import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/screen_header_bar.dart';
import '../../../core/shared_widgets/search_bar_with_button.dart';
import '../widgets/task_cards.dart';

class IndependentTaskScreen extends StatefulWidget {
  const IndependentTaskScreen({super.key});

  @override
  State<IndependentTaskScreen> createState() => _IndependentTaskScreenState();
}

class _IndependentTaskScreenState extends State<IndependentTaskScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('tasks')
          .select('*')
          .eq('is_group', false)
          .order('created_at', ascending: false);
      setState(() {
        _tasks = data as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchTasks,
            color: AppColors.primaryTeal,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // âœ… Header generik dari shared_widgets
                SliverToBoxAdapter(
                  child: ScreenHeaderBar(title: 'Independent Task'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // âœ… Search bar generik dari shared_widgets
                SliverToBoxAdapter(
                  child: SearchBarWithButton(controller: _searchCtrl),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 25)),
                _isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(color: AppColors.primaryTeal),
                          ),
                        ),
                      )
                    : _buildTaskListSliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          const AppBottomNavBar(currentIndex: -1),
        ],
      ),
    );

  Widget _buildTaskListSliver() {
    if (_tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Text(
              'No independent tasks available',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          // âœ… Setiap kartu tugas adalah widget terpisah
          (context, index) => IndependentTaskCard(
            task: _tasks[index],
            onDetailTap: () => Navigator.pushNamed(
              context,
              '/independent_task_detail',
              arguments: _tasks[index],
            ),
          ),
          childCount: _tasks.length,
        ),
      ),
    );
  }
}
