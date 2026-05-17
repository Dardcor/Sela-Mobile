import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input field standar untuk layar auth (email, username).
/// Menampilkan label di atas dan hint text di dalam field.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
        floatingLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.black87,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
    );
  }
}

/// Input field password dengan toggle visibilitas.
class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
        floatingLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.black87,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.remove_red_eye_outlined
                : Icons.visibility_off_outlined,
            color: Colors.black54,
          ),
          onPressed: onToggle,
          splashRadius: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
    );
  }
}

/// Custom formatter: mencegah spasi di awal, tapi mengizinkan spasi di tengah.
class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika teks baru dimulai dengan spasi, kembalikan nilai lama (tolak input)
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }
    return newValue;
  }
}
