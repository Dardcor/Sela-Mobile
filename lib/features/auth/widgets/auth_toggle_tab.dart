import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tab toggle Login / Register di layar autentikasi.
/// [isLogin] menentukan tab mana yang aktif.
/// [onLoginTap] dan [onRegisterTap] adalah callback saat tab ditekan.
class AuthToggleTab extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthToggleTab({
    super.key,
    required this.isLogin,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) => Container(
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
              onTap: onLoginTap,
              child: _TabButton(label: 'Login', active: isLogin),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onRegisterTap,
              child: _TabButton(label: 'Register', active: !isLogin),
            ),
          ),
        ],
      ),
    );
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;

  const _TabButton({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(5),
      decoration: active
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: active ? Colors.black : Colors.grey,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
}
