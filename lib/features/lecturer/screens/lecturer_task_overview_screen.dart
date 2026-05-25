import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';

class LecturerTaskOverviewScreen extends StatefulWidget {
  final String taskId;
  final String className;

  const LecturerTaskOverviewScreen({
    super.key,
    required this.taskId,
    required this.className,
  });

  @override
  State<LecturerTaskOverviewScreen> createState() => _LecturerTaskOverviewScreenState();
}

class _LecturerTaskOverviewScreenState extends State<LecturerTaskOverviewScreen> {
  final Set<int> _expandedMembers = {0};
  Map<String, dynamic>? _taskData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskOverview();
  }

  Future<void> _fetchTaskOverview() async {
    try {
      final response = await ApiClient().dio.get('lecturer/tasks/${widget.taskId}/overview');
      setState(() {
        _taskData = response.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      debugPrint('TaskOverview fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_taskData == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: Text(
            'Gagal memuat ringkasan tugas',
            style: GoogleFonts.outfit(color: Colors.black87),
          ),
        ),
      );
    }

    final taskData = _taskData!;
    final List<Map<String, dynamic>> members = 
        List<Map<String, dynamic>>.from(taskData['members'] ?? []);
    
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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 110, // Diperbesar jaraknya agar ada spasi ekstra di bawah badge
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Text(
                              'OVERVIEW',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showMemberProgressSheet(members, taskData),
                              child: const Icon(
                                Icons.show_chart,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Text(
                          taskData['task_name'] ?? taskData['title'] ?? 'Nama Tugas',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.className,
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              groupTag,
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 25,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         _buildStatItem('Tugas selesai', taskData['completed_tasks']?.toString() ?? '0', 'Tugas'),
                         Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.3)),
                         _buildStatItem('Tugas belum selesai', taskData['unfinished_tasks']?.toString() ?? '0', 'Tugas'),
                       ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(2, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CircularProgressIndicator(
                            value: (taskData['progress'] as num? ?? 0) / 100,
                            strokeWidth: 14,
                            backgroundColor: Colors.grey.shade100,
                            color: AppColors.primaryTeal,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${taskData['progress'] ?? 0}%',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Hitung mundur:', '${taskData['countdown'] ?? 0} Hari'),
                        const SizedBox(height: 15),
                        _buildInfoRow('Kontributor Teratas:', taskData['top_contributors']?.toString() ?? '-'),
                        const SizedBox(height: 15),
                        _buildInfoRow('Pembaruan Terkini:', taskData['recent_update']?.toString() ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Container(
                width: double.infinity,
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
                    Text(
                      'Anggota & Progres',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (members.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Tidak ada anggota ditemukan', style: GoogleFonts.outfit(color: Colors.grey)),
                        ),
                      )
                    else
                      ...List.generate(members.length, (index) {
                        final member = members[index];
                        final isExpanded = _expandedMembers.contains(index);
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedMembers.remove(index);
                                  } else {
                                    _expandedMembers.add(index);
                                  }
                                });
                              },
                              child: _buildMemberItem(
                                name: member['name']?.toString() ?? 'Anggota',
                                taskCount: member['task_count']?.toString() ?? '0 subtugas',
                                avatar: member['avatar_url']?.toString(),
                                isExpanded: isExpanded,
                                subtasks: isExpanded && member['subtasks'] != null
                                    ? List<Map<String, dynamic>>.from(member['subtasks'])
                                    : null,
                              ),
                            ),
                            if (index < members.length - 1) const Divider(height: 30),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showMemberProgressSheet(
    List<Map<String, dynamic>> members,
    Map<String, dynamic> taskData,
  ) {
    final totalSubtasks = (taskData['completed_tasks'] as num? ?? 0) +
        (taskData['unfinished_tasks'] as num? ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Progres Anggota',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final subtasks = List.from(member['subtasks'] ?? []);
                  final doneCount = subtasks
                      .where((s) => s['status'] == 'Done')
                      .length;
                  final memberProgress = totalSubtasks > 0
                      ? doneCount / totalSubtasks
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (member['avatar_url'] != null &&
                                  member['avatar_url']
                                      .toString()
                                      .startsWith('http') &&
                                  !member['avatar_url'].toString().endsWith('/'))
                              ? NetworkImage(member['avatar_url'])
                                  as ImageProvider
                              : const AssetImage(
                                  'assets/images/default_profile.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      member['name']?.toString() ?? 'Anggota',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$doneCount / $totalSubtasks',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: memberProgress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem({
    required String name,
    required String taskCount,
    String? avatar,
    required bool isExpanded,
    List<Map<String, dynamic>>? subtasks,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExpanded ? AppColors.primaryTeal.withOpacity(0.7) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: (avatar != null && (avatar.startsWith('http') || avatar.startsWith('https')))
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/default_profile.png',
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                          ),
                        )
                      : Image.asset(
                          'assets/images/default_profile.png',
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      taskCount,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isExpanded ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isExpanded ? Colors.white : Colors.grey,
              ),
            ],
          ),
        ),
        if (isExpanded && subtasks != null) ...[
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: subtasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['name']?.toString() ?? 'Subtugas',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      task['status'] == 'Done'
                          ? 'Selesai'
                          : task['status'] == 'Upcoming'
                              ? 'Akan Datang'
                              : task['status'] == 'In Progress'
                                  ? 'Sedang Berjalan'
                                  : (task['status']?.toString() ?? ''),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: task['status'] == 'Done' 
                            ? AppColors.primaryTeal 
                            : task['status'] == 'Upcoming' 
                                ? Colors.blue 
                                : AppColors.primaryTeal.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ]
      ],
    );
  }
}
