import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../core/shared_widgets/screen_header_bar.dart';
import '../../../core/shared_widgets/search_bar_with_button.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../widgets/group_widgets.dart';

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
    'Pemrograman Web',
  ];
  final List<String> _classes = [
    '1 – D3 IT A',
    '2 – D3 IT B',
    '3 – D4 SDT A',
    '4 – D4 IT B',
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final res = await supabase
          .from('groups')
          .select('*, group_members(*, profiles(*))')
          .order('created_at', ascending: false);
      if (mounted) setState(() => teams = res);
    } catch (e) {
      debugPrint('fetch teams info: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showJoinCreateModal() {
    String? curCourse;
    String? curClass;
    String? curNo;
    final joinCodeCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '4');
    bool inProc = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            30,
            20,
            30,
            MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // ✅ GroupInputField dari local widgets
                GroupInputField(
                  label: 'Code',
                  hint: 'Input a code',
                  controller: joinCodeCtrl,
                ),
                const SizedBox(height: 10),
                Text(
                  '*Note: Enter the code from the group',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final c = joinCodeCtrl.text.trim();
                      if (c.isEmpty) return;
                      try {
                        final results = await supabase.rpc(
                          'find_group_by_invite_code',
                          params: {'p_code': c},
                        );
                        if (results == null || (results as List).isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid or expired code')),
                            );
                          }
                          return;
                        }
                        final g = results[0];
                        await supabase.from('group_members').insert({
                          'group_id': g['id'],
                          'user_id': supabase.auth.currentUser!.id,
                          'role': 'member',
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          _fetch();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully joined group! ✅'),
                              backgroundColor: AppColors.primaryTeal,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to join. You may already be a member.'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Go to Group',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        'Or',
                        style: GoogleFonts.outfit(color: Colors.grey[400]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 25),
                // ✅ GroupDropdownField dari local widgets
                GroupDropdownField(
                  label: 'Title Group',
                  hint: 'select course',
                  value: curCourse,
                  items: _courses,
                  onChanged: (v) => setS(() => curCourse = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GroupDropdownField(
                        label: 'select a class',
                        hint: 'select a class',
                        value: curClass,
                        items: _classes,
                        onChanged: (v) => setS(() => curClass = v),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GroupDropdownField(
                        label: 'choose a number',
                        hint: 'choose a number',
                        value: curNo,
                        items: const ['Kelompok 1', 'Kelompok 2', 'Kelompok 3', 'Kelompok 4'],
                        onChanged: (v) => setS(() => curNo = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GroupInputField(
                  label: 'Group member limits',
                  hint: 'total member',
                  controller: limitCtrl,
                  isNum: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: inProc
                        ? null
                        : () async {
                            if (curCourse == null || curClass == null || curNo == null) return;
                            setS(() => inProc = true);
                            final inv = List.generate(
                              6,
                              (i) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[
                                  (DateTime.now().microsecondsSinceEpoch + i) % 36],
                            ).join();
                            final classShort = curClass!.split(' – ')[1];
                            final gNum = int.parse(curNo!.split(' ')[1]);
                            try {
                              final g = await supabase
                                  .from('groups')
                                  .insert({
                                    'name': '$classShort - $curCourse - Kelompok $gNum',
                                    'course_name': curCourse,
                                    'class_name': classShort,
                                    'group_number': gNum,
                                    'member_limit': int.parse(limitCtrl.text),
                                    'invitation_code': inv,
                                    'lecture_code': inv,
                                    'created_by': supabase.auth.currentUser!.id,
                                  })
                                  .select()
                                  .single();
                              await supabase.from('group_members').insert({
                                'group_id': g['id'],
                                'user_id': supabase.auth.currentUser!.id,
                                'role': 'leader',
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                _fetch();
                                // ✅ SuccessDialog reusable dari shared_widgets
                                SuccessDialog.show(
                                  context,
                                  message: 'Group successfully created',
                                );
                              }
                            } catch (e) {
                              debugPrint('create err: $e');
                              setS(() => inProc = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: inProc
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'Create',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
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

  void _showGroupDetail(dynamic team) {
    final members = (team['group_members'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: ListView(
                  controller: sc,
                  children: [
                    Text(
                      team['course_name'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelompok ${team['group_number'] ?? ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team['class_name'] ?? '',
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Maks: ${team['member_limit'] ?? 4} people',
                      style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 25),
                    // ✅ GroupCodeSection dari local widgets
                    GroupCodeSection(
                      label: 'Invitation code',
                      code: team['invitation_code'],
                    ),
                    const SizedBox(height: 18),
                    GroupCodeSection(
                      label: 'Lecture code',
                      code: team['lecture_code'],
                    ),
                    const SizedBox(height: 35),
                    Text(
                      'Member list:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 20),
                    ...members.map((m) {
                      final prof = m['profiles'];
                      final isLeader = m['role'] == 'leader';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: prof?['avatar_url'] != null
                                  ? NetworkImage(prof['avatar_url']) as ImageProvider
                                  : const AssetImage('assets/images/avatar.png'),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        prof?['full_name'] ?? prof?['username'] ?? 'User',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (isLeader)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Leader',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prof?['class_name'] ?? team['class_name'] ?? '',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLeader &&
                                team['created_by'] == supabase.auth.currentUser!.id)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  await supabase
                                      .from('group_members')
                                      .delete()
                                      .eq('id', m['id']);
                                  Navigator.pop(ctx);
                                  _fetch();
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
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
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ✅ Header generik
              SliverToBoxAdapter(child: ScreenHeaderBar(title: 'Group')),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.1,
                      ),
                      children: const [
                        TextSpan(text: 'create your '),
                        TextSpan(text: 'group', style: TextStyle(color: AppColors.primaryTeal)),
                        TextSpan(text: ',\nadd your '),
                        TextSpan(text: 'friends', style: TextStyle(color: AppColors.primaryTeal)),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 25)),
              SliverToBoxAdapter(child: _buildSearchUI()),
              const SliverToBoxAdapter(child: SizedBox(height: 25)),
              isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(color: AppColors.primaryTeal),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          // ✅ GroupCard dari local widgets — rebuild terisolasi
                          (context, index) => GroupCard(
                            team: teams[index],
                            onDetailTap: () => _showGroupDetail(teams[index]),
                          ),
                          childCount: teams.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          const AppBottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildSearchUI() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[300]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _IconBox(icon: Icons.search, onTap: () {}),
            const SizedBox(width: 15),
            Container(width: 1.5, height: 40, color: Colors.grey[300]),
            const SizedBox(width: 15),
            _IconBox(icon: Icons.person_add_alt_1_rounded, onTap: _showJoinCreateModal),
          ],
        ),
      );
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBox({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
