import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CalendarHeader — Header layar kalender dengan background melengkung.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final Function(int) onMonthChanged;

  const CalendarHeader({
    super.key,
    required this.selectedDate,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background teal — fixed height, tidak membatasi konten
        Container(
          height: MediaQuery.of(context).padding.top + 230,
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        // Konten — tidak punya height constraint, bebas dari overflow
        Padding(
          padding: EdgeInsets.fromLTRB(
            25,
            MediaQuery.of(context).padding.top + 20,
            25,
            30,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    'Calender',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Baris 2: navigasi bulan terpusat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => onMonthChanged(-1),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _getMonthName(selectedDate.month),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${selectedDate.year}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => onMonthChanged(1),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarCard — Kartu Kalender Bulanan.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> upcomingTasks;
  final Function(DateTime) onPageChanged;

  const CalendarCard({
    super.key,
    required this.selectedDate,
    required this.upcomingTasks,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: selectedDate,
        calendarFormat: CalendarFormat.month,
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.monday,
        onPageChanged: onPageChanged,
        daysOfWeekHeight: 45,
        rowHeight: 45,

        availableGestures: AvailableGestures.horizontalSwipe,

        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          cellMargin: EdgeInsets.zero,
          cellPadding: EdgeInsets.zero,
          defaultTextStyle: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 16,
          ),
          weekendTextStyle: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 16,
          ),
          todayDecoration: const BoxDecoration(color: Colors.transparent),
          todayTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 16),
          outsideTextStyle: GoogleFonts.outfit(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.outfit(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          weekendStyle: GoogleFonts.outfit(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _customDayBuilder(day, upcomingTasks, focusedDay: focusedDay),
          todayBuilder: (context, day, focusedDay) =>
              _customDayBuilder(day, upcomingTasks, focusedDay: focusedDay),
          selectedBuilder: (context, day, focusedDay) =>
              _customDayBuilder(day, upcomingTasks, focusedDay: focusedDay),
          outsideBuilder: (context, day, focusedDay) =>
              _customDayBuilder(day, upcomingTasks, focusedDay: focusedDay),
        ),
      ),
    );
  }

  Widget? _customDayBuilder(
    DateTime day,
    List<Map<String, dynamic>> tasks, {
    required DateTime focusedDay,
  }) {
    bool isOutside = day.month != focusedDay.month;

    // Tuntutan: Jika bukan bulan yang sedang difokuskan, MURNI tampilkan greyed out polos (TIDAK ADA TRACK SAMA SEKALI)
    if (isOutside) {
      return Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.outfit(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),
      );
    }

    final normalizedDay = DateTime(day.year, day.month, day.day);

    // 1. Circle highlight (due date)
    final circleTasks = tasks
        .where(
          (t) =>
              t['due_date'] != null && isSameDay(t['due_date'], normalizedDay),
        )
        .toList();
    bool isCircle = circleTasks.isNotEmpty;

    // 2. Range highlight helper
    bool isTaskInRange(Map<String, dynamic> t, DateTime d) {
      if (t['start_date'] == null || t['due_date'] == null) return false;
      if (isSameDay(t['start_date'], t['due_date'])) return false;
      final start = DateTime(
        t['start_date'].year,
        t['start_date'].month,
        t['start_date'].day,
      );
      final end = DateTime(
        t['due_date'].year,
        t['due_date'].month,
        t['due_date'].day,
      );
      return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
          (d.isAtSameMomentAs(end) || d.isBefore(end));
    }

    final rangeTasks = tasks
        .where((t) => isTaskInRange(t, normalizedDay))
        .toList();
    bool inRange = rangeTasks.isNotEmpty;

    if (isCircle || inRange) {
      // 3. Faded logic
      bool isFaded = true;
      for (var t in circleTasks) {
        if (t['is_completed'] != true && t['is_overdue'] != true) {
          isFaded = false;
          break;
        }
      }
      if (isFaded) {
        for (var t in rangeTasks) {
          if (t['is_completed'] != true && t['is_overdue'] != true) {
            isFaded = false;
            break;
          }
        }
      }

      bool dayHasRange(DateTime d) {
        final nd = DateTime(d.year, d.month, d.day);
        return tasks.any((t) => isTaskInRange(t, nd));
      }

      bool isStart =
          inRange &&
          (!dayHasRange(normalizedDay.subtract(const Duration(days: 1))) ||
              normalizedDay.weekday == DateTime.monday);
      bool isEnd =
          inRange &&
          (!dayHasRange(normalizedDay.add(const Duration(days: 1))) ||
              normalizedDay.weekday == DateTime.sunday);

      return _buildDayCell(
        day,
        isCircle: isCircle,
        inRange: inRange,
        isStart: isStart,
        isEnd: isEnd,
        isOutside: isOutside,
        isFaded: isFaded,
      );
    }
    
    // Tuntutan: "jangan ada penanda tanggal hari ini, hapus saja. penanda kotak abu - abu dan font hitam"
    // Dengan mereturn Widget Text secara eksplisit untuk HARI INI yang kosong task, 
    // Calendar table TIDAK AKAN menggunakan default style hari ininya (bulat/kotak abu-abu).
    return Center(
      child: Text(
        '${day.day}',
        style: GoogleFonts.outfit(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isCircle,
    required bool inRange,
    bool isStart = false,
    bool isEnd = false,
    bool isOutside = false,
    bool isFaded = false,
  }) {
    final effectivelyFaded = isFaded || isOutside;
    final rangeColor = effectivelyFaded ? Colors.grey[200]! : AppColors.lightTealBg;
    final circleColor = effectivelyFaded ? Colors.grey[400]! : AppColors.primaryTeal;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      decoration: BoxDecoration(
        color: inRange ? rangeColor : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isStart ? const Radius.circular(25) : Radius.zero,
          right: isEnd ? const Radius.circular(25) : Radius.zero,
        ),
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCircle ? circleColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: GoogleFonts.outfit(
                color: isCircle
                    ? Colors.white
                    : (isOutside ? Colors.grey[300] : Colors.black),
                fontWeight: isCircle || inRange
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpcomingTaskSection extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final String currentUserId;
  final Function(String) onDelete;

  const UpcomingTaskSection({
    super.key,
    required this.tasks,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Task',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
            Center(
              child: Text(
                'No upcoming tasks',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            )
          else
            ...tasks
                .map(
                  (task) => _TaskCard(
                    task: task,
                    currentUserId: currentUserId,
                    onDelete: () => onDelete(task['id']),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final String currentUserId;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.currentUserId,
    required this.onDelete,
  });

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.3,
                  ),
                  children: const [
                    TextSpan(text: 'Are you sure you want\nto '),
                    TextSpan(
                      text: 'delete',
                      style: TextStyle(color: AppColors.primaryTeal),
                    ),
                    TextSpan(text: ' this task?'),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                task['title'] ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  // Tombol Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Tombol Accept
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Accept',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Both created_by and currentUserId are UUIDs format, compare normally (handling nulls)
    final String createdBy = (task['created_by'] ?? '').toString();
    final bool isOwner = createdBy.isNotEmpty && createdBy == currentUserId;

    return Dismissible(
      key: Key(task['id'].toString()),
      direction: DismissDirection.endToStart,
      // ✅ Background muncul saat swipe, sesuai desain Figma (hanya ikon teal)
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 15),
        color: Colors.transparent,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.primaryTeal,
          size: 28,
        ),
      ),
      // ✅ confirmDismiss: cek permission dulu, lalu tampilkan popup konfirmasi
      confirmDismiss: (_) async {
        if (!isOwner) {
          // Member cannot delete task — show red snackbar above navbar
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 2500),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 85),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Text(
                  'Only the task creator can delete this task',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          return false;
        }
        // Pembuat task: tampilkan dialog konfirmasi
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task['date_label'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              task['status_label'] ?? '',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
