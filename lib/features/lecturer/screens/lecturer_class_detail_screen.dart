import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import 'lecturer_task_overview_screen.dart';

class LecturerClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const LecturerClassDetailScreen({super.key, required this.classData});

  @override
  State<LecturerClassDetailScreen> createState() =>
      _LecturerClassDetailScreenState();
}

class _LecturerClassDetailScreenState extends State<LecturerClassDetailScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await ApiClient().dio.get(
        'lecturer/classes/${widget.classData['id']}/tasks',
      );
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('ClassDetail fetch error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_searchQuery.isEmpty) return _tasks;
    final query = _searchQuery.toLowerCase();
    return _tasks.where((t) {
      final taskName =
          (t['task_name']?.toString() ?? t['title']?.toString() ?? '')
              .toLowerCase();
      final groupName = (t['group_name']?.toString() ?? '').toLowerCase();
      final subject = (t['subject']?.toString() ?? '').toLowerCase();
      return taskName.contains(query) ||
          groupName.contains(query) ||
          subject.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 230,
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
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Class Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          'CLASS',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.classData['name'] ?? 'Name Kelas',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.group_outlined,
                                  color: AppColors.primaryTeal,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${widget.classData['total_groups'] ?? 0} Grup',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryTeal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  color: AppColors.primaryTeal,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${widget.classData['total_tasks'] ?? 0} Tugas',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryTeal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 35),
                
                // Search Bar & Content
                Expanded(
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            maxLength: 50,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              hintText: 'Cari tugas...',
                              hintStyle: GoogleFonts.outfit(color: Colors.grey),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Task List
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryTeal,
                                ),
                              )
                            : _filteredTasks.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ada hasil untuk "$_searchQuery"'
                                      : 'Tidak ada tugas untuk kelas ini',
                                  style: GoogleFonts.outfit(color: Colors.grey),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchTasks,
                                color: AppColors.primaryTeal,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0,
                                  ),
                                  itemCount: _filteredTasks.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskCard(
                                      context,
                                      _filteredTasks[index],
                                    );
                                  },
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
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> taskData) {
    // Collect members for avatars
    final List<dynamic> membersData = taskData['members'] ?? [];
    final int extraMembers = membersData.length > 3
        ? membersData.length - 3
        : 0;

    String groupTag = 'Kelompok -';
    if (taskData['group_number'] != null && taskData['group_number'].toString().isNotEmpty && taskData['group_number'].toString() != 'null') {
      groupTag = 'Kelompok ${taskData['group_number']}';
    } else {
      final gn = taskData['group_name']?.toString() ?? '';
      if (gn.toLowerCase().contains('kelompok')) {
        final parts = gn.split(RegExp(r'kelompok', caseSensitive: false));
        if (parts.length > 1) {
          groupTag = 'Kelompok ${parts[1].trim()}';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTag,
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      taskData['task_name'] ?? taskData['title'] ?? 'Task Name',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress Circle
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryTeal, width: 5),
                ),
                child: Center(
                  child: Text(
                    '${taskData['progress'] ?? 0}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            '${taskData['date_range'] ?? taskData['deadline'] ?? ''} | ${taskData['subject'] ?? ''}',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar Stack
              SizedBox(
                width: 100,
                height: 30,
                child: Stack(
                  children: [
                    if (membersData.isNotEmpty)
                      _buildAvatar(0, membersData[0]['avatar_url']),
                    if (membersData.length > 1)
                      _buildAvatar(20, membersData[1]['avatar_url']),
                    if (membersData.length > 2)
                      _buildAvatar(40, membersData[2]['avatar_url']),
                    if (extraMembers > 0)
                      Positioned(
                        left: 60,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '$extraMembers+',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (membersData.isEmpty) ...[
                      _buildAvatar(0, null),
                      _buildAvatar(20, null),
                      _buildAvatar(40, null),
                      Positioned(
                        left: 60,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '3+',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final String taskId =
                      taskData['task_id']?.toString() ??
                      taskData['id']?.toString() ??
                      '';
                  if (taskId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LecturerTaskOverviewScreen(
                          taskId: taskId,
                          className: widget.classData['name'] ?? '',
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Detail',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double leftPosition, String? avatarUrl) {
    return Positioned(
      left: leftPosition,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child:
              (avatarUrl != null &&
                  (avatarUrl.startsWith('http') ||
                      avatarUrl.startsWith('https')) &&
                  !avatarUrl.endsWith('/'))
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_profile.png',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/default_profile.png',
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
