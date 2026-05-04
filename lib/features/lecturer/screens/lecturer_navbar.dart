import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'lecturer_dashboard_screen.dart';
import 'lecturer_profile_screen.dart';

class LecturerNavbar extends StatefulWidget {
  final int initialIndex;
  const LecturerNavbar({super.key, this.initialIndex = 0});

  @override
  State<LecturerNavbar> createState() => _LecturerNavbarState();
}

class _LecturerNavbarState extends State<LecturerNavbar> {
  late int _selectedIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Dosen hanya punya 2 tab: Dashboard dan Profile
    _screens = [
      const LecturerDashboardScreen(),
      const LecturerProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          LecturerBottomNavBar(
            currentIndex: _selectedIndex,
            onTabTap: _onItemTapped,
          ),
        ],
      ),
    );
  }
}

class LecturerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabTap;

  const LecturerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil padding bawah layar agar navbar tidak tertutup gesture bar di perangkat modern
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      bottom: bottomPadding + 20, // 20 adalah jarak dasar + ukuran safe area
      left: 30,
      right: 30,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home (Index 0)
            GestureDetector(
              onTap: () => onTabTap(0),
              child: Icon(
                Icons.home_filled,
                size: 28,
                color: currentIndex == 0 ? AppColors.primaryTeal : Colors.grey.shade400,
              ),
            ),
            
            // Profile (Index 1)
            GestureDetector(
              onTap: () => onTabTap(1),
              child: Icon(
                Icons.person,
                size: 28,
                color: currentIndex == 1 ? AppColors.primaryTeal : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
