import 'package:flutter/material.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SkeletonContainer(width: double.infinity, height: 50, borderRadius: 30),
          ),
          const SizedBox(height: 25),
          // Group Task Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonContainer(width: 150, height: 20),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 25),
              itemCount: 3,
              itemBuilder: (context, _) => Padding(
                padding: const EdgeInsets.only(right: 15),
                child: SkeletonContainer(width: 200, height: 185, borderRadius: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
