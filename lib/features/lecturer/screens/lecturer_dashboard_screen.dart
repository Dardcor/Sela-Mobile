import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import '../../../core/shared_widgets/search_bar_with_button.dart';
import 'lecturer_class_detail_screen.dart';

class LecturerDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  const LecturerDashboardScreen({super.key, this.onNavigateToProfile});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _unreadNotificationsCount = 0;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (!mounted) return;
      setState(() {
        _unreadNotificationsCount++;
      });
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final res = await ApiClient().dio.get(
        '/notifications',
        queryParameters: {'is_read': false},
      );
      if (mounted) {
        setState(() {
          _unreadNotificationsCount =
              (res.data['notifications'] as List).length;
        });
      }
    } catch (e) {
      debugPrint('Err Notifications Count: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('lecturer/classes'),
        ApiClient().dio.get('me'),
      ]);
      _fetchUnreadNotificationsCount();
      setState(() {
        _classes = List<Map<String, dynamic>>.from(
          responses[0].data['data'] ?? [],
        );
        _profile = Map<String, dynamic>.from(
          responses[1].data['user'] ??
              responses[1].data['data'] ??
              responses[1].data,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data';
        _isLoading = false;
      });
      debugPrint('LecturerDashboard fetch error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    final query = _searchQuery.toLowerCase();
    return _classes.where((c) {
      final className = (c['name']?.toString() ?? '').toLowerCase();
      return className.contains(query);
    }).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi!';
    } else if (hour < 18) {
      return 'Selamat Siang!';
    } else {
      return 'Selamat Malam!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primaryTeal,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Background Header + Avatar + Welcome
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Top
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25.0,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: widget.onNavigateToProfile,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child:
                                        _profile?['avatar_url'] != null &&
                                            !_profile!['avatar_url']
                                                .toString()
                                                .endsWith('/')
                                        ? Image.network(
                                            _profile!['avatar_url'],
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Image.asset(
                                                  'assets/images/default_profile.png',
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                ),
                                          )
                                        : Image.asset(
                                            'assets/images/default_profile.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Dashboard',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.primaryTeal,
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          '/lecturer_notifications',
                                        );
                                        _fetchUnreadNotificationsCount();
                                      },
                                    ),
                                    if (_unreadNotificationsCount > 0)
                                      Positioned(
                                        top: 10,
                                        right: 12,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Welcome Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _profile?['full_name'] ?? 'Lecturer',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Dosen',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 10,
                ),
                child: SearchBarWithButton(
                  controller: _searchController,
                  hintText: 'Cari kelas...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
            // "Your Classes" title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 10,
                ),
                child: Text(
                  'Kelas',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Content
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filteredClasses.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          color: Colors.grey[300],
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada hasil untuk "$_searchQuery"'
                              : 'Belum ada kelas',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pilih kelas dari profil Anda',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final classData = _filteredClasses[index];
                    return _buildClassCard(context, classData);
                  }, childCount: _filteredClasses.length),
                ),
              ),

            // Bottom spacing for navbar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Map<String, dynamic> classData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LecturerClassDetailScreen(classData: classData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + group count badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${classData['total_groups'] ?? 0} Grup',
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Class name
            Text(
              classData['name']?.toString() ?? 'Nama Kelas',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Task count subtitle
            Text(
              '${classData['total_tasks'] ?? 0} Tugas',
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Bottom row: updated info + detail button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'diperbarui:',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        classData['last_updated']?.toString() ?? '-',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Detail',
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
