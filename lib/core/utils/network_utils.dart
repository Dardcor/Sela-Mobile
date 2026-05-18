import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String noInternetMessage =
    'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.';

void showNoInternetSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Text(
          noInternetMessage,
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(15),
      ),
    );
}

bool isNetworkErrorMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('clientexception') ||
      normalized.contains('connection error') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('no address associated with hostname');
}

String mapAuthErrorMessage(Object error) {
  if (error is SocketException) {
    return noInternetMessage;
  }

  if (isNetworkErrorMessage(error.toString())) {
    return noInternetMessage;
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}
