import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/network_utils.dart';
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(profileData));

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
            SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Gagal memperbarui profil: $e')),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );

      final avatarUrl = await _uploadAvatar(imagePath);
      if (avatarUrl == null) {
        throw Exception('Upload failed.');
      }

      await ApiClient().dio.put('/me', data: {'avatar_url': avatarUrl});

      await _fetchProfile();

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(duration: Duration(milliseconds: 1500), content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog
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
          const SnackBar(content: Text('Kata sandi berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errMsg = e.response!.data['message'] ?? 'Failed to change password';
        // Stop propagation so modal doesn't close on failure if thrown inside widgets
        throw Exception(errMsg); 
      } else {
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

  Future<void> _handleLogout(BuildContext context) async {
    // Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keluar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    try {
      // Hapus token dan logout via API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        await ApiClient().logout();
      }
      
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      if (context.mounted) {
        Navigator.pop(context); // close loading
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (e) {
      // Walau error di server, tetap paksa logout dari aplikasi lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      if (context.mounted) {
        Navigator.pop(context); // close loading
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
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
                ProfileHeader(onLogoutTap: () => _handleLogout(context)),
                const SizedBox(height: 20),
                UserInfoCard(profile: profile, onEditTap: _showEditProfile),
                const SizedBox(height: 35),
                // Abilities Card
                AbilitiesCard(abilities: abilities, onEditTap: _showEditAbility),
                const SizedBox(height: 35),
                // Ganti Kata Sandi Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showChangePassword,
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                    label: Text(
                      'Ganti Kata Sandi',
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
        ],
      ),
    ),
  );
}