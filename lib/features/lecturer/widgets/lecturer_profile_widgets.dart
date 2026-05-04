import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LecturerEditProfileModal - Untuk mengubah nama dosen
// ─────────────────────────────────────────────────────────────────────────────
class LecturerEditProfileModal extends StatefulWidget {
  final Map<String, dynamic> profile;
  final ValueChanged<Map<String, dynamic>> onSave;

  const LecturerEditProfileModal({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<LecturerEditProfileModal> createState() => _LecturerEditProfileModalState();
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
                        child: const Icon(Icons.close, color: AppColors.primaryTeal, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: AppColors.primaryTeal, thickness: 1.2),
                const SizedBox(height: 20),
                
                // Form Fields
                _buildField('Nama Lengkap', _nameCtrl),
                
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    final updatedProfile = Map<String, dynamic>.from(widget.profile);
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
// LecturerEditClassModal - Untuk menambah/menghapus kelas yang dipantau
// ─────────────────────────────────────────────────────────────────────────────
class LecturerEditClassModal extends StatefulWidget {
  final List<Map<String, dynamic>> currentClasses;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const LecturerEditClassModal({
    super.key,
    required this.currentClasses,
    required this.onSave,
  });

  @override
  State<LecturerEditClassModal> createState() => _LecturerEditClassModalState();
}

class _LecturerEditClassModalState extends State<LecturerEditClassModal> {
  late List<Map<String, dynamic>> _tempClasses;
  final _newClassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bikin salinan dari list aslinya agar tak langsung mengubah data asli
    _tempClasses = List<Map<String, dynamic>>.from(widget.currentClasses);
  }

  @override
  void dispose() {
    _newClassCtrl.dispose();
    super.dispose();
  }

  void _addClass() {
    final text = _newClassCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tempClasses.add({
          'id': 'c_new_${DateTime.now().millisecondsSinceEpoch}',
          'name': text,
          'total_groups': 0,
          'total_tasks': 0,
          'last_updated': 'Just now',
        });
        _newClassCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
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
                      'Edit Class',
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
                      child: const Icon(Icons.close, color: AppColors.primaryTeal, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(color: AppColors.primaryTeal, thickness: 1.2),
              const SizedBox(height: 20),
              
              // Dynamic List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._tempClasses.asMap().entries.map((entry) {
                        int index = entry.key;
                        var classItem = entry.value;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    classItem['name'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _tempClasses.removeAt(index);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 20, color: Colors.grey.shade200),
                          ],
                        );
                      }),
                      
                      // Input Form to add new Class
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newClassCtrl,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppColors.primaryTeal,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add new class...',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addClass(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addClass,
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
                  _addClass(); // Auto-add if text is left in the input
                  widget.onSave(_tempClasses);
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