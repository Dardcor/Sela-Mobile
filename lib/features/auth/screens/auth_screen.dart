import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../widgets/auth_toggle_tab.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/auth_buttons.dart';
import 'forgot_password_screen.dart';

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

  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _usernameRegisterController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();

  final supabase = Supabase.instance.client;
  final _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      final savedEmail = prefs.getString('remembered_email') ?? '';
      final savedPassword = prefs.getString('remembered_password') ?? '';
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

  Future<void> _handleLogin() async {
    final email = _emailLoginController.text.trim();
    final password = _passwordLoginController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan Password tidak boleh kosong');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('remembered_email', email);
          await prefs.setString('remembered_password', password);
        } else {
          await prefs.remove('remember_me');
          await prefs.remove('remembered_email');
          await prefs.remove('remembered_password');
        }
        
        // Update last_login_at di database
        await supabase.from('profiles').update({
          'last_login_at': DateTime.now().toIso8601String(),
        }).eq('id', res.user!.id);

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('invalid_credentials') ||
          msg.contains('Invalid login credentials')) {
        msg = 'Email atau Password salah. Silakan coba lagi.';
      } else if (msg.contains('Email not confirmed')) {
        msg = 'Email belum dikonfirmasi. Silakan hubungi admin.';
      }
      _showError(msg);
    } catch (e) {
      _showError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final username = _usernameRegisterController.text.trim();
    final email = _emailRegisterController.text.trim();
    final password = _passwordRegisterController.text.trim();

    if (username.isEmpty) { _showError('Username tidak boleh kosong'); return; }
    if (email.isEmpty) { _showError('Email tidak boleh kosong'); return; }
    if (password.isEmpty) { _showError('Password tidak boleh kosong'); return; }
    if (password.length < 6) { _showError('Password minimal 6 karakter'); return; }

    setState(() => isLoading = true);
    try {

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': username, 'username': username},
      );

      final userId = res.user?.id;

      if (userId == null) {
        if (mounted) {
          _showSuccess('Registrasi berhasil! Silakan login dengan akun Anda.');
          _usernameRegisterController.clear();
          _emailRegisterController.clear();
          _passwordRegisterController.clear();
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            setState(() => isLogin = true);
            _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
          }
        }
        return;
      }

      try {
        await supabase.rpc('upsert_profile', params: {
          'p_id': userId, 'p_username': username, 'p_fullname': username,
        });
      } catch (profileError) {
        try {
          await supabase.from('profiles').upsert({
            'id': userId, 'username': username, 'full_name': username,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e2) {
        }
      }

      if (mounted) {
        _showSuccess('Registrasi berhasil! Silakan login dengan akun Anda.');
        _usernameRegisterController.clear();
        _emailRegisterController.clear();
        _passwordRegisterController.clear();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => isLogin = true);
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('User already registered') ||
          msg.contains('already been registered') ||
          msg.contains('already registered')) {
        msg = 'Email ini sudah terdaftar. Silakan login.';
      }
      _showError(msg);
    } catch (e) {
      _showError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.outfit()),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(15),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.outfit()),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primaryTeal,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
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
                        Text('Hello!', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Welcome to SELA', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w400)),
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                            child: AuthToggleTab(
                              isLogin: isLogin,
                              onLoginTap: () {
                                if (mounted && !isLogin) {
                                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                }
                              },
                              onRegisterTap: () {
                                if (mounted && isLogin) {
                                  _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: SizedBox(
                              height: isLogin ? 400 : 480,
                              child: PageView(
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (index) {
                                  if (mounted) setState(() => isLogin = index == 0);
                                },
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
                                    child: _LoginForm(
                                      emailController: _emailLoginController,
                                      passwordController: _passwordLoginController,
                                      obscurePassword: _obscureLoginPassword,
                                      isLoading: isLoading,
                                      rememberMe: _rememberMe,
                                      onToggleObscure: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                                      onRememberMeChanged: (val) => setState(() => _rememberMe = val ?? false),
                                      onLogin: _handleLogin,
                                      onForgotPassword: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
                                    child: _RegisterForm(
                                      usernameController: _usernameRegisterController,
                                      emailController: _emailRegisterController,
                                      passwordController: _passwordRegisterController,
                                      obscurePassword: _obscureRegisterPassword,
                                      isLoading: isLoading,
                                      onToggleObscure: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
                                      onRegister: _handleRegister,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
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
  Widget build(BuildContext context) => Column(
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
            Row(children: [
              Checkbox(
                value: rememberMe, 
                onChanged: onRememberMeChanged,
                activeColor: AppColors.primaryTeal,
              ),
              Text('Remember me', style: GoogleFonts.outfit(fontSize: 14)),
            ]),
            TextButton(
              onPressed: onForgotPassword,
              child: Text('Forgot Password?', style: GoogleFonts.outfit(color: AppColors.lightTeal, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AuthSubmitButton(label: 'Login', isLoading: isLoading, onPressed: onLogin),
        const SizedBox(height: 20),
      ],
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
  Widget build(BuildContext context) => Column(
      children: [
        AuthTextField(
          controller: usernameController,
          label: 'Username',
          hint: 'Masukkan username Anda',
          icon: Icons.person_outline,
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
        const SizedBox(height: 40),
        AuthSubmitButton(label: 'Register', isLoading: isLoading, onPressed: onRegister),
        const SizedBox(height: 20),
      ],
    );
}
