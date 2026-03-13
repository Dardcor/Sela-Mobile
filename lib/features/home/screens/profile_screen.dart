import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profile;
  List<String> abilities = [];
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

      // Fetch profile
      final profileData = await supabase.from('profiles').select().eq('id', userId).single();
      
      // Fetch abilities
      final abilitiesData = await supabase.from('profile_abilities').select('ability').eq('user_id', userId);
      final List<String> fetchedAbilities = (abilitiesData as List).map((e) => e['ability'] as String).toList();

      if (mounted) {
        setState(() {
          profile = profileData;
          abilities = fetchedAbilities;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile(String name, String className) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'full_name': name,
        'class_name': className,
      }).eq('id', userId);

      _fetchProfile();
    } catch (e) {
      // error handling
    }
  }

  Future<void> _updateAbilities(List<String> newAbilities) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Delete existing
      await supabase.from('profile_abilities').delete().eq('user_id', userId);

      // Insert new
      if (newAbilities.isNotEmpty) {
        await supabase.from('profile_abilities').insert(
          newAbilities.map((a) => {'user_id': userId, 'ability': a}).toList(),
        );
      }

      _fetchProfile();
    } catch (e) {
      // error handling
    }
  }

  void _showEditProfile() {
    showDialog(
      context: context,
      builder: (context) => EditProfileModal(
        profile: profile,
        onSave: _updateProfile,
      ),
    );
  }

  void _showEditAbility() {
    showDialog(
      context: context,
      builder: (context) => EditAbilityModal(
        abilities: abilities,
        onSave: _updateAbilities,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF1F8F9),
        body: Stack(
          children: [
            // Dark Teal Header with Curved Bottom Effect
            Container(
              width: double.infinity,
              height: 380,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const ProfileHeader(),
                    const SizedBox(height: 20),
                    // Information Card that overlaps the header
                    UserInfoCard(
                      profile: profile,
                      onEditTap: _showEditProfile,
                    ),
                    const SizedBox(height: 35),
                    // Abilities Card
                    AbilitiesCard(
                      abilities: abilities,
                      onEditTap: _showEditAbility,
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
            const AppBottomNavBar(currentIndex: 4),
          ],
        ),
      );
}

