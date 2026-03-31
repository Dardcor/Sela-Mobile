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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ Fetch created_by dan is_group untuk keperluan cek permission hapus
      final data = await _supabase
          .from('tasks')
          .select('id, title, description, due_date, start_date, created_by, is_group')
          .order('due_date', ascending: true);

      if (mounted) {
        setState(() {
          _upcomingTasks = (data as List).map((t) {
            final DateTime? dueDate = t['due_date'] != null
                ? DateTime.parse(t['due_date']).toLocal()
                : null;
            String dateLabel = 'No date';
            String statusLabel = 'Upcoming';

            if (dueDate != null) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final target =
                  DateTime(dueDate.year, dueDate.month, dueDate.day);
              final diff = target.difference(today).inDays;

              if (diff == 0) {
                dateLabel = 'Today';
                statusLabel = 'This day';
              } else if (diff == 1) {
                dateLabel = 'Tomorrow';
                statusLabel = 'Next 1 day';
              } else if (diff > 1) {
                dateLabel =
                    '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}';
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
              'due_date': dueDate,
              'start_date': t['start_date'] != null
                  ? DateTime.parse(t['start_date']).toLocal()
                  : null,
              'id': t['id'],
              // ✅ Simpan created_by untuk validasi permission hapus
              'created_by': t['created_by'],
              'is_group': t['is_group'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus task: $e')),
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
