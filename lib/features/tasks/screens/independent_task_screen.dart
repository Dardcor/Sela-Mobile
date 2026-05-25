import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/search_bar_with_button.dart';
import '../widgets/task_cards.dart';

class IndependentTaskScreen extends StatefulWidget {
  const IndependentTaskScreen({super.key});

  @override
  State<IndependentTaskScreen> createState() => _IndependentTaskScreenState();
}

class _IndependentTaskScreenState extends State<IndependentTaskScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  List<dynamic> get _filteredTasks {
    if (_searchQuery.isEmpty) return _tasks;
    return _tasks.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery);
    }).toList();
  }

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'].toString();

      final res = await ApiClient().dio.get('/tasks/user/$userId');
      final allTasks = res.data['tasks'] as List? ?? [];
      final independentTasks = allTasks.where((t) => t['is_group'] == false || t['is_group'] == null).toList();

      if (mounted) {
        setState(() {
          _tasks = independentTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Err Independent Tasks: $e');
      if (mounted) setState(() => _isLoading = false);
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
                  decoration: const BoxDecoration(color: Colors.white),
                  padding: EdgeInsets.fromLTRB(
                    25,
                    MediaQuery.of(context).padding.top + 5,
                    5,
                    10,
                  ),
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
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Tugas\nMandiri',
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
                              errorBuilder: (ctx, e, s) =>
                                  const SizedBox(height: 95),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              // âœSearch bar disamakan dengan homepage
              SliverToBoxAdapter(
                child: SearchBarWithButton(controller: _searchCtrl),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
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
    if (_filteredTasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Text(
              'Belum ada tugas mandiri',
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
            task: _filteredTasks[index],
            onDetailTap: () => Navigator.pushNamed(
              context,
              '/independent_task_detail',
              arguments: _filteredTasks[index],
            ),
          ),
          childCount: _filteredTasks.length,
        ),
      ),
    );
  }
}
