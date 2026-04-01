import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
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
  DateTime _selectedDate = DateTime.now();

  RealtimeChannel? _realtimeChannel;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _realtimeChannel = _supabase.channel('calendar-db-changes');

    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      callback: (payload) {
        debugPrint('Calendar Realtime: Task changed! Refreshing...');
        _fetchTasks();
      },
    ).subscribe();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      // Gunakan query sederhana dengan relasi default '*' untuk mencegah error missing columns
      final data = await _supabase
          .from('tasks')
          .select();
          
      final List<Map<String, dynamic>> allTasks = List<Map<String, dynamic>>.from(data);
      
      // Sort tasks: due_date terdekat, null di akhir
      allTasks.sort((a, b) {
        if (a['due_date'] == null && b['due_date'] == null) return 0;
        if (a['due_date'] == null) return 1;
        if (b['due_date'] == null) return -1;
        try {
          return DateTime.parse(a['due_date'].toString()).compareTo(DateTime.parse(b['due_date'].toString()));
        } catch (_) {
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _upcomingTasks = allTasks.where((t) {
            final status = t['status']?.toString() ?? '';
            return status.trim().toLowerCase() != 'done';
          }).map<Map<String, dynamic>>((t) {
            DateTime? dueDate;
            if (t['due_date'] != null) {
              try {
                dueDate = DateTime.parse(t['due_date'].toString()).toLocal();
              } catch (_) {}
            }

            DateTime? startDate;
            if (t['start_date'] != null) {
              try {
                startDate = DateTime.parse(t['start_date'].toString()).toLocal();
              } catch (_) {}
            }

            String dateLabel = 'No date set';
            String statusLabel = 'Upcoming';

            if (dueDate != null) {
              final now = DateTime.now();
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

            return <String, dynamic>{
              'title': t['title'] ?? 'Untitled Task',
              'date_label': dateLabel,
              'status_label': statusLabel,
              'due_date': dueDate,
              'start_date': startDate,
              'id': t['id'],
              'created_by': t['created_by'],
              'is_group': t['is_group'] == true,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching calendar tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menghapus task — hanya boleh dipanggil setelah konfirmasi.
  Future<void> _deleteTask(String taskId) async {
    // Optimistic update: hapus dari list lokal
    setState(() {
      _upcomingTasks.removeWhere((t) => t['id'] == taskId);
    });

    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Gagal menghapus task: $e')),
        );
        _fetchTasks();
      }
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
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month + increment, 1);
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _selectedDate = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchTasks,
      color: AppColors.primaryTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CalendarHeader(
                  selectedDate: _selectedDate,
                  onMonthChanged: _onMonthChanged,
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 210),
                    child: CalendarCard(
                      selectedDate: _selectedDate,
                      upcomingTasks: _upcomingTasks,
                      onPageChanged: _onPageChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              UpcomingTaskSection(
                tasks: _upcomingTasks,
                currentUserId: _currentUserId,
                onDelete: _deleteTask,
              ),
            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }
}
