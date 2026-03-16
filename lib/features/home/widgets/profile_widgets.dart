import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileHeader — Header layar Profil (Back + Judul Profile).
// ─────────────────────────────────────────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background teal — Positioned agar tidak memengaruhi tinggi Stack
        // Background tetap visually meluas ke top+230px
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
        // Konten asli — menentukan tinggi Stack yang dilaporkan ke Column
        Padding(
          padding: EdgeInsets.fromLTRB(25, MediaQuery.of(context).padding.top + 20, 25, 30),
          child: Row(
            children: [
              // Tombol back — kiri
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.primaryTeal, size: 24),
                ),
              ),
              const Spacer(),
              // Judul — pill putih tengah
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  'Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Tombol logout — kanan
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.primaryTeal, size: 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserInfoCard — Kartu putih berisi Avatar, Nama, Mahasiswa, dan Kelas.
// ─────────────────────────────────────────────────────────────────────────────
class UserInfoCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onEditTap;

  const UserInfoCard({super.key, required this.profile, required this.onEditTap});

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
              backgroundImage: profile?['avatar_url'] != null && profile!['avatar_url'].toString().isNotEmpty
                  ? NetworkImage(profile!['avatar_url']) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            profile?['full_name'] ?? profile?['username'] ?? 'User Name',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Mahasiswa',
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            profile?['class_name'] ?? 'Class Name',
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          _SmallEditButton(label: 'Edit Profile', onTap: onEditTap),
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

  const AbilitiesCard({super.key, required this.abilities, required this.onEditTap});

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
                _SmallEditButton(label: 'Edit ability', onTap: onEditTap),
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
                color: AppColors.bgLight, // Match screen background
                child: Text(
                  'Your ability',
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
      painter: _DashPainter(color: AppColors.primaryTeal, strokeWidth: 1.2, dash: 4, gap: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
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

  _DashPainter({required this.color, required this.strokeWidth, required this.dash, required this.gap});

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
  final List<String> _classes = ['2 - D3 IT B', '2 - D3 IT A', '1 - D3 IT B', '1 - D3 IT A'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?['full_name'] ?? '');
    _selectedClass = widget.profile?['class_name'] ?? _classes[0];
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal membuka galeri: $e')),
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
                        border: Border.all(color: AppColors.lightTealBg, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.lightTealBg,
                        backgroundImage: widget.profile?['avatar_url'] != null && widget.profile!['avatar_url'].toString().isNotEmpty
                            ? NetworkImage(widget.profile!['avatar_url']) as ImageProvider
                            : const AssetImage('assets/images/default_profile.png'),
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
              _buildDropdown('Class', _selectedClass, _classes, (val) => setState(() => _selectedClass = val)),
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
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryTeal, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700]))))
                  .toList(),
              onChanged: onChanged,
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

  const EditAbilityModal({super.key, required this.abilities, required this.onSave});

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
                                Text(entry.value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                                GestureDetector(
                                  onTap: () => setState(() => _currentAbilities.removeAt(entry.key)),
                                  child: const Icon(Icons.remove_rounded, color: AppColors.primaryTeal, size: 28),
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
                              decoration: InputDecoration(
                                hintText: 'Type new ability',
                                hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 16),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addAbility(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addAbility,
                            child: const Icon(Icons.add_rounded, color: AppColors.primaryTeal, size: 28),
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
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
