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
              _NavIcon(
                icon: Icons.home_rounded,
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
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
                ),
              ),
              _NavIcon(
                icon: Icons.groups_rounded,
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
                navigator.pushNamedAndRemoveUntil(route, (r) => false);
              } else {
                navigator.pushNamed(route);
              }
            },
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


