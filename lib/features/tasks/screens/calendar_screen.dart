import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/calendar_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingTasks = [];
  DateTime _selectedDate = DateTime(2026, 3, 13); // User requested 2026 real data

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('tasks')
          .select()
          .order('due_date', ascending: true);

      if (mounted) {
        setState(() {
          _upcomingTasks = (data as List).map((t) {
            final DateTime? dueDate = t['due_date'] != null ? DateTime.parse(t['due_date']).toLocal() : null;
            String dateLabel = 'No date';
            String statusLabel = 'Upcoming';

            if (dueDate != null) {
              final now = DateTime.now();
              // Normalize both dates to zero time for accurate day difference
              final today = DateTime(now.year, now.month, now.day);
              final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
              final diff = target.difference(today).inDays;
              
              if (diff == 0) {
                dateLabel = 'Today';
                statusLabel = 'This day';
              } else if (diff == 1) {
                dateLabel = 'Tomorrow';
                statusLabel = 'Next 1 day';
              } else if (diff > 1) {
                dateLabel = '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}';
                statusLabel = 'Next $diff days';
              } else if (diff < 0) {
                dateLabel = 'Passed';
                statusLabel = 'Expired';
              }
            }

            return {
              'title': t['title'],
              'date_label': dateLabel,
              'status_label': statusLabel,
              'show_delete': true,
              'due_date': dueDate,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _onMonthChanged(int increment) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + increment, 1);
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _selectedDate = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                CalendarHeader(
                  selectedDate: _selectedDate,
                  onMonthChanged: _onMonthChanged,
                ),
                const SizedBox(height: 25),
                CalendarCard(
                  selectedDate: _selectedDate,
                  upcomingTasks: _upcomingTasks,
                  onPageChanged: _onPageChanged,
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  UpcomingTaskSection(tasks: _upcomingTasks),
                const SizedBox(height: 140),
              ],
            ),
          ),
          const AppBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }
}
