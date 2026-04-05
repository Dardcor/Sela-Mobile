import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:SELA/features/auth/widgets/auth_toggle_tab.dart';

void main() {
  testWidgets('Auth toggle renders both tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthToggleTab(
            isLogin: true,
            onLoginTap: () {},
            onRegisterTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
