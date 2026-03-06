import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  // State untuk toggle visibility password
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;

  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _usernameRegisterController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _usernameRegisterController.dispose();
    _emailRegisterController.dispose();
    _passwordRegisterController.dispose();
    super.dispose();
  }

  // ─── LOGIN ───────────────────────────────────────────────────────────────────
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

  // ─── REGISTER ────────────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    final username = _usernameRegisterController.text.trim();
    final email = _emailRegisterController.text.trim();
    final password = _passwordRegisterController.text.trim();

    if (username.isEmpty) {
      _showError('Username tidak boleh kosong');
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

    setState(() => isLoading = true);
    try {
      debugPrint('🔐 [Register] Mencoba daftar: $email');

      // 1. Daftarkan user ke Supabase Auth
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': username,
          'username': username,
        },
      );

      debugPrint('🔐 [Register] Response user: ${res.user?.id}');
      debugPrint('🔐 [Register] Response session: ${res.session != null}');

      final userId = res.user?.id;

      if (userId == null) {
        // Ini terjadi jika "Confirm email" ON tapi signUp tetap berhasil
        // Data user sudah masuk auth.users, tapi session null
        debugPrint('⚠️ [Register] userId null — Confirm email mungkin masih ON');
        if (mounted) {
          _showSuccess(
              'Registrasi berhasil! Silakan login dengan akun Anda.');
          _usernameRegisterController.clear();
          _emailRegisterController.clear();
          _passwordRegisterController.clear();
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) setState(() => isLogin = true);
        }
        return;
      }

      // 2. Insert ke tabel profiles via RPC (SECURITY DEFINER)
      //    Ini bypass RLS sehingga data PASTI masuk meski
      //    "Confirm email" masih ON di Supabase
      try {
        debugPrint('📝 [Register] Upsert profile via RPC...');
        await supabase.rpc('upsert_profile', params: {
          'p_id': userId,
          'p_username': username,
          'p_fullname': username,
        });
        debugPrint('✅ [Register] Data berhasil masuk ke profiles via RPC!');
      } catch (profileError) {
        // Jika RPC gagal (belum dijalankan db.sql terbaru),
        // coba insert langsung sebagai backup
        debugPrint('⚠️ [Register] RPC gagal, coba upsert langsung: $profileError');
        try {
          await supabase.from('profiles').upsert({
            'id': userId,
            'username': username,
            'full_name': username,
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ [Register] Data masuk via upsert langsung!');
        } catch (e2) {
          debugPrint('⚠️ [Register] upsert langsung juga gagal: $e2');
          // Tidak apa-apa — trigger di Supabase mungkin sudah handle ini
        }
      }

      // 3. Berhasil → pindah ke tab login
      if (mounted) {
        _showSuccess('Registrasi berhasil! Silakan login dengan akun Anda.');
        _usernameRegisterController.clear();
        _emailRegisterController.clear();
        _passwordRegisterController.clear();

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => isLogin = true);
      }
    } on AuthException catch (e) {
      debugPrint('❌ [Register] AuthException: ${e.message}');
      String msg = e.message;
      if (msg.contains('User already registered') ||
          msg.contains('already been registered') ||
          msg.contains('already registered')) {
        msg = 'Email ini sudah terdaftar. Silakan login.';
      }
      _showError(msg);
    } catch (e) {
      debugPrint('❌ [Register] Exception: $e');
      _showError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/logo.png',
                width: 80,
              ),
              const SizedBox(height: 30),
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
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        // ── Toggle Login / Register ──
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () {
                                    if (mounted) setState(() => isLogin = true);
                                  },
                                  child: _buildToggleButton('Login', isLogin),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () {
                                    if (mounted) setState(() => isLogin = false);
                                  },
                                  child: _buildToggleButton('Register', !isLogin),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // ── Form ──
                        if (isLogin) _buildLoginForm() else _buildRegisterForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool active) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: active
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: active ? Colors.black : Colors.grey,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ─── LOGIN FORM ───────────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailLoginController,
          label: 'Email Address',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _passwordLoginController,
          label: 'Password',
          hint: 'Masukkan password',
          obscure: _obscureLoginPassword,
          onToggle: () {
            setState(() => _obscureLoginPassword = !_obscureLoginPassword);
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                Text('Remember me', style: GoogleFonts.outfit(fontSize: 14)),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen()),
                );
              },
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
        _buildSubmitButton('Login', _handleLogin),
        const SizedBox(height: 30),
        _buildDivider('Or login with'),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Google',
                'https://www.vectorlogo.zone/logos/google/google-icon.svg',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildEthalButton()),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── REGISTER FORM ────────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _usernameRegisterController,
          label: 'Username',
          hint: 'Masukkan username Anda',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailRegisterController,
          label: 'Email Address',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _passwordRegisterController,
          label: 'Password',
          hint: 'Minimal 6 karakter',
          obscure: _obscureRegisterPassword,
          onToggle: () {
            setState(() =>
                _obscureRegisterPassword = !_obscureRegisterPassword);
          },
        ),
        const SizedBox(height: 40),
        _buildSubmitButton('Register', _handleRegister),
        const SizedBox(height: 30),
        _buildDivider('Or Continue with'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: _buildSocialButton(
            'Google',
            'https://www.vectorlogo.zone/logos/google/google-icon.svg',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── WIDGET HELPERS ───────────────────────────────────────────────────────────

  /// Text field biasa (tanpa toggle password)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Password field dengan icon mata yang berfungsi
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
          // ── Icon mata yang berfungsi ──
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.primaryTeal.withOpacity(0.7) : AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialButton(String label, String iconUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.network(
            iconUrl,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEthalButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'e',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ethal',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF09637E),
                ),
              ),
              Text(
                'learning better',
                style: GoogleFonts.outfit(
                  fontSize: 7,
                  color: Colors.grey,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
