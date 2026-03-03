import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Auto-adjust for keyboard
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo at top
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                // Removed color: Colors.white so the actual logo pixels show
              ),
              const SizedBox(height: 30),
              // Greeting Text
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
              // Bottom Container
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
                        // Toggle
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
                        // Conditional Form
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          label: 'Email Address',
          hint: 'anton@it.pens.student.com',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Password',
          hint: 'Qwerty1234567',
          icon: Icons.lock_outline,
          isPassword: true,
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
              onPressed: () {},
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
        _buildSubmitButton('login'),
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
            Expanded(
              child: _buildEthalButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildTextField(
          label: 'Username',
          hint: 'Antonius Wilcoxs',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Email Address',
          hint: 'anton@it.pens.student.com',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Password',
          hint: 'Qwerty1234567',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 40),
        _buildSubmitButton('Register'),
        const SizedBox(height: 50),
        _buildDivider('Or Continue with'),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: _buildSocialButton(
            'Google',
            'https://www.vectorlogo.zone/logos/google/google-icon.svg',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    TextField(
                      obscureText: isPassword,
                      decoration: InputDecoration(
                        hintText: hint,
                        isDense: true,
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPassword)
                const Icon(Icons.remove_red_eye_outlined, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String text) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
