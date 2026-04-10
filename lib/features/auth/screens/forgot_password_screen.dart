import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/connectivity_service.dart';
import '../utils/auth_error_utils.dart';
import 'otp_verify_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Please enter your email address'),
          ),
        );
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text(noInternetMessage),
              backgroundColor: Colors.red,
            ),
          );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Supabase: Send recovery email
      // Note: In Supabase dashboard, you can configure if this sends a link or a token.
      // If it sends a token, the user can enter it in OTPVerifyScreen.
      await supabase.auth.resetPasswordForEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Reset code sent! Check your email.'),
            ),
          );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerifyScreen(email: email),
          ),
        );
      }
    } on AuthException catch (e) {
      final message = isNetworkErrorMessage(e.message)
          ? noInternetMessage
          : e.message;
      if (mounted) {
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
    } catch (e) {
      final message = mapAuthErrorMessage(e);
      if (mounted) {
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Image.asset('assets/images/forgot_pass.png', height: 250),
            const SizedBox(height: 40),
            Text(
              'Forgot Password',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Don't worry, we'll help you reset quickly.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Your Email Address',
                labelStyle: GoogleFonts.outfit(color: Colors.grey),
                hintText: 'youremail@gmail.com',
                hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
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
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
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
                        'Reset Password',
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
                    'Back to Login',
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
}
