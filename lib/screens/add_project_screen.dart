import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final supabase = Supabase.instance.client;
  bool isGroup = true;
  final titleCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  
  List<dynamic> userGroups = [];
  dynamic selectedGroup;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final res = await supabase.from('groups').select('*, group_members!inner(user_id)').eq('group_members.user_id', supabase.auth.currentUser!.id);
    if (mounted) setState(() => userGroups = res);
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 80),
            const SizedBox(height: 20),
            Text('Success!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Task successfully added', style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back to previous screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text('OK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (titleCtrl.text.isEmpty) return;
    if (isGroup && selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }
    
    setState(() => isLoading = true);
    try {
      await supabase.from('tasks').insert({
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'due_date': dateCtrl.text.isNotEmpty ? DateFormat('MM/dd/yyyy').parse(dateCtrl.text).toIso8601String() : null,
        'link': linkCtrl.text,
        'is_group': isGroup,
        'group_id': isGroup ? selectedGroup['id'] : null,
        'created_by': supabase.auth.currentUser!.id,
      });
      
      if (mounted) {
        setState(() => isLoading = false);
        _showSuccessPopup();
      }
    } catch (e) { 
      debugPrint('Save err: $e'); 
      if (mounted) setState(() => isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(children: [
        SingleChildScrollView(child: Column(children: [
          _header(),
          const SizedBox(height: 30),
          _toggleSec(),
          const SizedBox(height: 30),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Column(children: [
            _field('Title', 'Enter a task title', titleCtrl),
            const SizedBox(height: 25),
            _field('Due Date', 'mm/dd/yyyy', dateCtrl, icon: Icons.calendar_today_rounded, tap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) dateCtrl.text = DateFormat('MM/dd/yyyy').format(d);
            }),
            const SizedBox(height: 25),
            if (isGroup) ...[
              _dropdown('Grup', 'Select a group', selectedGroup?['id'], userGroups.map((g) => g as Map<String, dynamic>).toList(), (v) => setState(() => selectedGroup = userGroups.firstWhere((g) => g['id'] == v))),
              const SizedBox(height: 25),
            ],
            _field('Description', 'Description', descCtrl, lines: 4),
            const SizedBox(height: 30),
            Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('Support', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13))), const Expanded(child: Divider())]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: _field('Link', 'Enter a link', linkCtrl)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {}, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Text('Add', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ]),
            const SizedBox(height: 25),
            _uploadSec(),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity, height: 58, 
              child: ElevatedButton(
                onPressed: isLoading ? null : _save, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5, shadowColor: AppColors.primaryTeal.withOpacity(0.3)
                ), 
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Save', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))
              )
            ),
            const SizedBox(height: 120),
          ])),
        ])),
        _bottomNav(),
      ]),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(25, 55, 25, 0), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, size: 20))), 
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), 
        child: Text('Add Task', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal))
      ), 
      const SizedBox(width: 36)
    ])
  );

  Widget _toggleSec() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25), 
    height: 52, 
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35)), 
    child: Row(children: [
      Expanded(child: GestureDetector(onTap: () => setState(() => isGroup = true), child: Container(decoration: BoxDecoration(color: isGroup ? AppColors.primaryTeal : Colors.transparent, borderRadius: BorderRadius.circular(35)), child: Center(child: Text('Group', style: GoogleFonts.outfit(color: isGroup ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))))),
      Expanded(child: GestureDetector(onTap: () => setState(() => isGroup = false), child: Container(decoration: BoxDecoration(color: !isGroup ? AppColors.primaryTeal : Colors.transparent, borderRadius: BorderRadius.circular(35)), child: Center(child: Text('Individual', style: GoogleFonts.outfit(color: !isGroup ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))))),
    ])
  );

  Widget _field(String label, String hint, TextEditingController ctrl, {IconData? icon, VoidCallback? tap, int lines = 1}) => Stack(clipBehavior: Clip.none, children: [
    Container(height: lines == 1 ? 52 : null, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryTeal, width: 1.2)), child: TextField(controller: ctrl, maxLines: lines, readOnly: tap != null, onTap: tap, decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: GoogleFonts.outfit(color: Colors.grey[400]), suffixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null))),
    Positioned(left: 14, top: -10, child: Container(color: const Color(0xFFF1F8F9), padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(label, style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)))),
  ]);

  Widget _dropdown(String label, String hint, String? val, List<Map<String, dynamic>> items, Function(String?) tap) => Stack(clipBehavior: Clip.none, children: [
    Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryTeal, width: 1.2)), 
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        isExpanded: true, 
        value: val, 
        hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[400])), 
        icon: Icon(Icons.expand_more, color: Colors.grey[300]), 
        items: items.map((e) => DropdownMenuItem<String>(value: e['id'] as String, child: Text(e['name'] ?? '', style: GoogleFonts.outfit(color: Colors.black)))).toList(), 
        onChanged: tap
      ))
    ),
    Positioned(left: 14, top: -10, child: Container(color: const Color(0xFFF1F8F9), padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(label, style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)))),
  ]);

  Widget _uploadSec() => Container(
    width: double.infinity, height: 130, 
    decoration: BoxDecoration(border: Border.all(color: AppColors.primaryTeal, style: BorderStyle.solid, width: 1.5), borderRadius: BorderRadius.circular(25), color: Colors.white), 
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_upload_rounded, color: AppColors.primaryTeal, size: 45),
      const SizedBox(height: 10),
      Text('Upload your file here', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 8),
      Text('Browse', style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
    ])
  );

  Widget _bottomNav() => Align(alignment: Alignment.bottomCenter, child: Container(height: 85, margin: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(45), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _navIcon(Icons.home_filled, false, '/dashboard'), _navIcon(Icons.calendar_month, false, '/calendar'),
    Container(height: 60, width: 60, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 35)),
    _navIcon(Icons.people, false, '/team'), _navIcon(Icons.person, false, '/profile'),
  ])));

  Widget _navIcon(IconData i, bool active, String route) => GestureDetector(onTap: () => Navigator.pushReplacementNamed(context, route), child: Icon(i, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 32));
}
