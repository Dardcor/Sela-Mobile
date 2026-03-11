import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CalendarTopBar — Header navigasi layar kalender (back + judul).
// const-safe karena tidak menyimpan state atau konteks berbayar.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarTopBar extends StatelessWidget {
  const CalendarTopBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Text(
              'Calender',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarTitleSection — Judul "Track Your Schedule" + filter bulan.
// Bersifat statis untuk bulan ini; dapat dijadikan const setelah refactor.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarTitleSection extends StatelessWidget {
  const CalendarTitleSection({super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Track Your',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              'Shcedule',
              style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey[500]),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(children: [
              Text('Feb,2026', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(width: 5),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
            ]),
          ),
        ],
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarCard — Kartu kalender bulanan lengkap dengan grid hari.
// Diekstrak agar rebuild kalender tidak memengaruhi bagian layar lain.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _CircleNavBtn(),
          _CircleNavBtn(),
        ]),
        const SizedBox(height: 10),
        const _CalendarGrid(),
      ]),
    );
}

/// Tombol navigasi bulat di pojok kalender.
class _CircleNavBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
    );
}

/// Grid kalender (header hari + baris tanggal).
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: (d == 'Sat' || d == 'Sun') ? AppColors.primaryTeal : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 15),
      const _CalendarRows(),
    ]);
  }
}

/// Seluruh baris tanggal kalender February 2026.
class _CalendarRows extends StatelessWidget {
  const _CalendarRows();

  @override
  Widget build(BuildContext context) => Column(children: [
      _DayRow(values: const ['26', '27', '28', '29', '30', '31', '1']),
      const SizedBox(height: 10),
      _DayRow(
        values: const ['2', '3', '4', '5', '6', '7', '8'],
        highlights: const {'3-5': 'Project laravel'},
      ),
      const SizedBox(height: 10),
      _DayRow(values: const ['9', '10', '11', '12', '13', '14', '15']),
      const SizedBox(height: 10),
      _DayRow(
        values: const ['16', '17', '18', '19', '20', '21', '22'],
        highlights: const {'18-21': 'Project laravel'},
      ),
      const SizedBox(height: 10),
      _DayRow(values: const ['23', '24', '25', '26', '27', '28', '1']),
    ]);
}

/// Satu baris tanggal (7 sel).
class _DayRow extends StatelessWidget {
  final List<String> values;
  final Map<String, String>? highlights;

  const _DayRow({required this.values, this.highlights});

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) => _DayCell(val: values[i], highlights: highlights, index: i)),
    );
}

/// Satu sel hari dalam kalender; menangani highlight rentang tanggal.
class _DayCell extends StatelessWidget {
  final String val;
  final Map<String, String>? highlights;
  final int index;

  const _DayCell({required this.val, this.highlights, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final bool isNextPrevMonth =
        (index < 5 && val.length > 1 && int.parse(val) > 20) || (index > 5 && val == '1');

    if (highlights != null) {
      // Highlight rentang 3–5 Feb
      if (highlights!.containsKey('3-5') && (val == '3' || val == '4' || val == '5')) {
        final bool isStart = val == '3';
        final bool isEnd = val == '5';
        return Expanded(
          flex: 1,
          child: Container(
            height: 50,
            margin: EdgeInsets.only(left: isStart ? 2 : 0, right: isEnd ? 2 : 0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isStart ? 12 : 0),
                bottomLeft: Radius.circular(isStart ? 12 : 0),
                topRight: Radius.circular(isEnd ? 12 : 0),
                bottomRight: Radius.circular(isEnd ? 12 : 0),
              ),
            ),
            child: Stack(alignment: Alignment.center, children: [
              if (isStart)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Text('Project laravel',
                      style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              if (isStart)
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Text('3 Feb - 5 Feb',
                      style: GoogleFonts.outfit(fontSize: 6, color: Colors.grey)),
                ),
              if (isEnd)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
            ]),
          ),
        );
      }

      // Highlight rentang 18–21 Feb
      if (highlights!.containsKey('18-21') &&
          (val == '18' || val == '19' || val == '20' || val == '21')) {
        final bool isStart = val == '18';
        final bool isEnd = val == '21';
        return Expanded(
          flex: 1,
          child: Container(
            height: 50,
            margin: EdgeInsets.only(left: isStart ? 2 : 0, right: isEnd ? 2 : 0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isStart ? 12 : 0),
                bottomLeft: Radius.circular(isStart ? 12 : 0),
                topRight: Radius.circular(isEnd ? 12 : 0),
                bottomRight: Radius.circular(isEnd ? 12 : 0),
              ),
            ),
            child: Stack(alignment: Alignment.center, children: [
              if (isStart)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Text('Project laravel',
                      style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              if (isStart)
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Text('18 Feb - 21 Feb',
                      style: GoogleFonts.outfit(fontSize: 6, color: Colors.grey)),
                ),
              if (isEnd)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ]),
          ),
        );
      }
    }

    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isNextPrevMonth ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isNextPrevMonth ? Colors.grey[300] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarScheduleHeader — Judul "List schedule" + search kecil.
// ─────────────────────────────────────────────────────────────────────────────
class CalendarScheduleHeader extends StatelessWidget {
  const CalendarScheduleHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          'List schedule',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.search, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text('Search', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      ]),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleItem — Satu item jadwal dalam list bawah kalender.
// Diekstrak agar rebuild per-item terisolasi dari seluruh daftar.
// ─────────────────────────────────────────────────────────────────────────────
class ScheduleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isGroup;

  const ScheduleItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
          child: Icon(
            isGroup ? Icons.people : Icons.person,
            color: AppColors.primaryTeal,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
            ),
          ]),
        ),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ]),
    );
}
