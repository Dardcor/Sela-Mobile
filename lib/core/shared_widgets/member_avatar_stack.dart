import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Tumpukan avatar anggota yang ditampilkan secara overlapping.
/// Digunakan di kartu tugas grup pada Dashboard dan WorkInGroupScreen.
class MemberAvatarStack extends StatelessWidget {
  final List members;
  final int maxVisible;
  final double avatarRadius;
  final double overlap;

  const MemberAvatarStack({
    super.key,
    required this.members,
    this.maxVisible = 4,
    this.avatarRadius = 12,
    this.overlap = 18,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount =
        members.isEmpty ? 0 : members.length.clamp(0, maxVisible);
    final totalWidth = overlap * (displayCount - 1) + avatarRadius * 2 + 10;

    return SizedBox(
      height: avatarRadius * 2 + 4,
      width: totalWidth.clamp(0, 120),
      child: Stack(
        children: List.generate(displayCount, (idx) {
          // Slot terakhir diisi dengan "+N" jika melebihi batas
          if (idx == maxVisible - 1 && members.length > maxVisible) {
            return Positioned(
              left: idx * overlap,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.buttonGray,
                child: Text(
                  '+${members.length - (maxVisible - 1)}',
                  style: TextStyle(
                    fontSize: avatarRadius * 0.65,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            );
          }

          final avatarUrl = members[idx]['profiles']?['avatar_url'];
          return Positioned(
            left: idx * overlap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : const AssetImage('assets/images/avatar.png'),
              ),
            ),
          );
        }),
      ),
    );
  }
}
