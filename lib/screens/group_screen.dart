import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> teams = [];
  bool isLoading = true;
  final _searchCtrl = TextEditingController();

  final List<String> _courses = [
    'Workshop Aplikasi Bergerak',
    'Praktek Kecerdasan Buatan',
    'Administrasi Jaringan',
    'Konsep Jaringan',
    'Pemrograman Web'
  ];
  final List<String> _classes = ['1 \u2013 D3 IT A', '2 \u2013 D3 IT B', '3 \u2013 D4 SDT A', '4 \u2013 D4 IT B'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final res = await supabase.from('groups').select('*, group_members(*, profiles(*))').order('created_at', ascending: false);
      if (mounted) setState(() => teams = res);
    } catch (e) {
      debugPrint('fetch teams info: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
            Text('Group successfully created', style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text('OK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinCreateModal() {
    String? curCourse; String? curClass; String? curNo;
    final joinCodeCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '4');
    bool inProc = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(ctx).viewInsets.bottom + 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 60, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 30),
                _inputField('Code', 'Input a code', joinCodeCtrl),
                const SizedBox(height: 10),
                Text('*Note: Enter the code from the group', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400])),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final c = joinCodeCtrl.text.trim(); if (c.isEmpty) return;
                      try {
                        // Use RPC function to bypass RLS — allows non-member to look up group by code
                        final results = await supabase.rpc('find_group_by_invite_code', params: {'p_code': c});
                        if (results == null || (results as List).isEmpty) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired code')));
                          return;
                        }
                        final g = results[0];
                        await supabase.from('group_members').insert({'group_id': g['id'], 'user_id': supabase.auth.currentUser!.id, 'role': 'member'});
                        if (mounted) {
                          Navigator.pop(ctx); 
                          _fetch();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully joined group! ✅'), backgroundColor: AppColors.primaryTeal));
                        }
                      } catch (e) { 
                        debugPrint('Join err: $e');
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join. You may already be a member.'))); 
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text('Go to Group', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 25),
                Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text('Or', style: GoogleFonts.outfit(color: Colors.grey[400]))), const Expanded(child: Divider())]),
                const SizedBox(height: 25),
                _dropdownField('Title Group', 'select course', curCourse, _courses, (v) => setS(() => curCourse = v)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _dropdownField('select a class', 'select a class', curClass, _classes, (v) => setS(() => curClass = v))),
                  const SizedBox(width: 15),
                  Expanded(child: _dropdownField('choose a number', 'choose a number', curNo, ['Kelompok 1','Kelompok 2','Kelompok 3','Kelompok 4'], (v) => setS(() => curNo = v))),
                ]),
                const SizedBox(height: 20),
                _inputField('Group member limits', 'total member', limitCtrl, isNum: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, 
                  height: 56,
                  child: ElevatedButton(
                    onPressed: inProc ? null : () async {
                      if (curCourse == null || curClass == null || curNo == null) return;
                      setS(() => inProc = true);
                      final inv = List.generate(6, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Random().nextInt(36)]).join();
                      final classShort = curClass!.split(' \u2013 ')[1];
                      final gNum = int.parse(curNo!.split(' ')[1]);
                      try {
                        final g = await supabase.from('groups').insert({
                          'name': '$classShort - $curCourse - Kelompok $gNum',
                          'course_name': curCourse, 'class_name': classShort, 'group_number': gNum,
                          'member_limit': int.parse(limitCtrl.text), 'invitation_code': inv, 'lecture_code': inv,
                          'created_by': supabase.auth.currentUser!.id
                        }).select().single();
                        await supabase.from('group_members').insert({'group_id': g['id'], 'user_id': supabase.auth.currentUser!.id, 'role': 'leader'});
                        
                        if (mounted) {
                          Navigator.pop(ctx); // Close modal
                          _fetch();
                          _showSuccessPopup();
                        }
                      } catch (e) { debugPrint('create err: $e'); setS(() => inProc = false); }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: inProc ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text('Create', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupDetail(dynamic team) {
    final members = (team['group_members'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Center(child: Container(width: 80, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              GestureDetector(onTap: () => Navigator.pop(ctx), child: const Align(alignment: Alignment.centerLeft, child: Icon(Icons.arrow_back_ios_new_rounded, size: 20))),
              const SizedBox(height: 25),
              Expanded(child: ListView(
                controller: sc,
                children: [
                  Text(team['course_name'] ?? '', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('Kelompok ${team['group_number'] ?? ''}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(team['class_name'] ?? '', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  Text('Maks: ${team['member_limit'] ?? 4} people', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 25),
                  _codeSec('Invitation code', team['invitation_code']),
                  const SizedBox(height: 18),
                  _codeSec('Lecture code', team['lecture_code']),
                  const SizedBox(height: 35),
                  Text('Member list:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 20),
                  ...members.map((m) {
                    final prof = m['profiles'];
                    final isLeader = m['role'] == 'leader';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 28, backgroundImage: prof?['avatar_url'] != null ? NetworkImage(prof['avatar_url']) : const AssetImage('assets/images/avatar.png') as ImageProvider),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(prof?['full_name'] ?? prof?['username'] ?? 'User', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 10),
                                  if (isLeader) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(10)), child: const Text('Leader', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                ]),
                                const SizedBox(height: 2),
                                Text(prof?['class_name'] ?? team['class_name'] ?? '', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
                              ],
                            ),
                          ),
                          if (!isLeader && team['created_by'] == supabase.auth.currentUser!.id)
                            IconButton(icon: Icon(Icons.delete_outline_rounded, color: AppColors.primaryTeal, size: 28), onPressed: () async {
                              await supabase.from('group_members').delete().eq('id', m['id']);
                              Navigator.pop(ctx); _fetch();
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 50),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(children: [
        SingleChildScrollView(child: Column(children: [
          _headerUI(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25), 
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, height: 1.1), 
                children: [
                  const TextSpan(text: 'create your '), 
                  TextSpan(text: 'group', style: TextStyle(color: AppColors.primaryTeal)), 
                  const TextSpan(text: ',\nadd your '), 
                  TextSpan(text: 'friends', style: TextStyle(color: AppColors.primaryTeal))
                ]
              )
            )
          ),
          const SizedBox(height: 25),
          _searchUI(),
          const SizedBox(height: 25),
          isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: AppColors.primaryTeal))) 
            : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 22), itemCount: teams.length, itemBuilder: (_, i) => _groupItem(teams[i])),
          const SizedBox(height: 120),
        ])),
        _bottomNavUI(),
      ]),
    );
  }

  Widget _headerUI() => Padding(
    padding: const EdgeInsets.fromLTRB(25, 55, 25, 0), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, size: 20))), 
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), 
        child: Text('Group', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal))
      ), 
      const SizedBox(width: 36)
    ])
  );
  
  Widget _searchUI() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25), 
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]), 
          child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Search', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), hintStyle: GoogleFonts.outfit(color: Colors.grey[300])))
        )
      ), 
      const SizedBox(width: 12), 
      _iconBox(Icons.search, () {}), 
      const SizedBox(width: 15),
      Container(width: 1.5, height: 40, color: Colors.grey[300]),
      const SizedBox(width: 15),
      _iconBox(Icons.person_add_alt_1_rounded, _showJoinCreateModal)
    ])
  );
  
  Widget _iconBox(IconData i, VoidCallback tap) => GestureDetector(onTap: tap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(i, color: Colors.white, size: 28)));
  
  Widget _groupItem(dynamic t) {
    final members = (t['group_members'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 40, 
          child: Stack(children: List.generate(min(members.length, 3), (idx) => Positioned(left: idx * 24.0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: CircleAvatar(radius: 16, backgroundImage: members[idx]['profiles']?['avatar_url'] != null ? NetworkImage(members[idx]['profiles']['avatar_url']) : const AssetImage('assets/images/avatar.png') as ImageProvider)))) + [if (members.length > 3) Positioned(left: 72, child: CircleAvatar(radius: 17, backgroundColor: Colors.grey[200], child: Text('+${members.length - 3}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))))])
        ),
        const SizedBox(height: 15),
        Text(t['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
        const SizedBox(height: 4),
        Text('Grup', style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${members.length} Member', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
          GestureDetector(onTap: () => _showGroupDetail(t), child: Container(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12)), child: Text('Detail', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
        ]),
      ]),
    );
  }

  Widget _codeSec(String label, String? code) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.w600, fontSize: 14)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)), child: Text(code ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1.2)))),
      const SizedBox(width: 12),
      _iconBtn(Icons.copy_all_rounded, () => Clipboard.setData(ClipboardData(text: code ?? ''))),
      const SizedBox(width: 10),
      _iconBtn(Icons.refresh_rounded, () {}),
    ]),
  ]);

  Widget _iconBtn(IconData i, VoidCallback tap) => GestureDetector(onTap: tap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(i, color: Colors.white, size: 24)));

  Widget _inputField(String label, String hint, TextEditingController ctrl, {bool isNum = false}) => Stack(clipBehavior: Clip.none, children: [
    Container(height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryTeal, width: 1.2)), child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18), hintStyle: GoogleFonts.outfit(color: Colors.grey[300])))),
    Positioned(left: 14, top: -10, child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(label, style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 14)))),
  ]);

  Widget _dropdownField(String label, String hint, String? val, List<String> items, Function(String?) setS) => Stack(clipBehavior: Clip.none, children: [
    Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryTeal, width: 1.2)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: val, hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[300])), icon: Icon(Icons.expand_more, color: Colors.grey[300]), items: items.map((e) => DropdownMenuItem(value: e, child: Container(padding: const EdgeInsets.all(8), child: Text(e, style: GoogleFonts.outfit(color: Colors.black))))).toList(), onChanged: setS))),
    Positioned(left: 14, top: -10, child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(label, style: GoogleFonts.outfit(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 14)))),
  ]);

  Widget _bottomNavUI() => Align(alignment: Alignment.bottomCenter, child: Container(height: 85, margin: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(45), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _navIcon(Icons.home_filled, false, '/dashboard'), _navIcon(Icons.calendar_month, false, '/calendar'),
    GestureDetector(onTap: () => Navigator.pushNamed(context, '/add_project'), child: Container(height: 60, width: 60, decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 35))),
    _navIcon(Icons.people_rounded, true, '/team'), _navIcon(Icons.person_rounded, false, '/profile'),
  ])));

  Widget _navIcon(IconData i, bool active, String route) => GestureDetector(onTap: active ? null : () => Navigator.pushReplacementNamed(context, route), child: Icon(i, color: active ? AppColors.primaryTeal : Colors.grey[400], size: 32));
}
