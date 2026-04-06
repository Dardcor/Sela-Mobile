import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isListenerActive = false;
  static RealtimeChannel? _systemChannel;

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
            final supabase = Supabase.instance.client;
            await supabase
                .from('notifications')
                .update({'is_read': true})
                .eq('id', details.payload!);
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

  static void setupGlobalListener() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('Realtime Notifications: No authenticated user.');
      return;
    }

    if (_isListenerActive) {
      debugPrint(
        'Realtime Notifications: Listener already running for ${user.id}',
      );
      return;
    }

    _isListenerActive = true;
    debugPrint('Realtime Notifications: Subscribing for user ${user.id}...');

    // Close previous channel if exists
    if (_systemChannel != null) {
      supabase.removeChannel(_systemChannel!);
    }

    _systemChannel = supabase.channel('system-realtime-notifications');

    _systemChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint('REALTIME DATA RECEIVED: ${payload.newRecord}');

            final record = payload.newRecord;
            final String title = record['title'] ?? 'SELA Update';
            final String message =
                record['message'] ?? 'Ada aktivitas baru di akunmu.';

            showNotification(
              id: Random().nextInt(100000),
              title: title,
              body: message,
              payload: record['id']?.toString(),
            );
          },
        )
        .subscribe((status, [error]) {
          debugPrint('Realtime Subscription Status: $status');
          if (error != null) {
            debugPrint('Realtime Subscription ERROR: $error');
            _isListenerActive = false; // Allow retry on error
          }
        });
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Triggering Native Notification Display...');

    // Gunakan warna utama aplikasi (Teal)
    const Color selaPrimaryColor = Color(0xFF008080); // Warna Teal

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
      color: selaPrimaryColor, // Memberikan warna pada ikon & teks notifikasi
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
