import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'api_client.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    debugPrint('NotificationService: Initializing...');

    // 1. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS/Darwin Settings
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // 3. Initialize Plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        debugPrint('Notification Clicked! Payload: ${details.payload}');
        if (details.payload != null) {
          try {
            await ApiClient().dio.put('/notifications/${details.payload}', data: {'is_read': true});
          } catch (e) {
            debugPrint('Error marking as read: $e');
          }
        }
      },
    );

    // 4. Setup Android Channel (PENTING untuk Banner)
    if (!kIsWeb) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'sela_high_importance_channel',
            'Sela High Importance Notifications',
            description: 'Notifikasi penting untuk aktivitas Sela.',
            importance: Importance.max,
            playSound: true,
            showBadge: true,
            enableVibration: true,
          ),
        );

        debugPrint('Android Notification Channel Created.');

        // Request Permission (Penting untuk Android 13+)
        // Wait a bit to ensure UI is ready
        Future.delayed(const Duration(seconds: 2), () async {
          final bool? granted = await androidPlugin
              .requestNotificationsPermission();
          debugPrint('Notification Permission Granted: $granted');
        });
      }
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Triggering Native Notification Display...');

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'sela_high_importance_channel',
      'Sela High Importance Notifications',
      channelDescription: 'Notifikasi penting untuk aktivitas Sela.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher', // Tetap gunakan ini sebagai small icon
      largeIcon: const DrawableResourceAndroidBitmap(
        '@mipmap/ic_launcher',
      ), // Logo muncul besar & berwarna di samping
      color: AppColors.primaryTeal, // Memberikan warna pada ikon & teks notifikasi
      colorized: true, // Mengaktifkan pewarnaan di versi Android yang mendukung
      playSound: true,
      enableVibration: true,
      fullScreenIntent: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('System Notification SHOWN successfully.');
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('All native notifications cancelled.');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }
}
