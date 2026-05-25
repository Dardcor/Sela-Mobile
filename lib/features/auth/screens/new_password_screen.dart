import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/network_utils.dart';
import 'success_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const NewPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      _showError('Silakan masukkan password baru');
      return;
    }
    if (password != confirmPassword) {
      _showError('Password tidak cocok');
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

    setState(() => _isLoading = true);

    try {
      await ApiClient().resetPassword(widget.email, widget.otp, password);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      }
    } on DioException catch (e) {
      if (isNetworkErrorMessage(e.message ?? '')) {
        showNoInternetSnackBar(context);
      } else {
        _showError(e.response?.data?['message'] ?? e.message ?? 'Kesalahan tidak diketahui');
      }
    } catch (e) {
      final msg = mapAuthErrorMessage(e);
      if (msg == noInternetMessage) {
        showNoInternetSnackBar(context);
      } else {
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/new_pass.png', height: 250),
            const SizedBox(height: 40),
            Text(
              'Atur password baru',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Password baru harus berbeda dari password lama Anda.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password Baru',
              hint: '',
              obscure: _obscurePass,
              onToggle: () => setState(() => _obscurePass = !_obscurePass),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Password',
              hint: '',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Atur Ulang Password',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Kembali ke Login',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.remove_red_eye_outlined : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryTeal),
        ),
      ),
    );
  }
}
