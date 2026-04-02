import 'package:flutter/material.dart';
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

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
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

/// Input field dropdown untuk memilih kelas.
class AuthDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const AuthDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          initialSelection: value,
          onSelected: onChanged,
          leadingIcon: Icon(icon, color: Colors.black54),
          trailingIcon: Transform.translate(
            offset: const Offset(8, 0),
            child: const Icon(Icons.expand_more_rounded, color: Colors.black54),
          ),
          selectedTrailingIcon: Transform.translate(
            offset: const Offset(8, 0),
            child: const Icon(Icons.expand_less_rounded, color: Colors.black54),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
            floatingLabelStyle: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black87,
            ),
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
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
          label: Text(label),
          hintText: hint,
          dropdownMenuEntries: items
              .map((e) => DropdownMenuEntry<String>(
                    value: e,
                    label: e,
                    style: MenuItemButton.styleFrom(
                      textStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
