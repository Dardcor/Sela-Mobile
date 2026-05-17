import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import '../widgets/lecturer_profile_widgets.dart';
import '../../home/widgets/profile_widgets.dart';

class LecturerProfileScreen extends StatefulWidget {
  const LecturerProfileScreen({super.key});

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('me'),
        ApiClient().dio.get('lecturer/classes'),
      ]);
      final profileData = responses[0].data['user'] ??
          responses[0].data['data'] ??
          responses[0].data;
      setState(() {
        _profile = {
          'name': profileData['full_name'] ?? profileData['username'] ?? '',
          'role': 'Dosen',
          'avatar': profileData['avatar_url'],
        };
        _classes =
            List<Map<String, dynamic>>.from(responses[1].data['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Profile fetch error: $e');
    }
  }

  // ── Avatar upload (mirrors student ProfileScreen logic) ──

  Future<String?> _uploadAvatar(String path) async {
    try {
      final file = File(path);
      final fileName = file.path.split(Platform.pathSeparator).last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response =
          await ApiClient().dio.post('/upload/avatar', data: formData);
      return response.data['url'];
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  Future<void> _updateProfilePhoto(String imagePath) async {
    try {
      setState(() => _isUploadingPhoto = true);

      final avatarUrl = await _uploadAvatar(imagePath);
      if (avatarUrl == null) {
        throw Exception('Upload failed.');
      }

      await ApiClient().dio.put('/me', data: {'avatar_url': avatarUrl});
      await _fetchProfile();

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Foto profil berhasil diperbarui!'),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Edit profile ──

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LecturerEditProfileModal(
        profile: _profile,
        onSave: (updatedProfile) async {
          try {
            await ApiClient()
                .dio
                .put('me', data: {'full_name': updatedProfile['name']});
            await _fetchProfile();
          } catch (e) {
            debugPrint('Update profile error: $e');
          }
        },
        onPhotoChange: _updateProfilePhoto,
      ),
    );
  }

  // ── Pick classes ──

  void _showPickClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LecturerPickClassModal(
        currentClasses: _classes,
        onSave: (selectedClasses) async {
          try {
            // Send names to match backend expectations in LecturerService.php
            final selectedNames = selectedClasses
                .map((c) => c['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();

            final response = await ApiClient()
                .dio
                .put('lecturer/classes', data: {'classes': selectedNames});

            setState(() {
              _classes = List<Map<String, dynamic>>.from(
                  response.data['data'] ?? []);
            });
          } catch (e) {
            debugPrint('Update classes error: $e');
          }
        },
      ),
    );
  }

  // ── Change password ──

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    try {
      await ApiClient().dio.post('/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kata sandi berhasil diperbarui!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errMsg =
            e.response!.data['message'] ?? 'Failed to change password';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
          );
        }
        throw Exception(errMsg);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal mengganti kata sandi: $e'),
                backgroundColor: Colors.red),
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

  // ── Logout ──

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Keluar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        await ApiClient()
            .dio
            .delete('device-tokens', data: {'token': fcmToken});
        await prefs.remove('fcm_token');
      }
      await ApiClient().logout();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/auth', (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');

      // Fallback local logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/auth', (route) => false);
      }
    }
  }

  // ─────────────────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: MediaQuery.of(context).padding.top + 230,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          25,
                          MediaQuery.of(context).padding.top + 20,
                          25,
                          30,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 44),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 35,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Text(
                                'Profil',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _handleLogout(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                        // ── Profile card with avatar ──
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(45),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: (_profile['avatar'] !=
                                                    null &&
                                                (_profile['avatar']
                                                    .startsWith(
                                                        'http')))
                                            ? Image.network(
                                                _profile['avatar'],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context,
                                                        error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                  'assets/images/default_profile.png',
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Image.asset(
                                                'assets/images/default_profile.png',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  _profile['name'] ?? 'User Name',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _profile['role'] ?? 'Role',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                GestureDetector(
                                  onTap: () =>
                                      _showEditProfileDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_rounded,
                                            color: Colors.white,
                                            size: 14),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ubah Profil',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        // ── Your classes card ──
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.primaryTeal
                                      .withOpacity(0.5),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Divider(
                                        color: AppColors.primaryTeal
                                            .withOpacity(0.5),
                                        thickness: 1.5),
                                    Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        'Your class',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.primaryTeal,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: _classes
                                      .map((c) => _buildClassPill(
                                          c['name']?.toString() ??
                                              'Class'))
                                      .toList(),
                                ),
                                const SizedBox(height: 25),
                                GestureDetector(
                                  onTap: () =>
                                      _showPickClassDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.checklist,
                                            color: Colors.white,
                                            size: 14),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pick class',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        // Change Password Button
                        Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 25),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showChangePassword,
                            icon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 5,
                              shadowColor: AppColors.primaryTeal
                                  .withOpacity(0.3),
                            ),
                        ),
                      ),
                        const SizedBox(height: 15),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
            // Upload overlay
            if (_isUploadingPhoto)
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
    

  // ── Pick avatar directly from profile screen ──

  Future<void> _pickAndUploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        await _updateProfilePhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('Gagal membuka galeri: $e'),
            ),
          );
      }
    }
  }

  Widget _buildClassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryTeal,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: AppColors.primaryTeal,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
