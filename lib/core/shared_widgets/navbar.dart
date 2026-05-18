import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'app_bottom_nav_bar.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/tasks/screens/calendar_screen.dart';
import '../../features/tasks/screens/add_project_screen.dart';
import '../../features/groups/screens/group_screen.dart';
import '../../features/home/screens/profile_screen.dart';

/// App shell utama yang mengelola navigasi tab via PageView.
/// Gunakan [initialIndex] untuk menentukan tab yang aktif saat pertama dibuka:
/// 0=Home, 1=Calendar, 2=Add Task, 3=Team, 4=Profile
class Navbar extends StatefulWidget {
  final int initialIndex;
  const Navbar({super.key, this.initialIndex = 0});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late int _selectedIndex;
  late final PageController _pageController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Semua layar kini disatukan ke dalam satu deretan PageView
    _screens = [
      DashboardScreen(onNavigateTab: _onItemTapped),
      const CalendarScreen(),
      const AddProjectScreen(), // Layar Tambah Tugas sekarang tergabung di index ke-2
      const GroupScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Mengubah layar melalui Bottom Nav Bar
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    // Perbedaan indeks menentukan seberapa jauh kita menggeser
    int indexDifference = (index - _selectedIndex).abs();
    
    // Jika tujuannya loncat jauh (misal dari Home ke Profile), 
    // percepat sedikit animasinya agar terlihat gesit namun tetap meluncur mulus
    int duration = 300 + (indexDifference * 50);

    // Beralih secara mulus menggunakan animasi geser bawaan PageView
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: duration),
      curve: Curves.easeOutCubic,
    );
  }

  // Mengupdate status state saat pengguna menggeser (swipe) layar dengan jari
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi untuk mencegat tombol "Back" (Kembali) dari HP pengguna
  Future<bool> _onWillPop() async {
    // Jika tidak berada di halaman Dashboard (index 0), kembalikan ke Dashboard dulu
    if (_selectedIndex != 0) {
      _onItemTapped(0);
      return false; // Jangan keluar aplikasi
    }

    // Jika sudah di Dashboard, munculkan konfirmasi keluar
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Keluar Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Outfit')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        resizeToAvoidBottomInset: false, // Mencegah Navbar terangkat saat keyboard muncul
        body: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Kunci PageView agar dimensinya tetap utuh setinggi layar asli (tidak tertekan)
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(), // Efek memantul saat mentok di ujung
                children: _screens,
              ),
            ),
            // Menggunakan AppBottomNavBar dengan onTabTap
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNavBar(
                currentIndex: _selectedIndex,
                onTabTap: _onItemTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
