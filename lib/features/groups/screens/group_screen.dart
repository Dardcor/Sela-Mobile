import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/success_dialog.dart';
import '../widgets/group_widgets.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with AutomaticKeepAliveClientMixin {
  final apiClient = ApiClient();
  List<dynamic> _allTeams = [];
  List<dynamic> teams = [];
  bool isLoading = true;
  bool _isModalOpening = false;
  String _currentUserId = '';
  String _currentUserClass = '';

  @override
  bool get wantKeepAlive => true; // Mencegah rebuild saat swipe PageView

  List<String> _courses = [];
  final _searchCtrl = TextEditingController();

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showModalToast(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red : AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  Future<void> _initUserId() async {
    try {
      final res = await apiClient.dio.get('/me');
      final userData = res.data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));

      if (mounted) {
        setState(() {
          _currentUserId = userData['id']?.toString() ?? '';
          final cls =
              userData['class_name'] ??
              (userData['profile'] != null
                  ? userData['profile']['class_name']
                  : null);
          _currentUserClass =
              (cls == null ||
                  cls.toString() == 'null' ||
                  cls.toString().trim().isEmpty)
              ? ''
              : cls.toString().trim();
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          final userDataStr = prefs.getString('user_data');
          if (userDataStr != null) {
            final userData = json.decode(userDataStr);
            _currentUserId = userData['id']?.toString() ?? '';
            final cls =
                userData['class_name'] ??
                (userData['profile'] != null
                    ? userData['profile']['class_name']
                    : null);
            _currentUserClass =
                (cls == null ||
                    cls.toString() == 'null' ||
                    cls.toString().trim().isEmpty)
                ? ''
                : cls.toString().trim();
          } else {
            _currentUserId = '';
            _currentUserClass = '';
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initUserId();
    _fetch();

    // Mengecek apakah layar ini dipanggil dengan instruksi membuka modal dari route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args?['open_group_modal'] == true) {
        _showJoinCreateModal();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();

    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        final userId = userData['id'];
        final res = await apiClient.dio.get('/groups/user/$userId');
        _allTeams = res.data['groups'] ?? res.data['data'] ?? [];
      }

      try {
        final courseRes = await apiClient.dio.get('/courses');
        if (courseRes.data is List) {
          _courses = (courseRes.data as List)
              .map((c) => c['name'].toString())
              .toList();
        } else if (courseRes.data != null && courseRes.data['data'] is List) {
          _courses = (courseRes.data['data'] as List)
              .map((c) => c['name'].toString())
              .toList();
        }
      } catch (e) {
        debugPrint('fetch courses info: $e');
      }

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
            return name.contains(keyword) || courseName.contains(keyword);
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
                  children: const [
                    TextSpan(text: 'Apakah Anda yakin ingin '),
                    TextSpan(
                      text: 'menghapus',
                      style: TextStyle(color: AppColors.primaryTeal),
                    ),
                    TextSpan(text: ' grup ini?'),
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
                        'Batal',
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
                        _showLoadingDialog(context);
                        try {
                          await apiClient.dio.delete('/groups/${team['id']}');

                          _allTeams.removeWhere((g) => g['id'] == team['id']);
                          teams.removeWhere((g) => g['id'] == team['id']);

                          if (context.mounted) {
                            _hideLoadingDialog(context);
                            Navigator.pop(ctx); // close dialog
                            Navigator.pop(context); // close modal
                            setState(() {});
                            _fetch();
                            SuccessDialog.show(
                              context,
                              message: 'Grup berhasil dihapus',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) _hideLoadingDialog(context);
                          debugPrint('Delete group err: $e');
                          if (!context.mounted) return;
                          Navigator.pop(ctx);

                          String errMsg =
                              'Gagal menghapus grup. Silakan coba lagi.';
                          if (e is DioException) {
                            if (e.response?.statusCode == 500) {
                              errMsg =
                                  'Gagal menghapus grup: Terjadi masalah pada server. Pastikan tidak ada data yang terikat.';
                            } else if (e.response?.data != null &&
                                e.response?.data['message'] != null) {
                              errMsg =
                                  e.response?.data['message'].toString() ??
                                  errMsg;
                            }
                          }

                          _showModalToast(context, errMsg);
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
                        'Ya',
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

  Future<void> _kickMember({
    required BuildContext bottomSheetContext,
    required dynamic team,
    required dynamic member,
  }) async {
    try {
      final memberUserId = member['user_id'] ?? member['id'];
      if (memberUserId == null || memberUserId.toString().trim().isEmpty) {
        _showModalToast(
          bottomSheetContext,
          'Data anggota tidak valid (ID kosong)',
        );
        return;
      }

      _showLoadingDialog(bottomSheetContext);

      final groupLabel = team['course_name'] ?? team['name'] ?? 'grup';

      await apiClient.dio.delete('/groups/${team['id']}/members/$memberUserId');

      await apiClient.dio.post(
        '/notifications',
        data: {
          'user_id': memberUserId,
          'title': 'Dikeluarkan dari grup',
          'message': 'Kamu telah dikeluarkan dari grup $groupLabel',
          'type': 'system',
        },
      );

      if (!bottomSheetContext.mounted) return;
      _hideLoadingDialog(bottomSheetContext);
      Navigator.pop(bottomSheetContext);
      await _fetch();
      if (!mounted) return;
      SuccessDialog.show(
        context,
        message: 'Anggota berhasil dikeluarkan dari grup',
      );
    } catch (e) {
      if (bottomSheetContext.mounted) _hideLoadingDialog(bottomSheetContext);
      if (!bottomSheetContext.mounted) return;
      _showModalToast(bottomSheetContext, 'Gagal mengeluarkan anggota: $e');
    }
  }

  Future<void> _passLeadership({
    required BuildContext bottomSheetContext,
    required dynamic team,
    required dynamic member,
    required String currentUserId,
  }) async {
    try {
      _showLoadingDialog(bottomSheetContext);
      final memberUserId = member['user_id'] ?? member['id'];

      final membershipsRes = await apiClient.dio.get(
        '/groups/${team['id']}/members',
      );
      final List memberships = membershipsRes.data;

      final targetMembership = memberships.firstWhere(
        (m) => m['user_id'] == memberUserId,
      );
      final myMembership = memberships.firstWhere(
        (m) => m['user_id'] == currentUserId,
      );

      await apiClient.dio.put(
        '/group-members/${targetMembership['id']}',
        data: {'role': 'leader'},
      );
      await apiClient.dio.put(
        '/group-members/${myMembership['id']}',
        data: {'role': 'member'},
      );

      if (!bottomSheetContext.mounted) return;
      _hideLoadingDialog(bottomSheetContext);
      Navigator.pop(bottomSheetContext); // close bottom sheet
      await _fetch();
      if (!mounted) return;
      SuccessDialog.show(context, message: 'Berhasil menyerahkan kepemimpinan');
    } catch (e) {
      if (bottomSheetContext.mounted) _hideLoadingDialog(bottomSheetContext);
      if (!bottomSheetContext.mounted) return;
      _showModalToast(bottomSheetContext, 'Gagal menyerahkan kepemimpinan: $e');
    }
  }

  void _showLeaveGroupDialog(BuildContext context, dynamic team) {
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
                Icons.exit_to_app_rounded,
                color: Colors.red,
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
                  children: const [
                    TextSpan(text: 'Apakah Anda yakin ingin '),
                    TextSpan(
                      text: 'keluar dari',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(text: ' grup ini?'),
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
                        'Batal',
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
                        _showLoadingDialog(context);
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final userDataStr = prefs.getString('user_data');
                          if (userDataStr != null) {
                            final userData = json.decode(userDataStr);
                            final userId = userData['id'];
                            await apiClient.dio.delete(
                              '/groups/${team['id']}/members/$userId',
                            );
                          }

                          if (!context.mounted) return;
                          _hideLoadingDialog(context);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          await _fetch();
                          if (!mounted) return;
                          SuccessDialog.show(
                            this.context,
                            message: 'Kamu berhasil keluar dari grup',
                          );
                        } catch (e) {
                          if (context.mounted) _hideLoadingDialog(context);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          _showModalToast(
                            context,
                            'Gagal keluar dari grup: $e',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Keluar',
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

  void _showJoinCreateModal() async {
    if (_isModalOpening) return;
    _isModalOpening = true;

    try {
      await _initUserId();
      if (!mounted) return;

      String? curCourse;
      final noCtrl = TextEditingController();
      final joinCodeCtrl = TextEditingController();
      final limitCtrl = TextEditingController(text: '4');
      bool inProc = false;
      bool inProcJoin = false;
      String? joinCodeError;
      String? courseError;
      String? limitError;
      String? groupNumberError;

      void showAlert(String message, {bool isSuccess = false}) {
        if (!context.mounted) return;
        final overlay = Overlay.of(context);
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (context) => Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.primaryTeal : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (entry.mounted) {
            entry.remove();
          }
        });
      }

      if (_currentUserClass.isEmpty) {
        showAlert(
          'Kelas kosong. Silakan lengkapi kelas di profil untuk membuat grup.',
        );
        return;
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
                        color: Colors.grey[300]!,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Pilihan Grup',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'masukkan kode atau buat grup baru',
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
                      Tab(text: 'Gabung Grup'),
                      Tab(text: 'Buat Grup'),
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
                              label: 'Kode',
                              hint: 'Masukkan kode',
                              controller: joinCodeCtrl,
                              errorText: joinCodeError,
                              maxLength: 6,
                              showCounter: false,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [UpperCaseTextFormatter()],
                              onChanged: (_) {
                                if (joinCodeError != null) {
                                  setS(() => joinCodeError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '*Catatan: Masukkan kode dari grup',
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
                                onPressed: inProcJoin
                                    ? null
                                    : () async {
                                        if (inProcJoin) return;
                                        setS(() => inProcJoin = true);

                                        final c = joinCodeCtrl.text.trim();

                                        setS(() => joinCodeError = null);

                                        if (c.isEmpty) {
                                          setS(() {
                                            joinCodeError =
                                                'Silakan masukkan kode grup terlebih dahulu';
                                            inProcJoin = false;
                                          });
                                          return;
                                        }
                                        try {
                                          final res = await apiClient.dio.post(
                                            '/groups/join',
                                            data: {'code': c},
                                          );

                                          if (!ctx.mounted) return;
                                          Navigator.pop(ctx);
                                          _fetch();

                                          if (res.data != null &&
                                              res.data['data'] != null &&
                                              res.data['data']['status'] ==
                                                  'pending_approval') {
                                            showAlert(
                                              'Permintaan bergabung telah dikirim ke ketua grup dan sedang menunggu persetujuan.',
                                              isSuccess: true,
                                            );
                                          } else {
                                            showAlert(
                                              'Berhasil bergabung dengan grup! ✅',
                                              isSuccess: true,
                                            );
                                          }
                                        } catch (e) {
                                          String msg =
                                              'Gagal bergabung. Kode tidak valid atau Anda sudah menjadi anggota.';
                                          if (e is DioException &&
                                              e.response?.data != null &&
                                              e.response?.data['message'] !=
                                                  null) {
                                            msg = e.response?.data['message'];
                                          }
                                          showAlert(msg);
                                        } finally {
                                          if (ctx.mounted) {
                                            setS(() => inProcJoin = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  disabledBackgroundColor:
                                      AppColors.primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: inProcJoin
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Gabung',
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
                              label: 'Judul Grup',
                              hint: 'Pilih mata kuliah',
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
                                    label: 'Batas Anggota',
                                    hint: 'Total anggota',
                                    controller: limitCtrl,
                                    maxLength: 2,
                                    showCounter: false,
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
                                    label: 'Nomor Grup',
                                    hint: 'Masukkan nomor',
                                    controller: noCtrl,
                                    isNum: true,
                                    maxLength: 5,
                                    showCounter: false,
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
                                        if (inProc) return;
                                        final limitText = limitCtrl.text.trim();
                                        final parsedLimit = int.tryParse(
                                          limitText,
                                        );

                                        bool hasErr = false;
                                        setS(() {
                                          courseError = null;
                                          limitError = null;
                                          groupNumberError = null;
                                        });

                                        if (curCourse == null ||
                                            curCourse!.trim().isEmpty) {
                                          setS(
                                            () => courseError =
                                                'Silakan pilih mata kuliah',
                                          );
                                          hasErr = true;
                                        }

                                        final noText = noCtrl.text.trim();
                                        final noVal = int.tryParse(noText);

                                        if (noText.isEmpty) {
                                          setS(
                                            () => groupNumberError =
                                                'Silakan masukkan nomor grup',
                                          );
                                          hasErr = true;
                                        } else if (noVal == null ||
                                            noVal <= 0) {
                                          setS(
                                            () => groupNumberError =
                                                'Harus lebih dari 0',
                                          );
                                          hasErr = true;
                                        }

                                        if (limitText.isEmpty) {
                                          setS(
                                            () => limitError =
                                                'Silakan masukkan batas',
                                          );
                                          hasErr = true;
                                        } else if (parsedLimit == null ||
                                            parsedLimit < 2) {
                                          setS(
                                            () => limitError = 'Batas min: 2',
                                          );
                                          hasErr = true;
                                        }

                                        if (hasErr) return;

                                        setS(() => inProc = true);

                                        try {
                                          await apiClient.dio.post(
                                            '/groups',
                                            data: {
                                              'course_name': curCourse,
                                              'member_limit': parsedLimit,
                                              'group_number': noVal,
                                              'class_name': _currentUserClass,
                                            },
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                            _fetch();
                                            showAlert(
                                              'Grup berhasil dibuat! 🎉',
                                              isSuccess: true,
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            String errMsg =
                                                'Gagal membuat grup: $e';
                                            if (e is DioException &&
                                                e.response?.data != null) {
                                              final data = e.response?.data;
                                              if (data is Map &&
                                                  data['errors'] != null) {
                                                final errors =
                                                    data['errors'] as Map;
                                                errMsg = errors.values.first[0]
                                                    .toString();
                                              } else if (data is Map &&
                                                  data['message'] != null) {
                                                errMsg = data['message']
                                                    .toString();
                                              } else {
                                                errMsg = data.toString();
                                              }
                                            }
                                            showAlert(errMsg);
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setS(() => inProc = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  disabledBackgroundColor:
                                      AppColors.primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: inProc
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Buat',
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
    } finally {
      _isModalOpening = false;
    }
  }

  void _showGroupDetail(dynamic team) async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    dynamic groupDetail;
    List<dynamic> members = [];

    try {
      final res = await apiClient.dio.get('/groups/${team['id']}');
      groupDetail = res.data['group'];
      members = List<dynamic>.from(res.data['members'] ?? []);

      final String? currentUid = _currentUserId;
      members.sort((a, b) {
        final aIsMe = (a['id'] == currentUid || a['user_id'] == currentUid)
            ? 1
            : 0;
        final bIsMe = (b['id'] == currentUid || b['user_id'] == currentUid)
            ? 1
            : 0;

        final aIsLeader = a['role'] == 'leader' ? 1 : 0;
        final bIsLeader = b['role'] == 'leader' ? 1 : 0;

        if (aIsMe != bIsMe) return bIsMe.compareTo(aIsMe);
        if (aIsLeader != bIsLeader) return bIsLeader.compareTo(aIsLeader);
        return 0;
      });
    } catch (e) {
      debugPrint('Failed to load group detail: $e');
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showModalToast(context, 'Gagal memuat rincian grup: $e');
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // close loading

    final currentUserId = _currentUserId;
    final isMeLeader = members.any(
      (m) => m['id'] == currentUserId && m['role'] == 'leader',
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
                    color: Colors.grey[300]!,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                      'Maks: ${team['member_limit'] ?? 4} orang',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Invitation code section
                    Text(
                      'Kode undangan',
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
                            color: Colors.grey[100]!,
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
                      'Daftar anggota:',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...members.map((m) {
                      final isLeader = m['role'] == 'leader';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  m['avatar_url'] != null &&
                                      m['avatar_url'].toString().isNotEmpty &&
                                      !m['avatar_url'].toString().endsWith('/')
                                  ? NetworkImage(m['avatar_url'])
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
                                          m['full_name'] ??
                                              m['username'] ??
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
                                            'Ketua',
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
                                    m['class_name'] ??
                                        groupDetail['class_name'] ??
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
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.primaryTeal,
                                ),
                                onSelected: (value) {
                                  if (value == 'make_leader') {
                                    showDialog(
                                      context: ctx,
                                      builder: (dialogCtx) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(30),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.swap_horiz_rounded,
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
                                                    const TextSpan(
                                                      text: 'Jadikan ',
                                                    ),
                                                    const TextSpan(
                                                      text: 'Ketua',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .primaryTeal,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: ' grup?',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 30),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogCtx,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.grey[200],
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 15,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Batal',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        Navigator.pop(
                                                          dialogCtx,
                                                        );
                                                        await _passLeadership(
                                                          bottomSheetContext:
                                                              ctx,
                                                          team: team,
                                                          member: m,
                                                          currentUserId:
                                                              currentUserId,
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryTeal,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 15,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Ya',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                  } else if (value == 'kick') {
                                    showDialog(
                                      context: ctx,
                                      builder: (dialogCtx) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(30),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_remove_rounded,
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
                                                    const TextSpan(
                                                      text:
                                                          'Apakah Anda yakin ingin ',
                                                    ),
                                                    const TextSpan(
                                                      text: 'mengeluarkan',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .primaryTeal,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: ' anggota ini?',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 30),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogCtx,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.grey[200],
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 15,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Batal',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        Navigator.pop(
                                                          dialogCtx,
                                                        );
                                                        await _kickMember(
                                                          bottomSheetContext:
                                                              ctx,
                                                          team: team,
                                                          member: m,
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryTeal,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 15,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Ya',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'make_leader',
                                    child: Text(
                                      'Jadikan Ketua',
                                      style: GoogleFonts.outfit(),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'kick',
                                    child: Text(
                                      'Keluarkan',
                                      style: GoogleFonts.outfit(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                    if (isMeLeader) ...[
                      if (members.length > 1) ...[
                        GestureDetector(
                          onTap: () {
                            _showModalToast(
                              ctx,
                              'Anda harus menyerahkan kepemimpinan ke anggota lain terlebih dahulu.',
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 1.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.exit_to_app_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Keluar Grup',
                                  style: GoogleFonts.outfit(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
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
                                'Hapus grup',
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
                    ] else ...[
                      GestureDetector(
                        onTap: () => _showLeaveGroupDialog(ctx, team),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 1.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.exit_to_app_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar Grup',
                                style: GoogleFonts.outfit(
                                  color: Colors.red,
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
    super.build(context);
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
              child: Center(
                child: Container(
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
                    'Grup',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      letterSpacing: -0.5,
                    ),
                  ),
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
                      child: CircularProgressIndicator(
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                )
              : teams.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            color: Colors.grey[300],
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Belum ada grup',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Gabung atau buat grup untuk memulai',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applySearch(),
                  onSubmitted: (_) => _applySearch(),
                  maxLength: 50,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Cari...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _applySearch();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                );
              },
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
