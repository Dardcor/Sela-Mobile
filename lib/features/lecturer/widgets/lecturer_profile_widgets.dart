import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_client.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LecturerEditProfileModal - Edit name + change profile photo
// ─────────────────────────────────────────────────────────────────────────────
class LecturerEditProfileModal extends StatefulWidget {
  final Map<String, dynamic> profile;
  final ValueChanged<Map<String, dynamic>> onSave;
  final Function(String path) onPhotoChange;

  const LecturerEditProfileModal({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onPhotoChange,
  });

  @override
  State<LecturerEditProfileModal> createState() =>
      _LecturerEditProfileModalState();
}

class _LecturerEditProfileModalState extends State<LecturerEditProfileModal> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile['name']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
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
          top: -1,
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
                        'Edit Profile',
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
                        child: const Icon(Icons.close,
                            color: AppColors.primaryTeal, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: AppColors.primaryTeal, thickness: 1.2),
                const SizedBox(height: 20),

                // ── Avatar with tap-to-change ──
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                      );
                      if (image != null && mounted) {
                        widget.onPhotoChange(image.path);
                        Navigator.pop(context);
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
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryTeal.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: ClipOval(
                            child: (widget.profile['avatar'] != null &&
                                    widget.profile['avatar']
                                        .toString()
                                        .startsWith('http'))
                                ? Image.network(
                                    widget.profile['avatar'],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                      'assets/images/default_profile.png',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/default_profile.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Change Photo Profile',
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Form Fields
                _buildField('Nama Lengkap', _nameCtrl),

                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    final updatedProfile =
                        Map<String, dynamic>.from(widget.profile);
                    updatedProfile['name'] = _nameCtrl.text.trim();
                    widget.onSave(updatedProfile);
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
                        'Save Profile',
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

// ─────────────────────────────────────────────────────────────────────────────
// LecturerPickClassModal - Pick class from database list
// ─────────────────────────────────────────────────────────────────────────────
class LecturerPickClassModal extends StatefulWidget {
  final List<Map<String, dynamic>> currentClasses;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const LecturerPickClassModal({
    super.key,
    required this.currentClasses,
    required this.onSave,
  });

  @override
  State<LecturerPickClassModal> createState() =>
      _LecturerPickClassModalState();
}

class _LecturerPickClassModalState extends State<LecturerPickClassModal> {
  List<Map<String, dynamic>> _allClasses = [];
  final Set<String> _selectedNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (final c in widget.currentClasses) {
      final name = c['name']?.toString() ?? '';
      if (name.isNotEmpty) _selectedNames.add(name);
    }
    _fetchAllClasses();
  }

  Future<void> _fetchAllClasses() async {
    try {
      final response = await ApiClient().dio.get('classes');
      final data = response.data;
      List<dynamic> rawList;
      if (data is Map && data.containsKey('data')) {
        rawList = data['data'] as List<dynamic>;
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }
      setState(() {
        _allClasses = List<Map<String, dynamic>>.from(rawList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Fetch classes error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
                      'Pick Class',
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
                      child: const Icon(Icons.close,
                          color: AppColors.primaryTeal, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(color: AppColors.primaryTeal, thickness: 1.2),
              const SizedBox(height: 10),

              // Class list
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child:
                      CircularProgressIndicator(color: AppColors.primaryTeal),
                )
              else if (_allClasses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'No classes available',
                    style:
                        GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _allClasses.map((classItem) {
                        final name = classItem['name']?.toString() ?? '';
                        final isSelected = _selectedNames.contains(name);
                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryTeal
                                  : Colors.grey[700],
                            ),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedNames.add(name);
                              } else {
                                _selectedNames.remove(name);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  final selectedClasses = _allClasses
                      .where((c) => _selectedNames.contains(c['name']?.toString()))
                      .toList();
                  widget.onSave(selectedClasses);
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
}
