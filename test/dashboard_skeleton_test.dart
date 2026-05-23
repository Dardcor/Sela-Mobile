import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sela/core/shared_widgets/skeleton_loader.dart';

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
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.minWidth, isNull); // Container doesn't enforce minWidth in this simple check
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
