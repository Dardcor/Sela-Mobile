import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shared Bottom Navigation Bar used across all main screens.
/// [currentIndex]: 0=Home, 1=Calendar, 2=Add(FAB), 3=Team, 4=Profile
/// [onTabTap]: optional — jika diisi, navigasi menggunakan callback (untuk IndexedStack shell).
///             Jika kosong, navigasi menggunakan Navigator.pushNamed (untuk screen standalone).
class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final VoidCallback? onAddTap;
  final void Function(int)? onTabTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onAddTap,
    this.onTabTap,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  bool _isPressed = false; // State untuk mendeteksi apakah tombol Add sedang ditekan

  @override
  Widget build(BuildContext context) {
    // Gunakan 'viewPadding' (statis) atau abaikan bottomInset dari keyboard
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    // Set fixed padding minimal 16 jika viewPadding tidak tersedia
    final bottomInset = bottomPadding > 0 ? bottomPadding : 16.0;
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;
    final horizontalMargin = isTablet
        ? 32.0
        : (screenWidth < 360 ? 16.0 : 25.0);
    final barHeight = isTablet ? 84.0 : 80.0;
    final fabSize = isTablet ? 56.0 : 52.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: barHeight,
        margin: EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          bottomInset + 8, // Hanya menggunakan padding dagu/notch perangkat yang statis
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavIcon(
              icon: Icons.home_rounded,
              active: widget.currentIndex == 0,
              route: '/dashboard',
              index: 0,
              onTabTap: widget.onTabTap,
            ),
            _NavIcon(
              icon: Icons.calendar_month_rounded,
              active: widget.currentIndex == 1,
              route: '/calendar',
              index: 1,
              onTabTap: widget.onTabTap,
            ),
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.currentIndex == 2 
                ? null 
                : () {
                    // Sekarang karena semua disatukan dalam Navbar, cukup gunakan callback yang sama
                    if (widget.onTabTap != null) {
                      widget.onTabTap!(2);
                    }
                  },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: fabSize,
                width: fabSize,
                // Tombol akan terus naik jika kita sedang berada di halaman Add Project (index == 2)
                transform: Matrix4.translationValues(
                    0.0, (_isPressed || widget.currentIndex == 2) ? -8.0 : 0.0, 0.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(15),
                  // Tombol akan terus bercahaya (menyala) jika kita berada di halaman Add Project
                  boxShadow: (_isPressed || widget.currentIndex == 2)
                      ? [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [],
                ),
                child: AnimatedScale(
                  // Ikon bertambah besar sedikit jika halaman sedang aktif
                  scale: widget.currentIndex == 2 ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: isTablet ? 36 : 34,
                  ),
                ),
              ),
            ),
            _NavIcon(
              icon: Icons.groups_rounded,
              active: widget.currentIndex == 3,
              route: '/team',
              index: 3,
              onTabTap: widget.onTabTap,
            ),
            _NavIcon(
              icon: Icons.person_rounded,
              active: widget.currentIndex == 4,
              route: '/profile',
              index: 4,
              onTabTap: widget.onTabTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String route;
  final int index;
  final void Function(int)? onTabTap;

  const _NavIcon({
    required this.icon,
    required this.active,
    required this.route,
    required this.index,
    this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active
          ? null
          : () {
              if (onTabTap != null) {
                // Mode shell: switch tab via IndexedStack
                onTabTap!(index);
              } else {
                // Mode standalone: navigasi via route
                if (ModalRoute.of(context)?.isCurrent == true) {
                  final navigator = Navigator.of(context);
                  if (route == '/dashboard') {
                    navigator.pushNamedAndRemoveUntil(route, (r) => false);
                  } else {
                    navigator.pushNamed(route);
                  }
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: active ? AppColors.lightTealBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: active ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Icon(
            icon,
            color: active ? AppColors.primaryTeal : Colors.grey[400],
            size: 28,
          ),
        ),
      ),
    );
  }
}
