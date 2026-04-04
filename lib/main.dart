import 'package:flutter/material.dart';
import 'core/shared_widgets/navbar.dart';
import 'features/home/screens/splash_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/dashboard_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/new_password_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/auth/screens/success_screen.dart';
import 'features/groups/screens/work_in_group_screen.dart';
import 'features/tasks/screens/independent_task_screen.dart';
import 'features/tasks/screens/calendar_screen.dart';
import 'features/tasks/screens/add_project_screen.dart';
import 'features/groups/screens/group_screen.dart';
import 'features/home/screens/profile_screen.dart';
import 'features/groups/screens/group_detail_screen.dart';
import 'features/tasks/screens/independent_task_detail_screen.dart';
import 'features/notifications/screens/notification_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/colors.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.init();

  try {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di .env',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Supabase initialize timeout'),
    );
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const MyApp());

  // Setup global listener after app starts for better reliability
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.setupGlobalListener();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SELA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),

    initialRoute: '/',
    routes: {
      '/': (context) => const SplashScreen(),
      '/auth': (context) => const AuthScreen(),
      '/dashboard': (context) => const Navbar(initialIndex: 0),
      '/forgot_password': (context) => const ForgotPasswordScreen(),
      '/new_password': (context) => const NewPasswordScreen(),
      '/otp_verify': (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return OTPVerifyScreen(email: args);
      },
      '/success': (context) => const SuccessScreen(),
      '/work_in_group': (context) => const WorkInGroupScreen(),
      '/independent_task': (context) => const IndependentTaskScreen(),
      '/calendar': (context) => const Navbar(initialIndex: 1),
      '/add_project': (context) => const AddProjectScreen(),
      '/team': (context) => const Navbar(initialIndex: 3),
      '/profile': (context) => const Navbar(initialIndex: 4),
      '/work_in_group_detail': (context) => const GroupDetailScreen(),
      '/independent_task_detail': (context) =>
          const IndependentTaskDetailScreen(),
      '/notifications': (context) => const NotificationScreen(),
    },
  );
}
