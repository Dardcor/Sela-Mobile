import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'group_screen.dart';
import 'profile_screen.dart';

class Navbar extends StatefulWidget {
  final int initialIndex;
  const Navbar({super.key, this.initialIndex = 0});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const GroupScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 85,
        margin: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home_filled, 0),
            _navIcon(Icons.calendar_month_rounded, 1),
            _buildAddButton(),
            _navIcon(Icons.people_rounded, 2),
            _navIcon(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/add_project'),
      child: Container(
        height: 60,
        width: 60,
        decoration: const BoxDecoration(
          color: AppColors.primaryTeal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        // Equalizing the hit area and ensuring consistent size
        width: 50,
        height: 50,
        decoration: active 
            ? BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: active ? AppColors.primaryTeal : Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
