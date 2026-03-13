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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(100),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.primaryTeal, size: 22),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    'Calender',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 44), 
              ],
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onMonthChanged(-1),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                ),
                Column(
                  children: [
                    Text(
                      _getMonthName(selectedDate.month),
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${selectedDate.year}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => onMonthChanged(1),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
          defaultTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 16),
          weekendTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 16),
          todayDecoration: const BoxDecoration(color: Colors.transparent),
          todayTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 16),
          outsideTextStyle: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 16),
        ),
        
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 15),
          weekendStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 15),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            
            // Dapatkan semua tugas yang jatuh pada hari ini (due date)
            bool isSpecificDueDate = upcomingTasks.any((t) => 
               t['due_date'] != null && 
               DateTime(t['due_date'].year, t['due_date'].month, t['due_date'].day) == normalizedDay);
            
            // Cek apakah hari ini berada dalam rentang start_date s/d due_date
            bool inRange = upcomingTasks.any((t) {
              if (t['start_date'] == null || t['due_date'] == null) return false;
              final start = DateTime(t['start_date'].year, t['start_date'].month, t['start_date'].day);
              final end = DateTime(t['due_date'].year, t['due_date'].month, t['due_date'].day);
              return normalizedDay.isAfter(start.subtract(const Duration(seconds: 1))) && 
                     normalizedDay.isBefore(end.add(const Duration(seconds: 1)));
            });

            if (isSpecificDueDate || inRange) {
               bool isStart = upcomingTasks.any((t) => 
                  t['start_date'] != null && 
                  DateTime(t['start_date'].year, t['start_date'].month, t['start_date'].day) == normalizedDay);
               
               bool isEnd = upcomingTasks.any((t) => 
                  t['due_date'] != null && 
                  DateTime(t['due_date'].year, t['due_date'].month, t['due_date'].day) == normalizedDay);

               return _buildDayCell(day, isCircle: isSpecificDueDate, inRange: inRange, isStart: isStart, isEnd: isEnd);
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {required bool isCircle, required bool inRange, bool isStart = false, bool isEnd = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: inRange ? AppColors.lightTealBg : Colors.transparent,
        borderRadius: isStart 
          ? const BorderRadius.horizontal(left: Radius.circular(25))
          : isEnd 
            ? const BorderRadius.horizontal(right: Radius.circular(25))
            : BorderRadius.zero,
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCircle ? AppColors.primaryTeal : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: GoogleFonts.outfit(
                color: isCircle ? Colors.white : Colors.black,
                fontWeight: isCircle || inRange ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// UpcomingTaskSection â€” Daftar tugas mendatang.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class UpcomingTaskSection extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(String) onDelete;

  const UpcomingTaskSection({super.key, required this.tasks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Task',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
             Center(child: Text('No upcoming tasks', style: GoogleFonts.outfit(color: Colors.grey)))
          else
            ...tasks.map((task) => _TaskCard(
              task: task, 
              onDelete: () => onDelete(task['id']),
            )).toList(),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onDelete;

  const _TaskCard({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(Icons.delete_rounded, color: AppColors.primaryTeal.withOpacity(0.8), size: 35),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        width: double.infinity, // Full width
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

