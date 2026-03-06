import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildTitleSection(),
                const SizedBox(height: 20),
                _buildCalendarCard(),
                const SizedBox(height: 30),
                _buildListScheduleHeader(),
                const SizedBox(height: 15),
                _buildScheduleList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildBottomNavBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              'Calender',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 44), // Alignment spacing
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Your',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Shcedule', // Keeping typo from image as requested "persis sesuai gambar"
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Feb,2026',
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 5),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleBtn(),
              _buildCircleBtn(),
            ],
          ),
          const SizedBox(height: 10),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCircleBtn() {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Correct days for Feb 2026 starting on Sunday
    // Layout: Mon Tue Wed Thu Fri Sat Sun
    // Row 1: 27 28 29 30 31 (Jan) 1 (Sun)
    // Row 2: 2 3 4 5 6 7 8
    // etc.
    // In image, Feb 1 is Saturday (meaning Feb 2025). 
    // User requested Feb 2026.
    // However, user said "wajib persis seperti gambar" (must be exactly like image).
    // The image shows Feb 1st under Saturday.
    // I will use Feb 2026 headers but layout might differ. 
    // Actually, I'll match the VISUAL structure of the image (Feb 1 on Sat) but label it 2026 if requested.
    // But Feb 2026 Feb 1st is SUNDAY. 
    // I'll make it correctly for Feb 2026.
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: (day == 'Sat' || day == 'Sun') ? AppColors.primaryTeal : Colors.grey[400],
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 15),
        _buildCalendarRows(),
      ],
    );
  }

  Widget _buildCalendarRows() {
    // Feb 2026: Feb 1 is Sunday.
    // Column 1 is Mon.
    // Row 1: [26, 27, 28, 29, 30, 31, 1]
    return Column(
      children: [
        _buildDayRow(['26', '27', '28', '29', '30', '31', '1']),
        const SizedBox(height: 10),
        _buildDayRow(['2', '3', '4', '5', '6', '7', '8'], highlights: {'3-5': 'Project laravel'}),
        const SizedBox(height: 10),
        _buildDayRow(['9', '10', '11', '12', '13', '14', '15']),
        const SizedBox(height: 10),
        _buildDayRow(['16', '17', '18', '19', '20', '21', '22'], highlights: {'18-21': 'Project laravel'}),
        const SizedBox(height: 10),
        _buildDayRow(['23', '24', '25', '26', '27', '28', '1']),
      ],
    );
  }

  Widget _buildDayRow(List<String> values, {Map<String, String>? highlights}) {
    // Logic to handle "Project Laravel" spans
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (int i = 0; i < 7; i++)
          _buildDayCell(values[i], highlights: highlights, index: i),
      ],
    );
  }

  Widget _buildDayCell(String val, {Map<String, String>? highlights, int index = 0}) {
    bool isNextPrevMonth = (index < 5 && val.length > 1 && int.parse(val) > 20) || (index > 5 && val == '1');
    
    // Check for "3-5" highlight span
    if (highlights != null) {
      if (highlights.containsKey('3-5') && (val == '3' || val == '4' || val == '5')) {
        bool isStart = val == '3';
        bool isEnd = val == '5';
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isStart) 
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Text('Project laravel', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                if (isStart)
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: Text('3 Feb - 5 Feb', style: GoogleFonts.outfit(fontSize: 6, color: Colors.grey)),
                  ),
                if (isEnd)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ),
                if (!isStart && !isEnd) Container(), // Mid portion
              ],
            ),
          ),
        );
      }
      
      if (highlights.containsKey('18-21') && (val == '18' || val == '19' || val == '20' || val == '21')) {
        bool isStart = val == '18';
        bool isEnd = val == '21';
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isStart) 
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Text('Project laravel', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                if (isStart)
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: Text('18 Feb - 21 Feb', style: GoogleFonts.outfit(fontSize: 6, color: Colors.grey)),
                  ),
                if (isEnd)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle)),
                  ),
              ],
            ),
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

  Widget _buildListScheduleHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'List schedule',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Search', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Very light blue
                  shape: BoxShape.circle,
                ),
                child: Icon(index == 0 ? Icons.people : Icons.person, color: AppColors.primaryTeal, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ecomerse AWS', // Match typo in image as requested "persis sesuai gambar"
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Workshop Aplikasi dan Komputasi Awan',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 78, margin: const EdgeInsets.only(left: 22, right: 22, bottom: 22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navIcon(context, Icons.home_filled, false, '/dashboard'),
          _navIcon(context, Icons.calendar_month, true, '/calendar'),
          GestureDetector(onTap: () => Navigator.pushNamed(context, '/add_project'), child: Container(height: 54, width: 54, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 30))),
          _navIcon(context, Icons.people_outline, false, '/team'),
          _navIcon(context, Icons.person_outline, false, '/profile'),
        ]),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, bool active, String route) {
    return GestureDetector(
      onTap: active ? null : () => Navigator.pushReplacementNamed(context, route),
      child: Container(padding: const EdgeInsets.all(9), decoration: active ? BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.12), shape: BoxShape.circle) : null, child: Icon(icon, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 28)),
    );
  }
}
