import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/api_client.dart';
import '../../auth/utils/auth_error_utils.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  List<String> abilities = [];
  bool isLoading = true;
  bool isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      // Fetch profile
      final response = await ApiClient().dio.get('/me');
      final profileData = response.data['user'];

      // Fetch abilities
      final abilitiesResponse = await ApiClient().dio.get('/profile_abilities');
      final List<String> fetchedAbilities = (abilitiesResponse.data['abilities'] as List)
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
      debugPrint('Error fetching profile: $e');
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
      await ApiClient().dio.put('/me', data: {'full_name': name, 'class_name': className});
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

      final avatarUrl = await _uploadAvatar(imagePath);
      if (avatarUrl == null) {
        throw Exception('Upload failed.');
      }

      await ApiClient().dio.put('/me', data: {'avatar_url': avatarUrl});

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

  Future<String?> _uploadAvatar(String path) async {
    try {
      final file = File(path);
      final fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await ApiClient().dio.post('/upload/avatar', data: formData);
      return response.data['url'];
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  Future<void> _updateAbilities(List<String> newAbilities) async {
    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      await ApiClient().dio.put('/profile_abilities', data: {'abilities': newAbilities});

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
      await ApiClient().dio.post('/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      if (context.mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errMsg = e.response!.data['message'] ?? 'Failed to change password';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
          );
        }
        // Stop propagation so modal doesn't close on failure if thrown inside widgets
        throw Exception(errMsg); 
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password: $e'), backgroundColor: Colors.red),
          );
        }
        throw Exception(e);
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgLight,
    body: RefreshIndicator(
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
    ),
  );
}