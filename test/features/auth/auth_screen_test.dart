import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:SELA/features/auth/screens/auth_screen.dart';
import 'package:SELA/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockApiClient mockApiClient;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockApiClient = MockApiClient();
    mockSecureStorage = MockFlutterSecureStorage();
    // Stub methods if needed
  });

  testWidgets('AuthScreen shows login and register tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(),
      ),
    );

    // Verify tabs are present
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
