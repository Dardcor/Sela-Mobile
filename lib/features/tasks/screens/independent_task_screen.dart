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
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchTasks,
            color: AppColors.primaryTeal,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // âœHeader dengan Background Putih (Kotak) & Gambar
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.fromLTRB(25, MediaQuery.of(context).padding.top + 5, 5, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Independent\nTask',
                                style: GoogleFonts.outfit(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            // Gambar digeser sedikit agar pas (offset negatif)
                            Transform.translate(
                              offset: const Offset(-20, -10),
                              child: Image.asset(
                                'assets/images/independent_task.png', 
                                height: 95,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, s) => const SizedBox(height: 95),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                // âœSearch Bar sesuai Gambar 1
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
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
