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
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
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
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Calender',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 30),
            const CalendarFilters(),
            const SizedBox(height: 30),
            MonthSelector(
              selectedDate: selectedDate,
              onMonthChanged: onMonthChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarFilters extends StatelessWidget {
  const CalendarFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _FilterBtn(label: 'Day', active: false),
        _FilterBtn(label: 'Week', active: false),
        _FilterBtn(label: 'Month', active: true),
        _FilterBtn(label: 'Year', active: false),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool active;

  const _FilterBtn({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: active ? AppColors.primaryTeal : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(int) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onMonthChanged,
  });

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${selectedDate.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarCard — Kartu Kalender Bulanan Menggunakan TableCalendar Library.
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
    // Collect all task dates
    final taskDates = upcomingTasks
        .where((t) => t['due_date'] != null)
        .map((t) => DateTime(t['due_date'].year, t['due_date'].month, t['due_date'].day))
        .toSet();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
        daysOfWeekHeight: 40,
        
        // Custom styling to match user's screenshot
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          outsideTextStyle: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 14),
          defaultTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 14),
          weekendTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 14),
          todayDecoration: const BoxDecoration(
            color: Colors.transparent, // We handle today separately via builders if needed
          ),
          todayTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 14),
        ),
        
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
          weekendStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
        ),

        // Custom builders to match the specific "Teal Highlight" style
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            if (taskDates.contains(normalizedDay)) {
              return _buildHighlightedDay(day, isRange: false);
            }
            return null;
          },
          outsideBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 14),
              ),
            );
          },
          markerBuilder: (context, day, events) => const SizedBox(), // Hide default markers
        ),
      ),
    );
  }

  Widget _buildHighlightedDay(DateTime day, {required bool isRange}) {
    return Center(
      child: Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: AppColors.primaryTeal,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UpcomingTaskSection — Daftar tugas mendatang.
// ─────────────────────────────────────────────────────────────────────────────
class UpcomingTaskSection extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const UpcomingTaskSection({super.key, required this.tasks});

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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
             Center(child: Text('No upcoming tasks', style: GoogleFonts.outfit(color: Colors.grey)))
          else
            ...tasks.map((task) => _TaskCard(task: task)).toList(),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                          style: GoogleFonts.outfit(
                            fontSize: 16,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    task['status_label'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (task['show_delete'] == true) ...[
            const SizedBox(width: 15),
            Icon(Icons.delete_rounded, color: AppColors.primaryTeal.withOpacity(0.6), size: 28),
          ],
        ],
      ),
    );
  }
}
