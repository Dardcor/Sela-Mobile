import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  bool isUploadingPhoto = false;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = supabase.channel('profile-screen-changes');

    // Listen for profiles changes for current user
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: (payload) {
        debugPrint('Profile Realtime: Profile updated!');
        _fetchProfile();
      },
    );

    // Listen for profile_abilities changes for current user
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profile_abilities',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        debugPrint('Profile Realtime: Abilities updated!');
        _fetchProfile();
      },
    ).subscribe();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfilePhoto(String imagePath) async {
    try {
      setState(() => isUploadingPhoto = true);
      
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final avatarUrl = await _uploadAvatar(imagePath, userId);
      if (avatarUrl == null) {
        throw Exception('Upload failed. Pastikan Storage Bucket "profiles" sudah dibuat di Supabase.');
      }

      await supabase.from('profiles').update({
        'avatar_url': avatarUrl,
      }).eq('id', userId);

      await _fetchProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  Future<String?> _uploadAvatar(String path, String userId) async {
    try {
      final file = File(path);
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'avatars/$fileName';

      await supabase.storage.from('profiles').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return supabase.storage.from('profiles').getPublicUrl(storagePath);
    } catch (e) {
      return null;
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
        onPhotoChange: _updateProfilePhoto,
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
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppColors.primaryTeal,
        child: Stack(
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
                physics: const AlwaysScrollableScrollPhysics(),
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
            if (isUploadingPhoto)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
               ),
          ],
        ),
      );
}

