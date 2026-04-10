import 'dart:io';

const String noInternetMessage =
    'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.';

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
