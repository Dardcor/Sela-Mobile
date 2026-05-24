import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/shared_widgets/skeleton_loader.dart';

void main() {
  testWidgets('SkeletonContainer renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonContainer(width: 100, height: 20),
        ),
      ),
    );

    expect(find.byType(SkeletonContainer), findsOneWidget);
  });

  testWidgets('DashboardSkeleton renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardSkeleton(),
        ),
      ),
    );

    // Verify it doesn't crash
    expect(find.byType(DashboardSkeleton), findsOneWidget);
    expect(find.byType(SkeletonContainer), findsWidgets);
  });
}
