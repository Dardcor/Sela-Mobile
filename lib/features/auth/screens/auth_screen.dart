import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/auth_toggle_tab.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/auth_buttons.dart';
import '../utils/auth_error_utils.dart';
import 'forgot_password_screen.dart';
import '../../../core/services/connectivity_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _rememberMe = false;

  List<String> _classes = [];
  String? _selectedClass;

  final _secureStorage = const FlutterSecureStorage();

  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _usernameRegisterController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();

  final _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/data/class.json',
      );
      final data = json.decode(response) as List<dynamic>;
      if (mounted) {
        setState(() {
          _classes = data.map((e) => e.toString()).toList();
          // _selectedClass tetap null agar dropdown menampilkan "Select Class" di awal
        });
      }
    } catch (e) {
      debugPrint('Error loading class.json: $e');
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final remembered = await _secureStorage.read(key: 'remember_me');
    if (remembered == 'true') {
      final savedEmail = await _secureStorage.read(key: 'remembered_email') ?? '';
      final savedPassword = await _secureStorage.read(key: 'remembered_password') ?? '';
      if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
        if (mounted) {
          setState(() {
            _rememberMe = true;
            _emailLoginController.text = savedEmail;
            _passwordLoginController.text = savedPassword;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _usernameRegisterController.dispose();
    _emailRegisterController.dispose();
    _passwordRegisterController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _emailLoginController.clear();
    _passwordLoginController.clear();
    _usernameRegisterController.clear();
    _emailRegisterController.clear();
    _passwordRegisterController.clear();
    setState(() => _selectedClass = null);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _handleLogin() async {
    final email = _emailLoginController.text.trim();
    final password = _passwordLoginController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan Password tidak boleh kosong');
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      showNoInternetSnackBar(context);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiClient().login(email, password);

      if (res.statusCode == 200 && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res.data['token']);
        await prefs.setString('user_data', json.encode(res.data['user']));
        
        // Register FCM device token
        await NotificationService.registerDeviceToken();
        
        if (_rememberMe) {
          await _secureStorage.write(key: 'remember_me', value: 'true');
          await _secureStorage.write(key: 'remembered_email', value: email);
          await _secureStorage.write(key: 'remembered_password', value: password);
        } else {
          await _secureStorage.delete(key: 'remember_me');
          await _secureStorage.delete(key: 'remembered_email');
          await _secureStorage.delete(key: 'remembered_password');
        }

        final userRole = res.data['user']['role'];
        if (userRole == 'lecturer') {
          Navigator.pushReplacementNamed(context, '/lecturer_navbar');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on DioException catch (e) {
      debugPrint('🔥 LOGIN DIO ERROR: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionError ||
          isNetworkErrorMessage(e.message ?? '')) {
        showNoInternetSnackBar(context);
      } else {
        String msg = 'Email atau Password salah. Silakan coba lagi.';
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          msg = e.response?.data['message'];
        }
        _showError(msg);
      }
    } catch (e) {
      debugPrint('🔥 LOGIN EXCEPTION: $e');
      if (e.toString().contains('SocketException')) {
        showNoInternetSnackBar(context);
      } else {
        _showError('Email atau Password salah. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final username = _usernameRegisterController.text.trim();
    final email = _emailRegisterController.text.trim();
    final password = _passwordRegisterController.text.trim();

    if (username.isEmpty) {
      _showError('Username tidak boleh kosong');
      return;
    }
    if (username.length > 20) {
      _showError('Username maksimal 20 karakter');
      return;
    }
    // Hanya huruf (a-z, A-Z), angka (0-9), dan spasi di tengah yang diperbolehkan
    // Tidak boleh diawali spasi
    final usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9 ]*$');
    if (!usernameRegex.hasMatch(username)) {
      _showError(
        'Username hanya boleh mengandung huruf, angka, dan spasi di tengah (tidak boleh diawali spasi atau menggunakan simbol)',
      );
      return;
    }
    if (email.isEmpty) {
      _showError('Email tidak boleh kosong');
      return;
    }
    if (password.isEmpty) {
      _showError('Password tidak boleh kosong');
      return;
    }
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      _showError('Kelas tidak boleh kosong');
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      showNoInternetSnackBar(context);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiClient().register({
        'full_name': username,
        'username': username,
        'email': email,
        'password': password,
        'class_name': _selectedClass ?? '',
      });

      if (mounted && (res.statusCode == 201 || res.statusCode == 200)) {
        _showSuccess('Registrasi berhasil! Silakan login dengan akun Anda.');
        _usernameRegisterController.clear();
        _emailRegisterController.clear();
        _passwordRegisterController.clear();

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          setState(() {
            isLogin = true;
          });
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    } on DioException catch (e) {
      debugPrint('🔥 REGISTER DIO ERROR: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionError ||
          isNetworkErrorMessage(e.message ?? '')) {
        showNoInternetSnackBar(context);
      } else {
        String msg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        if (msg.contains('User already registered') || msg.contains('The email has already been taken')) {
          msg = 'Email ini sudah terdaftar. Silakan login.';
        } else if (msg.contains('Database error saving new user') || msg.contains('username already exists') || msg.contains('The username has already been taken')) {
          msg = 'Username atau Email sudah digunakan. Silakan pilih yang lain.';
        } else if (e.response?.data?['errors'] != null) {
          msg = "Form tidak valid: ${e.response?.data['errors'].toString()}";
        }
        _showError(msg);
      }
    } catch (e) {
      debugPrint('🔥 REGISTER GENERIC ERROR: $e');
      final msg = mapAuthErrorMessage(e);
      if (msg == noInternetMessage) {
        showNoInternetSnackBar(context);
      } else {
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(message, style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(15),
        ),
      );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(message, style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(15),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primaryTeal,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.mainGradient),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Image.asset('assets/images/logo.png', width: 80),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello!',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Welcome to SELA',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomInset),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        30, 30, 30, 0),
                                    child: AuthToggleTab(
                                      isLogin: isLogin,
                                      onLoginTap: () {
                                        if (mounted && !isLogin) {
                                          _pageController.animateToPage(
                                            0,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      onRegisterTap: () {
                                        if (mounted && isLogin) {
                                          _pageController.animateToPage(
                                            1,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.55,
                                    child: PageView(
                                      controller: _pageController,
                                      physics: const BouncingScrollPhysics(),
                                      onPageChanged: (index) {
                                        if (mounted) {
                                          setState(
                                              () => isLogin = index == 0);
                                        }
                                      },
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 15,
                                            left: 30,
                                            right: 30,
                                          ),
                                          child: _LoginForm(
                                            emailController:
                                                _emailLoginController,
                                            passwordController:
                                                _passwordLoginController,
                                            obscurePassword:
                                                _obscureLoginPassword,
                                            isLoading: isLoading,
                                            rememberMe: _rememberMe,
                                            onToggleObscure: () => setState(
                                              () => _obscureLoginPassword =
                                                  !_obscureLoginPassword,
                                            ),
                                            onRememberMeChanged: (val) =>
                                                setState(
                                              () =>
                                                  _rememberMe = val ?? false,
                                            ),
                                            onLogin: _handleLogin,
                                            onForgotPassword: () =>
                                                Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 15,
                                            left: 30,
                                            right: 30,
                                          ),
                                          child: _RegisterForm(
                                            usernameController:
                                                _usernameRegisterController,
                                            emailController:
                                                _emailRegisterController,
                                            passwordController:
                                                _passwordRegisterController,
                                            obscurePassword:
                                                _obscureRegisterPassword,
                                            isLoading: isLoading,
                                            selectedClass: _selectedClass,
                                            classes: _classes,
                                            onClassChanged: (val) {
                                              if (val != null) {
                                                setState(() =>
                                                    _selectedClass = val);
                                              }
                                            },
                                            onToggleObscure: () => setState(
                                              () => _obscureRegisterPassword =
                                                  !_obscureRegisterPassword,
                                            ),
                                            onRegister: _handleRegister,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// Form Login — widget terpisah agar isolasi rebuild
// ────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool rememberMe;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.rememberMe,
    required this.onToggleObscure,
    required this.onRememberMeChanged,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Column(
      children: [
        AuthTextField(
          controller: emailController,
          label: 'Email Address',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        AuthPasswordField(
          controller: passwordController,
          label: 'Password',
          hint: 'Masukkan password',
          obscure: obscurePassword,
          onToggle: onToggleObscure,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: onRememberMeChanged,
                  activeColor: AppColors.primaryTeal,
                ),
                Text('Remember me', style: GoogleFonts.outfit(fontSize: 14)),
              ],
            ),
            TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.outfit(
                  color: AppColors.lightTeal,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AuthSubmitButton(
          label: 'Login',
          isLoading: isLoading,
          onPressed: onLogin,
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

// ────────────────────────────────────────────
// Form Register — widget terpisah agar isolasi rebuild
// ────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? selectedClass;
  final List<String> classes;
  final ValueChanged<String?> onClassChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onRegister;

  const _RegisterForm({
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.selectedClass,
    required this.classes,
    required this.onClassChanged,
    required this.onToggleObscure,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Column(
      children: [
        AuthTextField(
          controller: usernameController,
          label: 'Username',
          hint: 'Masukkan username Anda',
          icon: Icons.person_outline,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
            NoLeadingSpaceFormatter(),
          ],
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: emailController,
          label: 'Email Address',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        AuthPasswordField(
          controller: passwordController,
          label: 'Password',
          hint: 'Minimal 6 karakter',
          obscure: obscurePassword,
          onToggle: onToggleObscure,
        ),
        const SizedBox(height: 20),
        AuthDropdownField(
          key: ValueKey(classes.length),
          label: 'Class',
          hint: 'Pilih Kelas',
          value: selectedClass,
          items: classes,
          onChanged: onClassChanged,
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 40),
        AuthSubmitButton(
          label: 'Register',
          isLoading: isLoading,
          onPressed: onRegister,
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
