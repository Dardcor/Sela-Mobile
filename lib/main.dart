import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/shared_widgets/navbar.dart';
import 'core/widgets/connectivity_wrapper.dart';
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
import 'features/lecturer/screens/lecturer_navbar.dart';
import 'features/lecturer/screens/lecturer_notification_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/colors.dart';

import 'core/services/notification_service.dart';

import 'core/services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Load env and API client BEFORE notifications — 
  // NotificationService uses ApiClient().dio internally
  try {
    await dotenv.load(fileName: '.env');
    await ApiClient().init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  // Initialize notifications (includes FCM setup — needs ApiClient ready)
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SELA',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    builder: (context, child) {
      return ConnectivityWrapper(child: child!);
    },

    initialRoute: '/',
    routes: {
      '/': (context) => const SplashScreen(),
      '/auth': (context) => const AuthScreen(),
      '/dashboard': (context) => const Navbar(initialIndex: 0),
      '/lecturer_navbar': (context) => const LecturerNavbar(initialIndex: 0),
      '/lecturer_notifications': (context) => const LecturerNotificationScreen(),
      '/forgot_password': (context) => const ForgotPasswordScreen(),
      '/new_password': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map?;
        return NewPasswordScreen(
          email: args?['email'] ?? '',
          otp: args?['otp'] ?? '',
        );
      },
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
