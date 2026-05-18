import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Fix FCM leak
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        try {
          await _apiClient.dio.delete('/device-tokens', data: {'token': fcmToken});
        } catch (e) {
          debugPrint('Failed to delete FCM token: $e');
        }
      }

      await _apiClient.logout();
      await _clearLocalData(prefs);

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      final prefs = await SharedPreferences.getInstance();
      await _clearLocalData(prefs);
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }

  Future<void> _clearLocalData(SharedPreferences prefs) async {
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('fcm_token');
  }

  Future<void> changePassword(BuildContext context, String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post('/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui!'),
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errMsg = e.response!.data['message'] ?? 'Failed to change password';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
          );
        }
        throw Exception(errMsg);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengganti kata sandi: $e'),
              backgroundColor: Colors.red
            ),
          );
        }
        throw Exception(e);
      }
    }
  }
}
