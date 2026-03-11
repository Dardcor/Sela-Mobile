import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shared Bottom Navigation Bar used across all main screens.
/// [currentIndex]: 0=Home, 1=Calendar, 2=Add(FAB), 3=Team, 4=Profile
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onAddTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 85,
        margin: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: Icons.home_filled,
              active: currentIndex == 0,
              route: '/dashboard',
            ),
            _NavIcon(
              icon: Icons.calendar_month_rounded,
              active: currentIndex == 1,
              route: '/calendar',
            ),
            GestureDetector(
              onTap: onAddTap ?? () => Navigator.pushNamed(context, '/add_project'),
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
              ),
            ),
            _NavIcon(
              icon: Icons.people_rounded,
              active: currentIndex == 3,
              route: '/team',
            ),
            _NavIcon(
              icon: Icons.person_rounded,
              active: currentIndex == 4,
              route: '/profile',
            ),
          ],
        ),
      ),
    );
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String route;

  const _NavIcon({
    required this.icon,
    required this.active,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active
          ? null
          : () {
              final navigator = Navigator.of(context);
              if (route == '/dashboard') {
                // ✅ Home: pop semua route hingga dashboard, atau push jika belum ada.
                // Ini mencegah stack menumpuk saat user klik Home berkali-kali.
                if (navigator.canPop()) {
                  navigator.popUntil(
                    (r) => r.settings.name == '/dashboard' || !navigator.canPop(),
                  );
                } else {
                  navigator.pushNamed(route);
                }
              } else {
                // ✅ Tab lain: pushNamed agar stack tetap ada.
                // Sekarang back button di Calendar/Profile/Team → kembali ke Dashboard ✅
                navigator.pushNamed(route);
              }
            },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: active ? AppColors.primaryTeal : Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
