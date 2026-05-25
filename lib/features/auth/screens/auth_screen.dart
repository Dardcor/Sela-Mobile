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
import '../../../core/utils/network_utils.dart';
import 'forgot_password_screen.dart';
import 'register_otp_verify_screen.dart';
import 'onboarding_screen.dart';
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
  }

  Future<void> _loadRememberedCredentials() async {
    final remembered = await _secureStorage.read(key: 'remember_me');
    if (remembered == 'true') {
      final savedEmail =
          await _secureStorage.read(key: 'remembered_email') ?? '';
      final savedPassword =
          await _secureStorage.read(key: 'remembered_password') ?? '';
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
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showUnregisteredError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Akun belum terdaftar, silakan registrasi terlebih dahulu.',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                setState(() {
                  isLogin = false;
                });
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                'DAFTAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      final res = await ApiClient().login(email, password, rememberMe: _rememberMe);

      if (res.statusCode == 200 && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res.data['token']);
        await prefs.setString('user_data', json.encode(res.data['user']));

        // Register FCM device token
        await NotificationService.registerDeviceToken();

        final String email = res.data['user']['email'];
        final userRole = res.data['user']['role'];

        if (_rememberMe) {
          await _secureStorage.write(key: 'remember_me', value: 'true');
          await _secureStorage.write(key: 'remembered_email', value: email);
          await _secureStorage.write(
            key: 'remembered_password',
            value: password,
          );
        } else {
          await _secureStorage.delete(key: 'remember_me');
          await _secureStorage.delete(key: 'remembered_email');
          await _secureStorage.delete(key: 'remembered_password');
        }

        final hasSeenOnboarding = prefs.getBool('has_seen_onboarding_$email') ?? false;

        if (!hasSeenOnboarding) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        } else {
          if (userRole == 'lecturer') {
            Navigator.pushReplacementNamed(context, '/lecturer_navbar');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '🔥 LOGIN DIO ERROR: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}',
      );
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          isNetworkErrorMessage(e.message ?? '')) {
        showNoInternetSnackBar(context);
      } else {
        String msg = 'Email atau Password salah. Silakan coba lagi.';
        String backendMessage = '';
        
        try {
          dynamic responseData = e.response?.data;
          if (responseData is String) {
            try {
              responseData = json.decode(responseData);
            } catch (_) {}
          }
          if (responseData is Map) {
            if (responseData['errors'] != null) {
              final errors = responseData['errors'];
              if (errors is Map && errors.values.isNotEmpty) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  backendMessage = firstError.first.toString();
                } else {
                  backendMessage = firstError.toString();
                }
              }
            }
            if (backendMessage.isEmpty && responseData['message'] != null) {
              backendMessage = responseData['message'].toString();
            }
          }
        } catch (err) {
          debugPrint('Error parsing backend validation message: $err');
        }

        if (backendMessage.isNotEmpty) {
          String lowerMsg = backendMessage.toLowerCase();
          if (lowerMsg.contains('unauthorized') ||
              lowerMsg.contains('not found') ||
              lowerMsg.contains('invalid') ||
              lowerMsg.contains('incorrect') ||
              lowerMsg.contains('credential') ||
              lowerMsg.contains('password salah')) {
            msg = 'Email atau Password salah. Silakan coba lagi.';
            if (lowerMsg.contains('password salah')) {
              msg = 'Password salah.';
            }
          } else {
            msg = backendMessage;
          }
        }

        // Memeriksa pesan spesifik (jika akun tidak ada/belum register)
        if (e.response?.statusCode == 404 ||
            msg.toLowerCase().contains('not found') ||
            msg.toLowerCase().contains('belum terdaftar') ||
            msg.toLowerCase().contains('tidak ditemukan')) {
          _showUnregisteredError();
        } else {
          _showError(msg);
        }
      }
    } catch (e) {
      debugPrint('dY" LOGIN EXCEPTION: $e');
      if (e.toString().contains('SocketException')) {
        showNoInternetSnackBar(context);
      } else {
        _showError('Terjadi kesalahan yang tidak terduga. Silakan coba lagi.');
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

    // Validasi domain email
    final isStudentEmail = email.endsWith('@it.student.pens.ac.id');
    final isLecturerEmail = email.endsWith('@pens.ac.id');

    if (!isStudentEmail && !isLecturerEmail) {
      _showError(
        'Gunakan email kampus: @it.student.pens.ac.id (Mahasiswa) atau @pens.ac.id (Dosen)',
      );
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

    if (!await ConnectivityService.isConnected()) {
      showNoInternetSnackBar(context);
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiClient().register({
        'username': username,
        'email': email,
        'password': password,
      });

      // Success — navigate to OTP verification
      if (mounted) {
        _usernameRegisterController.clear();
        _passwordRegisterController.clear();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterOTPVerifyScreen(email: email),
          ),
        );
        _emailRegisterController.clear();
      }
    } on DioException catch (e) {
      debugPrint(
        '🔥 REGISTER DIO ERROR: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}',
      );
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          isNetworkErrorMessage(e.message ?? '')) {
        // Network error — do NOT navigate
        showNoInternetSnackBar(context);
      } else {
        String msg = e.message ?? 'Kesalahan tidak diketahui';
        if (e.response?.data is Map) {
          msg = e.response?.data?['message'] ?? msg;
        } else if (e.response?.data is String) {
          msg = 'Kesalahan Server: ${e.response?.statusCode}';
        }

        if (e.response?.statusCode == 429) {
          _showError(msg);
          return;
        }

        // Check if user/email already exists — do NOT navigate
        final bool isAlreadyRegistered = msg.contains('User already registered') ||
            msg.contains('The email has already been taken') ||
            msg.contains('Database error saving new user') ||
            msg.contains('username already exists') ||
            msg.contains('The username has already been taken');

        final bool isValidationError = e.response?.data is Map<String, dynamic> &&
            e.response?.data?['errors'] != null;

        if (isAlreadyRegistered) {
          if (msg.contains('User already registered') ||
              msg.contains('The email has already been taken')) {
            _showError('Email ini sudah terdaftar. Silakan login.');
          } else {
            _showError('Username atau Email sudah digunakan. Silakan pilih yang lain.');
          }
        } else if (isValidationError) {
          final errors = e.response?.data['errors'];
          if (errors is Map) {
            final List<String> messages = [];
            errors.forEach((key, value) {
              if (value is List) {
                messages.addAll(value.map((e) => e.toString()));
              } else {
                messages.add(value.toString());
              }
            });
            _showError(messages.join('\n'));
          } else {
            _showError("Form tidak valid");
          }
        } else {
          // Server error but OTP likely sent — navigate to OTP screen
          if (mounted) {
            _usernameRegisterController.clear();
            _passwordRegisterController.clear();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterOTPVerifyScreen(email: email),
              ),
            );
            _emailRegisterController.clear();
          }
        }
      }
    } catch (e) {
      debugPrint('🔥 REGISTER GENERIC ERROR: $e');
      final msg = mapAuthErrorMessage(e);
      if (msg == noInternetMessage) {
        showNoInternetSnackBar(context);
      } else {
        // Non-network generic error — still navigate since OTP may have been sent
        if (mounted) {
          _usernameRegisterController.clear();
          _passwordRegisterController.clear();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterOTPVerifyScreen(email: email),
            ),
          );
          _emailRegisterController.clear();
        }
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
                          'Halo!',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Selamat datang di SELA',
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
                                      30,
                                      30,
                                      30,
                                      0,
                                    ),
                                    child: AuthToggleTab(
                                      isLogin: isLogin,
                                      onLoginTap: () {
                                        if (mounted && !isLogin) {
                                          _pageController.animateToPage(
                                            0,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      onRegisterTap: () {
                                        if (mounted && isLogin) {
                                          _pageController.animateToPage(
                                            1,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.55,
                                    child: PageView(
                                      controller: _pageController,
                                      physics: const BouncingScrollPhysics(),
                                      onPageChanged: (index) {
                                        if (mounted) {
                                          setState(() => isLogin = index == 0);
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
                                                  () => _rememberMe =
                                                      val ?? false,
                                                ),
                                            onLogin: _handleLogin,
                                            onForgotPassword: () => Navigator.push(
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
          label: 'Alamat Email',
          hint: 'contoh@it.student.pens.ac.id',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: passwordController,
          label: 'Password',
          hint: 'Masukkan password',
          obscure: obscurePassword,
          onToggle: onToggleObscure,
        ),
        const SizedBox(height: 8),
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
                Text('Ingat saya', style: GoogleFonts.outfit(fontSize: 14)),
              ],
            ),
            TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Lupa Password?',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Masuk',
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
  final VoidCallback onToggleObscure;
  final VoidCallback onRegister;

  const _RegisterForm({
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
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
          label: 'Alamat Email',
          hint: 'contoh@it.student.pens.ac.id',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Hanya mendukung email @it.student.pens.ac.id (Mahasiswa) atau @pens.ac.id (Dosen)',
            style: GoogleFonts.outfit(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        AuthPasswordField(
          controller: passwordController,
          label: 'Password',
          hint: 'Minimal 6 karakter',
          obscure: obscurePassword,
          onToggle: onToggleObscure,
        ),
        const SizedBox(height: 40),
        AuthSubmitButton(
          label: 'Daftar',
          isLoading: isLoading,
          onPressed: onRegister,
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
