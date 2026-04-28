import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo muncul dari bawah layar ke tengah
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 6),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _controller.forward();

    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Tunggu animasi logo sedikit
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      // Jika ada sesi aktif, langsung ke Dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Jika tidak ada, ke halaman Auth
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
              ),
            ),
          ),
        ),
      ),
    );
}
