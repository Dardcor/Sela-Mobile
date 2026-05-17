import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/colors.dart';
import '../../auth/widgets/auth_form_fields.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileHeader — Header layar Profil (Back + Judul Profile).
// ─────────────────────────────────────────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final VoidCallback onLogoutTap;
  const ProfileHeader({super.key, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background teal
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
        // Konten asli
        Padding(
          padding: EdgeInsets.fromLTRB(
            25,
            MediaQuery.of(context).padding.top + 20,
            25,
            30,
          ),
          child: Row(
            children: [
              const SizedBox(width: 44), // Pengganti tombol back agar judul tetap di tengah
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
                onTap: onLogoutTap,
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
    );
  }
}

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Keluar',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Keluar',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );

      try {
        await NotificationService.unregisterDeviceToken();
        await ApiClient().logout();
      } catch (e) {
        debugPrint('Logout err: $e');
      } finally {
        if (context.mounted) {
          Navigator.pop(context); // close loading
          Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
        }
      }
    }
  }

// ─────────────────────────────────────────────────────────────────────────────
// ChangePasswordModal — Modal untuk mengganti password
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordModal extends StatefulWidget {
  final Future<void> Function(String oldPass, String newPass) onSave;

  const ChangePasswordModal({super.key, required this.onSave});

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  int _step = 1; // Step 1: Input old password, Step 2: Input new password

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOldPassword() async {
    final oldPass = _oldPassCtrl.text.trim();
    if (oldPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan kata sandi lama Anda')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/verify-password', data: {
        'password': oldPass,
      });

      // If successful, proceed to step 2
      setState(() {
        _step = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      String errMsg = 'Password salah';
      if (e is DioException && e.response?.data != null) {
        errMsg = e.response!.data['message'] ?? errMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan lengkapi semua bidang')),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru minimal 6 karakter')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await widget.onSave(_oldPassCtrl.text.trim(), newPass);
    } catch (e) {
      setState(() => _isLoading = false);
      String errMsg = 'Failed to change password';
      if (e.toString().contains('Password harus berbeda')) {
        errMsg = 'Password harus berbeda dari password lama';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildPassField(String label, TextEditingController ctrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: true,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700]),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
        ),
        Positioned(
          left: 15,
          top: -11,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Change Password',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.primaryTeal,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: AppColors.primaryTeal, thickness: 1.2),
                const SizedBox(height: 20),
                
                if (_step == 1) ...[
                  _buildPassField('Old Password', _oldPassCtrl),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _isLoading ? null : _verifyOldPassword,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Next',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  _buildPassField('New Password', _newPassCtrl),
                  const SizedBox(height: 25),
                  _buildPassField('Confirm Password', _confirmPassCtrl),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _isLoading ? null : _submitNewPassword,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserInfoCard — Kartu putih berisi Avatar, Nama, Mahasiswa, dan Kelas.
// ─────────────────────────────────────────────────────────────────────────────
class UserInfoCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onEditTap;

  const UserInfoCard({
    super.key,
    required this.profile,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.only(top: 40, bottom: 30),
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightTealBg, width: 1),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.lightTealBg,
              backgroundImage:
                  profile?['avatar_url'] != null &&
                      profile!['avatar_url'].toString().isNotEmpty
                  ? NetworkImage(profile!['avatar_url']) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
            ),
          ),
          const SizedBox(height: 15),
          Builder(
            builder: (_) {
              String displayName = profile?['full_name'] ?? '';
              if (displayName.trim().isEmpty) {
                displayName = profile?['username'] ?? 'User Name';
              }
              final truncated = displayName.length > 15
                  ? '${displayName.substring(0, 15)}...'
                  : displayName;
              return Text(
                truncated,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Mahasiswa',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile?['class_name'] ?? 'Class Name',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          _SmallEditButton(label: 'Ubah Profil', onTap: onEditTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AbilitiesCard — Kartu dengan fieldset style bertuliskan "Your ability".
// ─────────────────────────────────────────────────────────────────────────────
class AbilitiesCard extends StatelessWidget {
  final List<String> abilities;
  final VoidCallback onEditTap;

  const AbilitiesCard({
    super.key,
    required this.abilities,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 35, 20, 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.primaryTeal, width: 1.2),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: abilities.isEmpty
                      ? [const SizedBox(height: 40)]
                      : abilities.map((a) => _AbilityTag(label: a)).toList(),
                ),
                const SizedBox(height: 20),
                _SmallEditButton(label: 'Edit Kemampuan', onTap: onEditTap),
              ],
            ),
          ),
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.bgLight,
                child: Text(
                  'Kemampuan Anda',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallEditButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallEditButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityTag extends StatelessWidget {
  final String label;

  const _AbilityTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(
        color: AppColors.primaryTeal,
        strokeWidth: 1.2,
        dash: 4,
        gap: 3,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  _DashPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(15),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// EditProfileModal — Modal untuk mengedit Username dan Class.
// ─────────────────────────────────────────────────────────────────────────────
class EditProfileModal extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Function(String name, String className) onSave;
  final Function(String path) onPhotoChange;

  const EditProfileModal({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onPhotoChange,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameCtrl;
  String? _selectedClass;
  List<String> _classes = [];

  @override
  void initState() {
    super.initState();
    // Gunakan full_name, jika kosong gunakan username
    String? name = widget.profile?['full_name'];
    if (name == null || name.toString().trim().isEmpty) {
      name = widget.profile?['username'];
    }
    _nameCtrl = TextEditingController(text: name?.toString() ?? '');
    
    // Inisialisasi class dari database
    _selectedClass = widget.profile?['class_name'];
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await ApiClient().dio.get('classes');
      final data = response.data;
      List<dynamic> rawList;
      if (data is Map && data.containsKey('data')) {
        rawList = data['data'];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }
      if (mounted) {
        setState(() {
          _classes = rawList.map((e) => e['name']?.toString() ?? e['class_name']?.toString() ?? e.toString()).toList();
          // Jika kelas dari DB tidak ada di API, tambahkan sementara agar tidak kosong di dropdown
          if (_selectedClass != null && 
              _selectedClass!.isNotEmpty && 
              !_classes.contains(_selectedClass)) {
            _classes.insert(0, _selectedClass!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 30, 25, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  try {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70, // Optimize image size
                    );
                    if (image != null && mounted) {
                      widget.onPhotoChange(image.path);
                      Navigator.pop(context); // Close modal after selection
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                        SnackBar(duration: const Duration(milliseconds: 1500), content: Text('Gagal membuka galeri: $e')),
                      );
                    }
                  }
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.lightTealBg,
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.lightTealBg,
                        backgroundImage:
                            widget.profile?['avatar_url'] != null &&
                                widget.profile!['avatar_url']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(widget.profile!['avatar_url'])
                                  as ImageProvider
                            : const AssetImage(
                                'assets/images/default_profile.png',
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Edit Photo Profile',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildField('Username', _nameCtrl),
              const SizedBox(height: 25),
              _buildDropdown(
                'Class',
                _selectedClass,
                _classes,
                (val) => setState(() => _selectedClass = val),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  widget.onSave(_nameCtrl.text, _selectedClass ?? '');
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'Save',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: TextField(
            controller: ctrl,
            maxLength: label == 'Username' ? 20 : null,
            inputFormatters: label == 'Username'
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                    NoLeadingSpaceFormatter(),
                  ]
                : null,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700]),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
        ),
        Positioned(
          left: 15,
          top: -11,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 55,
          padding: const EdgeInsets.only(left: 18, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
            color: Colors.transparent,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                'Select $label',
                style: GoogleFonts.outfit(
                  color: Colors.grey[700],
                  fontSize: 15,
                ),
              ),
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: Colors.grey,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              menuMaxHeight: 250,
            ),
          ),
        ),
        Positioned(
          left: 15,
          top: -11,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EditAbilityModal — Modal untuk menambah/menghapus Ability.
// ─────────────────────────────────────────────────────────────────────────────
class EditAbilityModal extends StatefulWidget {
  final List<String> abilities;
  final Function(List<String> newAbilities) onSave;

  const EditAbilityModal({
    super.key,
    required this.abilities,
    required this.onSave,
  });

  @override
  State<EditAbilityModal> createState() => _EditAbilityModalState();
}

class _EditAbilityModalState extends State<EditAbilityModal> {
  late List<String> _currentAbilities;
  final _newAbilityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentAbilities = List.from(widget.abilities);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 30, 25, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Ability',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 5),
              const Divider(color: AppColors.primaryTeal, thickness: 1.2),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._currentAbilities.asMap().entries.map((entry) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _currentAbilities.removeAt(entry.key),
                                  ),
                                  child: const Icon(
                                    Icons.remove_rounded,
                                    color: AppColors.primaryTeal,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 25, color: Colors.grey.shade200),
                          ],
                        );
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newAbilityCtrl,
                              maxLength: 50,
                              decoration: InputDecoration(
                                hintText: 'Type new ability',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onSubmitted: (_) => _addAbility(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addAbility,
                            child: const Icon(
                              Icons.add_rounded,
                              color: AppColors.primaryTeal,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 10, color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  _addAbility(); // Auto-add if text is left in the input
                  widget.onSave(_currentAbilities);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'Save',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAbility() {
    if (_newAbilityCtrl.text.isNotEmpty) {
      setState(() {
        _currentAbilities.add(_newAbilityCtrl.text);
        _newAbilityCtrl.clear();
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DashedBorderPainter — Untuk menggambar border putus-putus
// ─────────────────────────────────────────────────────────────────────────────
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.borderRadius = 18,
    this.strokeWidth = 1.5,
    this.dashWidth = 5,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    // Mengubah path menjadi dashed path
    PathMetrics pathMetrics = path.computeMetrics();
    Path dashedPath = Path();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// LecturerRegistrationModal — Dialog konfirmasi daftar dosen
// ─────────────────────────────────────────────────────────────────────────────
class LecturerRegistrationModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const LecturerRegistrationModal({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Register to become a\nlecturer',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(color: AppColors.primaryTeal, thickness: 1.2),
                const SizedBox(height: 20),
                Text(
                  'Use this feature to request a change in account access rights to the Lecturer level. Activating this role will unlock teaching-specific modules and functions. The system will create a request ticket and send it to the Administrator. Your account status will be updated as soon as the Administrator approves it.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
