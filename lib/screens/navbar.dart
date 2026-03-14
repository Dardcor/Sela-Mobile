import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../features/home/screens/dashboard_screen.dart';
import '../features/tasks/screens/calendar_screen.dart';
import '../features/groups/screens/group_screen.dart';
import '../features/home/screens/profile_screen.dart';

class Navbar extends StatefulWidget {
  final int initialIndex;
  const Navbar({super.key, this.initialIndex = 0});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late int _selectedIndex;

  // Use 5 slots to match indexing (0=Home, 1=Calendar, 2=FAB, 3=Team, 4=Profile)
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      const DashboardScreen(),
      const CalendarScreen(),
      const SizedBox.shrink(), // Placeholder for index 2
      const GroupScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      // Use IndexedStack to keep state alive and make transitions instant
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
        height: 80,
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(Icons.home_rounded, 0),
            _navIcon(Icons.calendar_month_rounded, 1),
            _buildAddButton(),
            _navIcon(Icons.groups_rounded, 3),
            _navIcon(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/add_project'),
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: active
            ? const BoxDecoration(
                color: AppColors.lightTealBg,
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: active ? AppColors.primaryTeal : Colors.black.withOpacity(0.4),
          size: 30,
        ),
      ),
    );
  }
}
