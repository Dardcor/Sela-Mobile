import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/services/connectivity_service.dart';
import '../../auth/utils/auth_error_utils.dart';
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
    _realtimeChannel!
        .onPostgresChanges(
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
        )
        .subscribe();
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
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Fetch abilities
      final abilitiesData = await supabase
          .from('profile_abilities')
          .select('ability')
          .eq('user_id', userId);
      final List<String> fetchedAbilities = (abilitiesData as List)
          .map((e) => e['ability'] as String)
          .toList();

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
    if (name.length > 20) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(duration: Duration(milliseconds: 1500), content: Text('Username maksimal 20 karakter'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9 ]*$');
    if (!usernameRegex.hasMatch(name)) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500), 
            content: Text('Username hanya boleh mengandung huruf, angka, dan spasi di tengah'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({'full_name': name, 'class_name': className})
          .eq('id', userId);

      _fetchProfile();
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateProfilePhoto(String imagePath) async {
    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      setState(() => isUploadingPhoto = true);

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final avatarUrl = await _uploadAvatar(imagePath, userId);
      if (avatarUrl == null) {
        throw Exception(
          'Upload failed. Pastikan Storage Bucket "profiles" sudah dibuat di Supabase.',
        );
      }

      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);

      await _fetchProfile();

      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(duration: Duration(milliseconds: 1500), content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
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

      await supabase.storage
          .from('profiles')
          .upload(
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
    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Delete existing
      await supabase.from('profile_abilities').delete().eq('user_id', userId);

      // Insert new
      if (newAbilities.isNotEmpty) {
        await supabase
            .from('profile_abilities')
            .insert(
              newAbilities
                  .map((a) => {'user_id': userId, 'ability': a})
                  .toList(),
            );
      }

      _fetchProfile();
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
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
      builder: (context) =>
          EditAbilityModal(abilities: abilities, onSave: _updateAbilities),
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user?.email == null) throw Exception('Email not found');

      // 1. Verify old password by attempting to sign in
      await supabase.auth.signInWithPassword(
        email: user!.email!,
        password: oldPassword,
      );

      // 2. Update to new password
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (mounted) {
        Navigator.pop(context); // close modal
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.message)) {
          showNoInternetSnackBar(context);
        } else {
          String msg = e.message;
          if (msg.contains('invalid_credentials') || msg.contains('Invalid login credentials')) {
            msg = 'Email atau Password lama salah.';
          }
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.toString())) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(content: Text('Failed to change password: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordModal(onSave: _changePassword),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _fetchProfile,
    color: AppColors.primaryTeal,
    child: Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfileHeader(),
              const SizedBox(height: 20),
              UserInfoCard(profile: profile, onEditTap: _showEditProfile),
              const SizedBox(height: 35),
              // Abilities Card
              AbilitiesCard(abilities: abilities, onEditTap: _showEditAbility),
              const SizedBox(height: 35),
              // Change Password Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showChangePassword,
                  icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                  label: Text(
                    'Change Password',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 140),
            ],
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
