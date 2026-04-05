import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../widgets/group_widgets.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _allTeams = [];
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

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetch();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _realtimeChannel = supabase.channel('group-screen-changes');

    // Listen for groups changes
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'groups',
      callback: (payload) {
        debugPrint('Groups Realtime: Data changed! Refreshing...');
        _fetch();
      },
    );

    // Listen for group_members changes
    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          callback: (payload) {
            debugPrint('Group Members Realtime: Data changed! Refreshing...');
            _fetch();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final res = await supabase
          .from('groups')
          .select('*, group_members(*, profiles(*))')
          .order('created_at', ascending: false);
      _allTeams = res;
      _applySearch();
    } catch (e) {
      debugPrint('fetch teams info: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applySearch() {
    final keyword = _searchCtrl.text.trim().toLowerCase();
    final filteredTeams = keyword.isEmpty
        ? List<dynamic>.from(_allTeams)
        : _allTeams.where((team) {
            final name = (team['name'] ?? '').toString().toLowerCase();
            final courseName = (team['course_name'] ?? '')
                .toString()
                .toLowerCase();
            final className = (team['class_name'] ?? '')
                .toString()
                .toLowerCase();

            return name.contains(keyword) ||
                courseName.contains(keyword) ||
                className.contains(keyword);
          }).toList();

    if (mounted) {
      setState(() {
        teams = filteredTeams;
        isLoading = false;
      });
    }
  }

  void _showDeleteGroupDialog(BuildContext context, dynamic team) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.primaryTeal,
                size: 50,
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to '),
                    TextSpan(
                      text: 'delete',
                      style: const TextStyle(color: AppColors.primaryTeal),
                    ),
                    const TextSpan(text: ' this group?'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${team['course_name']} - kelompok ${team['group_number']} - ${team['class_name']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final deletedGroups = await supabase
                              .from('groups')
                              .delete()
                              .eq('id', team['id'])
                              .select('id');

                          if (deletedGroups.isEmpty) {
                            throw Exception(
                              'Group could not be deleted. Please make sure the DELETE policy for groups has been applied in Supabase.',
                            );
                          }

                          _allTeams.removeWhere((g) => g['id'] == team['id']);
                          teams.removeWhere((g) => g['id'] == team['id']);

                          if (context.mounted) {
                            Navigator.pop(ctx); // close dialog
                            Navigator.pop(context); // close modal
                            setState(() {});
                            _fetch();
                            SuccessDialog.show(
                              context,
                              message: 'Group successfully deleted',
                            );
                          }
                        } catch (e) {
                          debugPrint('Delete group err: $e');
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 2200),
                                content: Text('Failed to delete group: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinCreateModal() {
    String? curCourse;
    final noCtrl = TextEditingController();
    final joinCodeCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '4');
    bool inProc = false;
    String? joinCodeError;
    String? courseError;
    String? limitError;
    String? groupNumberError;

    void showAlert(String message, {bool isSuccess = false}) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1800),
            backgroundColor: isSuccess ? AppColors.primaryTeal : null,
            content: Text(message),
          ),
        );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              25,
              15,
              25,
              MediaQuery.of(ctx).viewInsets.bottom + 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.buttonGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Group Option',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'join a code or create a group',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 15),
                // Tabs
                TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: AppColors.primaryTeal,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'Join Group'),
                    Tab(text: 'Create Group'),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  height: 350,
                  child: TabBarView(
                    children: [
                      // Join Group Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GroupInputField(
                            label: 'Code',
                            hint: 'Input a code',
                            controller: joinCodeCtrl,
                            errorText: joinCodeError,
                            onChanged: (_) {
                              if (joinCodeError != null) {
                                setS(() => joinCodeError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '*Note: Enter the code from the group',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                final c = joinCodeCtrl.text.trim();

                                setS(() => joinCodeError = null);

                                if (c.isEmpty) {
                                  setS(
                                    () => joinCodeError =
                                        'Please enter the group code first',
                                  );
                                  return;
                                }
                                try {
                                  final results = await supabase.rpc(
                                    'find_group_by_invite_code',
                                    params: {'p_code': c},
                                  );
                                  if (results == null ||
                                      (results as List).isEmpty) {
                                    setS(
                                      () => joinCodeError =
                                          'Invalid or expired group code',
                                    );
                                    return;
                                  }
                                  final g = results[0];
                                  await supabase.from('group_members').insert({
                                    'group_id': g['id'],
                                    'user_id': supabase.auth.currentUser!.id,
                                    'role': 'member',
                                  });
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _fetch();
                                  showAlert(
                                    'Successfully joined group! ✅',
                                    isSuccess: true,
                                  );
                                } catch (e) {
                                  showAlert(
                                    'Failed to join. You may already be a member.',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'Join',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Create Group Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GroupDropdownField(
                            label: 'Title Group',
                            hint: 'select course',
                            value: curCourse,
                            errorText: courseError,
                            items: _courses,
                            onChanged: (v) => setS(() {
                              curCourse = v;
                              courseError = null;
                            }),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: GroupInputField(
                                  label: 'Group member limits',
                                  hint: 'total member',
                                  controller: limitCtrl,
                                  isNum: true,
                                  errorText: limitError,
                                  onChanged: (_) {
                                    if (limitError != null) {
                                      setS(() => limitError = null);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GroupInputField(
                                  label: 'Number Group',
                                  hint: 'input number',
                                  controller: noCtrl,
                                  isNum: true,
                                  errorText: groupNumberError,
                                  onChanged: (_) {
                                    if (groupNumberError != null) {
                                      setS(() => groupNumberError = null);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 35),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: inProc
                                  ? null
                                  : () async {
                                      final limitText = limitCtrl.text.trim();
                                      final parsedLimit = int.tryParse(
                                        limitText,
                                      );

                                      setS(() {
                                        courseError = null;
                                        limitError = null;
                                        groupNumberError = null;
                                      });

                                      if (curCourse == null) {
                                        setS(
                                          () => courseError =
                                              'Please select a course',
                                        );
                                        return;
                                      }

                                      if (noCtrl.text.trim().isEmpty) {
                                        setS(
                                          () => groupNumberError =
                                              'Please input a group number',
                                        );
                                        return;
                                      }

                                      if (limitText.isEmpty) {
                                        setS(
                                          () => limitError =
                                              'Please fill in the member limit',
                                        );
                                        return;
                                      }

                                      if (parsedLimit == null ||
                                          parsedLimit <= 0) {
                                        setS(
                                          () => limitError =
                                              'Member limit must be greater than 0',
                                        );
                                        return;
                                      }
                                      setS(() => inProc = true);
                                      final inv = List.generate(
                                        6,
                                        (i) =>
                                            'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[(DateTime.now()
                                                        .microsecondsSinceEpoch +
                                                    i) %
                                                36],
                                      ).join();

                                      try {
                                        final g = await supabase
                                            .from('groups')
                                            .insert({
                                              'name':
                                                  'D3 IT B - $curCourse - Kelompok ${noCtrl.text.trim()}',
                                              'course_name': curCourse,
                                              'class_name': 'D3 IT B',
                                              'group_number': int.parse(
                                                noCtrl.text.trim(),
                                              ),
                                              'member_limit': parsedLimit,
                                              'invitation_code': inv,
                                              'lecture_code': inv,
                                              'created_by':
                                                  supabase.auth.currentUser!.id,
                                            })
                                            .select()
                                            .single();
                                        await supabase
                                            .from('group_members')
                                            .insert({
                                              'group_id': g['id'],
                                              'user_id':
                                                  supabase.auth.currentUser!.id,
                                              'role': 'leader',
                                            });
                                        if (!ctx.mounted) return;
                                        Navigator.pop(ctx);
                                        _fetch();
                                        SuccessDialog.show(
                                          ctx,
                                          message: 'Group successfully created',
                                        );
                                      } catch (e) {
                                        debugPrint('create err: $e');
                                        setS(() => inProc = false);
                                        showAlert(
                                          'Failed to create group. Please check the data and try again.',
                                        );
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
                    ],
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
    final currentUserId = supabase.auth.currentUser?.id;
    final isMeLeader = members.any(
      (m) => m['user_id'] == currentUserId && m['role'] == 'leader',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.buttonGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
                    const SizedBox(height: 2),
                    Text(
                      'Kelompok ${team['group_number'] ?? ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team['class_name'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Maks: ${team['member_limit'] ?? 4} people',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Invitation code section
                    Text(
                      'Invitation code',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textFieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            team['invitation_code'] ?? '',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedCopyButton(
                          textToCopy: team['invitation_code'] ?? '',
                          isCircle: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    Text(
                      'Member list:',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
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
                              backgroundImage:
                                  prof?['avatar_url'] != null &&
                                      prof!['avatar_url'].toString().isNotEmpty
                                  ? NetworkImage(prof['avatar_url'])
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/images/default_profile.png',
                                    ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          prof?['full_name'] ??
                                              prof?['username'] ??
                                              'User',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isLeader) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Leader',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prof?['class_name'] ??
                                        team['class_name'] ??
                                        '',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMeLeader && !isLeader)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 26,
                                ),
                                onPressed: () async {
                                  await supabase
                                      .from('group_members')
                                      .delete()
                                      .eq('id', m['id']);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _fetch();
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                    if (isMeLeader) ...[
                      GestureDetector(
                        onTap: () => _showDeleteGroupDialog(ctx, team),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryTeal,
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.primaryTeal,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete group',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primaryTeal,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ✅ Header sesuai Gambar 1
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                25,
                MediaQuery.of(context).padding.top + 15,
                25,
                20,
              ),
              child: Row(
                children: [
                  // Tombol back — kiri
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/dashboard',
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primaryTeal,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Judul — pill putih tengah
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      'Group',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Penyeimbang ukuran tombol back (agar judul tetap center)
                  const SizedBox(width: 44),
                ],
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
                      child: CircularProgressIndicator(
                        color: AppColors.primaryTeal,
                      ),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applySearch(),
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 1.5,
          height: 40,
          color: AppColors.primaryTeal.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: _showJoinCreateModal,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    ),
  );
}
