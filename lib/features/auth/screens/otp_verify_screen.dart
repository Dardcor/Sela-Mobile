import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/network_utils.dart';
import 'new_password_screen.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String email;
  const OTPVerifyScreen({super.key, required this.email});

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
  String? _otpCode;
  bool _isLoading = false;
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpCode == null || _otpCode!.length < 6) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Silakan masukkan 6 digit kode OTP'),
          ),
        );
      return;
    }

    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient().verifyOTP(widget.email, _otpCode!);

      if (res.statusCode == 200 && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPasswordScreen(email: widget.email, otp: _otpCode!)),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.message ?? '')) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text(e.response?.data?['message'] ?? e.message ?? 'Unknown error'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        final message = mapAuthErrorMessage(e);
        if (message == noInternetMessage) {
          showNoInternetSnackBar(context);
        } else {
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
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOTP() async {
    if (!await ConnectivityService.isConnected()) {
      if (mounted) showNoInternetSnackBar(context);
      return;
    }

    try {
      await ApiClient().forgotPassword(widget.email);
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text('Kode baru telah dikirim ke email Anda'),
            ),
          );
      }
    } on DioException catch (e) {
      if (mounted) {
        if (isNetworkErrorMessage(e.message ?? '')) {
          showNoInternetSnackBar(context);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text(e.response?.data?['message'] ?? e.message ?? 'Unknown error'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        final message = mapAuthErrorMessage(e);
        if (message == noInternetMessage) {
          showNoInternetSnackBar(context);
        } else {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 55,
      height: 60,
      textStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/otp.png', height: 250),
              const SizedBox(height: 40),
              Text(
                'Check your email',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Text(
                    'We send a password reset code to',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.email,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primaryTeal, width: 2),
                  ),
                ),
                onChanged: (val) => _otpCode = val,
                separatorBuilder: (index) => const SizedBox(width: 8),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOTP,
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
                          'Verify email',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: _canResend ? _handleResendOTP : null,
                    child: Text(
                      _canResend ? 'Resend again' : 'Resend again (${_countdown}s)',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: _canResend ? const Color(0xFF1597AF) : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
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
}
