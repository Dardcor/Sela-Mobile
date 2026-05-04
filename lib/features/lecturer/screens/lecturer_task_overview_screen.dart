import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class LecturerTaskOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final String className;

  const LecturerTaskOverviewScreen({
    super.key,
    required this.taskData,
    required this.className,
  });

  @override
  State<LecturerTaskOverviewScreen> createState() => _LecturerTaskOverviewScreenState();
}

class _LecturerTaskOverviewScreenState extends State<LecturerTaskOverviewScreen> {
  final Set<int> _expandedMembers = {0};

  @override
  Widget build(BuildContext context) {
    final taskData = widget.taskData;
    final members = taskData['members'] as List<Map<String, dynamic>>? ?? [];

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
                            const Icon(
                              Icons.show_chart,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Text(
                          taskData['task_name'],
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
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              taskData['group_name'],
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
                  bottom: -40,
                  left: 25,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                        _buildStatItem('completed task', taskData['completed_tasks'].toString(), 'Task'),
                        Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.3)),
                        _buildStatItem('unfinished task', taskData['unfinished_tasks'].toString(), 'Task'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70), // Kompensasi ruang untuk stats box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: (taskData['progress'] as int) / 100,
                          strokeWidth: 20,
                          backgroundColor: Colors.white,
                          color: AppColors.primaryTeal,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            '${taskData['progress']}%',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Countdown:', taskData['countdown']),
                        const SizedBox(height: 15),
                        _buildInfoRow('Top Contributor:', taskData['top_contributors']),
                        const SizedBox(height: 15),
                        _buildInfoRow('Recent Update:', taskData['recent_update']),
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
                      'Member & Progres',
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
                          child: Text('No members found', style: GoogleFonts.outfit(color: Colors.grey)),
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
                                name: member['name'],
                                taskCount: member['task_count'],
                                avatar: member['avatar'],
                                isExpanded: isExpanded,
                                subtasks: isExpanded ? (member['subtasks'] as List).cast<Map<String, dynamic>>() : null,
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

  Widget _buildStatItem(String title, String value, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
            height: 1.0,
          ),
        ),
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

  Widget _buildInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem({
    required String name,
    required String taskCount,
    required String avatar,
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
                backgroundImage: AssetImage(avatar),
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
                    Text(
                      task['name'],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      task['status'],
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
