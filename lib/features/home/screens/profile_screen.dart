import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/profile_widgets.dart';

/// ProfileScreen â€” Kerangka layar profil pengguna.
///
/// File ini mengelola pengambilan data profil dari Supabase dan
/// mendelegasikan rendering UI ke komponen di [profile_widgets.dart]:
/// - [ProfileTopBar]       â†’ header navigasi (const, tidak perlu rebuild)
/// - [ProfileInfoSection]  â†’ avatar + nama + kelas (rebuild saat profil dimuat)
/// - [ProfileMenuList]     â†’ daftar menu (const, tidak perlu rebuild)
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
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // âœ… const â€” tidak pernah di-rebuild
                    const ProfileTopBar(),
                    const SizedBox(height: 30),
                    // âœ… Hanya bagian ini yang di-rebuild saat profil dimuat
                    ProfileInfoSection(profile: profile),
                    const SizedBox(height: 40),
                    // âœ… const â€” menu statis, tidak pernah di-rebuild
                    const ProfileMenuList(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            const AppBottomNavBar(currentIndex: 4),
          ],
        ),
      ),
    );
}
