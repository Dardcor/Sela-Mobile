import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    // Initial dummy initialization
    dio = Dio();
  }

  Future<void> init() async {
    String baseUrl = dotenv.env['LARAVEL_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    debugPrint('ApiClient: Using Base URL: $baseUrl');

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle token expiration or unauthorized errors globally if needed
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_data');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Auth Methods
  Future<Response> login(String email, String password) async {
    return await dio.post(
      'login',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post('register', data: data);
  }

  Future<Response> forgotPassword(String email) async {
    return await dio.post('forgot-password', data: {'email': email});
  }

  Future<Response> verifyOTP(String email, String otp) async {
    return await dio.post('verify-otp', data: {'email': email, 'otp': otp});
  }

  Future<Response> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    return await dio.post(
      'reset-password',
      data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }

  Future<Response> logout() async {
    return await dio.post('logout');
  }
}
