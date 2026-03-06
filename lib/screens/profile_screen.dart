import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) setState(() => profile = data);
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    _buildProfileInfo(),
                    const SizedBox(height: 40),
                    _buildMenuList(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              _buildBottomNavBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildProfileInfo() {
    final name = profile?['full_name'] ?? profile?['username'] ?? 'User';
    final className = profile?['class_name'] ?? 'Software Enginner';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
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
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                className,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final items = [
      {'icon': Icons.people_outline, 'label': 'My Team'},
      {'icon': Icons.description_outlined, 'label': 'My Project'},
      {'icon': Icons.person_outline, 'label': 'My Profile'},
      {'icon': Icons.email_outlined, 'label': 'Email'},
      {'icon': Icons.shield_outlined, 'label': 'Account'},
      {'icon': Icons.notifications_outlined, 'label': 'Notification'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              final label = item['label'] as String;
              if (label == 'My Team') {
                Navigator.pushNamed(context, '/team');
              } else if (label == 'My Project') {
                Navigator.pushNamed(context, '/add_project');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
          _navIcon(context, Icons.calendar_month, false, '/calendar'),
          GestureDetector(onTap: () => Navigator.pushNamed(context, '/add_project'), child: Container(height: 54, width: 54, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 30))),
          _navIcon(context, Icons.people_outline, false, '/team'),
          _navIcon(context, Icons.person, true, '/profile'),
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
