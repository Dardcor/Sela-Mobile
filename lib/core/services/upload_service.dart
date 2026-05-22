import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class UploadService {
  final ApiClient _apiClient;

  UploadService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String?> uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      
      // Fix Windows path bug by using path_provider or standard string splitting
      // that handles both backslashes and forward slashes
      final fileName = filePath.split(RegExp(r'[/\]')).last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.dio.post('/upload/avatar', data: formData);
      return response.data['url'];
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  Future<String?> uploadTaskFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split(RegExp(r'[/\]')).last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.dio.post('/upload/task-file', data: formData);
      return response.data['url'];
    } catch (e) {
      debugPrint('Upload task file error: $e');
      return null;
    }
  }
}
