import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileTopBar — Header navigasi "My Profile" (back + judul).
// const-safe karena tidak menyimpan state, hanya menerima action navigasi.
// ─────────────────────────────────────────────────────────────────────────────
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
            ),
          ),
          Text(
            'My Profile',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileInfoSection — Bagian avatar + nama + kelas pengguna.
// Diekstrak agar hanya bagian ini yang di-rebuild saat profil dimuat.
// ─────────────────────────────────────────────────────────────────────────────
class ProfileInfoSection extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const ProfileInfoSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?['full_name'] ?? profile?['username'] ?? 'User';
    final className = profile?['class_name'] ?? 'Software Enginner';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(
              child: profile?['avatar_url'] != null
                  ? Image.network(profile!['avatar_url'], fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 50, color: AppColors.primaryTeal),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                className,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileMenuList — Daftar menu (My Team, My Project, dll.) dengan navigasi.
// Diekstrak agar hanya bagian ini yang di-rebuild saat item ditekan.
// ─────────────────────────────────────────────────────────────────────────────
class ProfileMenuList extends StatelessWidget {
  const ProfileMenuList({super.key});

  static const _items = [
    {'label': 'My Team', 'route': '/team'},
    {'label': 'My Project', 'route': '/add_project'},
    {'label': 'My Profile', 'route': null},
    {'label': 'Email', 'route': null},
    {'label': 'Account', 'route': null},
    {'label': 'Notification', 'route': null},
  ];

  static const _icons = [
    Icons.people_outline,
    Icons.description_outlined,
    Icons.person_outline,
    Icons.email_outlined,
    Icons.shield_outlined,
    Icons.notifications_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final route = item['route'] as String?;
          return GestureDetector(
            onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(_icons[i], color: Colors.white, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
