import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/otp_verify_screen.dart';
import 'screens/success_screen.dart';
import 'screens/work_in_group_screen.dart';
import 'screens/independent_task_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/add_project_screen.dart';
import 'screens/group_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/independent_task_detail_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SELA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF09637E)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/new_password': (context) => const NewPasswordScreen(),
        '/otp_verify': (context) => const OTPVerifyScreen(),
        '/success': (context) => const SuccessScreen(),
        '/work_in_group': (context) => const WorkInGroupScreen(),
        '/independent_task': (context) => const IndependentTaskScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/add_project': (context) => const AddProjectScreen(),
        '/team': (context) => const GroupScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/work_in_group_detail': (context) => const GroupDetailScreen(),
        '/independent_task_detail': (context) => const IndependentTaskDetailScreen(),
      },
    );
  }
}
