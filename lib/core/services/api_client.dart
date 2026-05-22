import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  bool _isNavigatingToAuth = false;

  ApiClient._internal() {
    // Initial dummy initialization
    dio = Dio();
  }

  Future<void> init() async {
    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
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
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final hasToken = prefs.getString('auth_token') != null;

            if (hasToken && !_isNavigatingToAuth) {
              _isNavigatingToAuth = true;
              
              await prefs.remove('auth_token');
              await prefs.remove('user_data');

              final navigator = MyApp.navigatorKey.currentState;
              if (navigator != null) {
                // Remove all routes and push to AuthScreen
                navigator.pushNamedAndRemoveUntil('/auth', (_) => false);
              }

              // Reset flags after short delay to allow UI to settle
              Future.delayed(const Duration(seconds: 2), () {
                _isNavigatingToAuth = false;
              });
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> login(String email, String password, {bool rememberMe = false}) async {
    return await dio.post(
      '/login',
      data: {'email': email, 'password': password, 'remember_me': rememberMe},
    );
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post('/register', data: data);
  }

  Future<Response> forgotPassword(String email) async {
    return await dio.post('/forgot-password', data: {'email': email});
  }

  Future<Response> verifyOTP(String email, String otp) async {
    return await dio.post('/verify-otp', data: {'email': email, 'otp': otp});
  }

  Future<Response> verifyRegisterOTP(String email, String otp) async {
    return await dio.post('/verify-register-otp', data: {'email': email, 'otp': otp});
  }

  Future<Response> resendRegisterOTP(String email) async {
    return await dio.post('/resend-register-otp', data: {'email': email});
  }

  Future<Response> resetPassword(String email, String otp, String password) async {
    return await dio.post('/reset-password', data: {
      'email': email,
      'otp': otp,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<Response> logout() async {
    return await dio.post('/logout');
  }
}
