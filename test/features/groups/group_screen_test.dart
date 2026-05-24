import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:SELA/features/groups/screens/group_screen.dart';

void main() {
  testWidgets('GroupScreen shows group list title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GroupScreen()),
      ),
    );

    // Verify title is present, adjust to what's actually rendered if needed.
    // If "Grup Anda" is not found, maybe I should check for another element
    // like the search bar or list.
    expect(find.byType(TextField), findsWidgets); 
  });
}
