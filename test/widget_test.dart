import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:SELA/features/auth/screens/auth_screen.dart';
import 'package:SELA/features/auth/utils/auth_error_utils.dart';
import 'package:SELA/core/widgets/connectivity_wrapper.dart';
import 'package:SELA/features/auth/widgets/auth_toggle_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  testWidgets('Connectivity banner appears when offline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectivityWrapper(
          connectivityStream: Stream<ConnectivityResult>.value(
            ConnectivityResult.none,
          ),
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('Connectivity banner stays hidden when online', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectivityWrapper(
          connectivityStream: Stream<ConnectivityResult>.value(
            ConnectivityResult.wifi,
          ),
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Tidak ada koneksi internet'), findsNothing);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
  });

  test('mapAuthErrorMessage returns friendly offline message', () {
    final message = mapAuthErrorMessage(
      const SocketException('Failed host lookup: supabase.co'),
    );

    expect(
      message,
      'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.',
    );
  });

  test('mapAuthErrorMessage hides raw client exception details', () {
    final message = mapAuthErrorMessage(
      Exception(
        "ClientException with SocketException: Failed host lookup: 'example.supabase.co'",
      ),
    );

    expect(
      message,
      'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.',
    );
  });

  test('isNetworkErrorMessage detects raw auth network text', () {
    final isNetwork = isNetworkErrorMessage(
      "ClientException with SocketException: Failed host lookup: 'example.supabase.co'",
    );

    expect(isNetwork, isTrue);
  });

  test('AuthException network message is converted to friendly text', () {
    String msg = const AuthException(
      "ClientException with SocketException: Failed host lookup: 'example.supabase.co'",
    ).message;

    if (isNetworkErrorMessage(msg)) {
      msg = 'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.';
    }

    expect(msg, noInternetMessage);
  });

  test(
    'mapAuthErrorMessage exposes generic message for non-network errors',
    () {
      final message = mapAuthErrorMessage(Exception('some unexpected error'));

      expect(message, 'Terjadi kesalahan. Silakan coba lagi.');
    },
  );
}
