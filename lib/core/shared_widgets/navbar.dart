import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'app_bottom_nav_bar.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/tasks/screens/calendar_screen.dart';
import '../../features/groups/screens/group_screen.dart';
import '../../features/home/screens/profile_screen.dart';

/// App shell utama yang mengelola navigasi tab via IndexedStack.
/// Gunakan [initialIndex] untuk menentukan tab yang aktif saat pertama dibuka:
/// 0=Home, 1=Calendar, 3=Team, 4=Profile
class Navbar extends StatefulWidget {
  final int initialIndex;
  const Navbar({super.key, this.initialIndex = 0});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late int _selectedIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      DashboardScreen(onNavigateTab: _onItemTapped),
      const CalendarScreen(),
      const SizedBox.shrink(), // index 2 = tombol Add (tidak ada screen)
      const GroupScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) return; // tombol Add ditangani oleh AppBottomNavBar
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
          // Menggunakan AppBottomNavBar dengan onTabTap agar tidak duplikasi kode tampilan
          AppBottomNavBar(
            currentIndex: _selectedIndex,
            onTabTap: _onItemTapped,
          ),
        ],
      ),
    );
  }
}
