import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../widgets/calendar_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Mencegah rebuild saat swipe PageView

  final Set<Completer<bool>> _pendingDeletes = {};

  Future<void> _forceExecutePendingDeletes() async {
    if (_pendingDeletes.isEmpty) return;
    for (var completer in _pendingDeletes) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _pendingDeletes.clear();
    ScaffoldMessenger.of(context).clearSnackBars();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  List<Map<String, dynamic>> _upcomingTasks = [];
  List<Map<String, dynamic>> _allTasks = [];
  DateTime _selectedDate = DateTime.now();

  Timer? _refreshDebounce;

  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _initUserAndFetchTasks();
  }

  Future<void> _initUserAndFetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      _currentUserId = userData['id'].toString();
    }
    _fetchTasks();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), _fetchTasks);
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _purgeExpiredTasks(
    List<Map<String, dynamic>> tasks,
  ) async {
    final now = DateTime.now();
    final deleteAfter = now.subtract(const Duration(days: 7));

    final staleOwnedTaskIds = tasks
        .where((task) {
          final taskId = task['id']?.toString();
          final createdBy = task['created_by']?.toString() ?? '';
          final status = task['status']?.toString().trim().toLowerCase() ?? '';

          if (taskId == null || taskId.isEmpty) {
            return false;
          }

          if (createdBy != _currentUserId || status == 'done') {
            return false;
          }

          final dueValue = task['due_date'];
          if (dueValue == null) {
            return false;
          }

          try {
            final dueDate = DateTime.parse(dueValue.toString()).toLocal();
            return dueDate.isBefore(deleteAfter);
          } catch (_) {
            return false;
          }
        })
        .map((task) => task['id'].toString())
        .toList();

    if (staleOwnedTaskIds.isEmpty) {
      return tasks;
    }

    try {
      for (var i = 0; i < staleOwnedTaskIds.length; i += 50) {
        final batch = staleOwnedTaskIds.skip(i).take(50).toList();
        for (var id in batch) await ApiClient().dio.delete('/tasks/$id');
      }
    } catch (e) {
      debugPrint('Error purging expired tasks: $e');
      return tasks;
    }

    return tasks
        .where((task) => !staleOwnedTaskIds.contains(task['id'].toString()))
        .toList();
  }

  Future<void> _fetchTasks() async {
    try {
      if (_currentUserId.isEmpty) return;
      final res = await ApiClient().dio.get('/tasks/user/$_currentUserId');
      final data = res.data['tasks'] as List? ?? [];

      final rawTasks = List<Map<String, dynamic>>.from(data);
      final List<Map<String, dynamic>> allTasks = await _purgeExpiredTasks(
        rawTasks,
      );

      // Sort tasks: terbaru (created_at DESC) di posisi atas
      allTasks.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
        final dateB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _allTasks = allTasks.map<Map<String, dynamic>>((t) {
            final status = t['status']?.toString() ?? '';
            final isCompleted = status.trim().toLowerCase() == 'done';

            DateTime? dueDate;
            if (t['due_date'] != null) {
              try {
                dueDate = DateTime.parse(t['due_date'].toString()).toLocal();
              } catch (_) {}
            }

            DateTime? startDate;
            if (t['start_date'] != null) {
              try {
                startDate = DateTime.parse(
                  t['start_date'].toString(),
                ).toLocal();
              } catch (_) {}
            }

            String dateLabel = 'Tanggal belum diatur';
            String statusLabel = 'Tertunda';
            bool isOverdue = false;

            if (dueDate != null) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
              final diff = target.difference(today).inDays;

              if (diff < 0) {
                isOverdue = true;
              }

              if (diff == 0) {
                dateLabel = 'Hari Ini';
                statusLabel = 'Hari Ini';
              } else if (diff == 1) {
                dateLabel = 'Besok';
                statusLabel = '1 hari lagi';
              } else if (diff > 1) {
                dateLabel =
                    '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}';
                statusLabel = '$diff hari lagi';
              } else if (diff < 0) {
                dateLabel = 'Terlewat';
                statusLabel = 'Kedaluwarsa';
              }
            }

            return <String, dynamic>{
              'title': t['title'] ?? 'Tugas Tanpa Judul',
              'date_label': dateLabel,
              'status_label': statusLabel,
              'due_date': dueDate,
              'start_date': startDate,
              'id': t['id'],
              'created_by': t['created_by'],
              'is_group': t['is_group'] == true,
              'is_completed': isCompleted,
              'is_overdue': isOverdue,
            };
          }).toList();

          _upcomingTasks = _allTasks.where((t) => !t['is_completed']).toList();
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
    final taskIndex = _upcomingTasks.indexWhere((t) => t['id'] == taskId);
    if (taskIndex == -1) return;
    final taskData = _upcomingTasks[taskIndex];

    setState(() {
      _upcomingTasks.removeAt(taskIndex);
    });

    bool isUndone = false;
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);

    if (mounted) {
      showUndoSnackBar(context, 'Task berhasil dihapus', () {
        isUndone = true;
        if (!completer.isCompleted) completer.complete(true);
        if (mounted) {
          setState(() {
            _upcomingTasks.insert(taskIndex, taskData);
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 10), () => false),
      completer.future,
    ]);

    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    try {
      await ApiClient().dio.delete('/tasks/$taskId');
    } catch (e) {
      if (mounted) {
        String errMsg = 'Gagal menghapus tugas. Silakan coba lagi.';
        
        // Mencegat error teknis jika server menolak karena ada data yang menyangkut (Code 500)
        if (e is DioException && e.response?.statusCode == 500) {
          errMsg = 'Gagal menghapus tugas: Terjadi masalah pada server. Pastikan tidak ada data turunan yang masih terikat.';
        } else if (e is DioException && e.response?.data != null && e.response?.data['message'] != null) {
          errMsg = e.response!.data['message'].toString();
        }

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 3000),
              backgroundColor: Colors.red.shade700,
              content: Text(errMsg),
            ),
          );
        _fetchTasks();
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  void _onMonthChanged(int increment) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + increment,
        1,
      );
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
                      upcomingTasks: _allTasks,
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
