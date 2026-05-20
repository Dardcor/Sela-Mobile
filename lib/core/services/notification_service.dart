import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constants/colors.dart';
import 'api_client.dart';

// Top-level background message handler — MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.messageId}');
  // Background messages are automatically displayed as system notifications by FCM
  // No need to call showNotification here
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    debugPrint('NotificationService: Initializing...');

    // ── 1. Local Notifications Setup (PRESERVED) ──
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        debugPrint('Notification Clicked! Payload: ${details.payload}');
        if (details.payload != null) {
          try {
            await ApiClient().dio.put(
              'notifications/${details.payload}',
              data: {'is_read': true},
            );
          } catch (e) {
            debugPrint('Error marking as read: $e');
          }
        }
      },
    );

    // Android channel setup
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

        Future.delayed(const Duration(seconds: 2), () async {
          final bool? granted = await androidPlugin
              .requestNotificationsPermission();
          debugPrint('Notification Permission Granted: $granted');
        });
      }
    }

    // ── 2. Firebase Cloud Messaging Setup ──
    if (Firebase.apps.isNotEmpty) {
      await _initFCM();
    } else {
      debugPrint('Firebase not initialized. Skipping FCM setup.');
    }
  }

  /// Initialize FCM: request permission, setup listeners, get token
  static Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground Message: ${message.messageId}');
      final notification = message.notification;
      if (notification != null) {
        showNotification(
          id: message.hashCode,
          title: notification.title ?? 'Sela',
          body: notification.body ?? '',
          payload: message.data['notification_id'],
        );
      }
    });

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Message Opened: ${message.data}');
      final notificationId = message.data['notification_id'];
      if (notificationId != null) {
        try {
          ApiClient().dio.put(
            'notifications/$notificationId',
            data: {'is_read': true},
          );
        } catch (e) {
          debugPrint('Error marking FCM notification as read: $e');
        }
      }
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM Initial Message: ${initialMessage.data}');
      final notificationId = initialMessage.data['notification_id'];
      if (notificationId != null) {
        try {
          await ApiClient().dio.put(
            'notifications/$notificationId',
            data: {'is_read': true},
          );
        } catch (e) {
          debugPrint('Error marking initial FCM notification as read: $e');
        }
      }
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refreshed');
      await _registerTokenWithBackend(newToken);
    });

    // Fetch and store initial FCM token so registerDeviceToken() can use it later
    try {
      final token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        debugPrint('FCM initial token stored locally');
      }
    } catch (e) {
      debugPrint('Error fetching initial FCM token: $e');
    }
  }

  /// Get the current FCM token and register with backend
  static Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Unregister device token from backend (call on logout)
  static Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        await ApiClient().dio.delete('device-tokens', data: {'token': token});
        await prefs.remove('fcm_token');
        debugPrint('FCM token unregistered');
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only register if we have an auth token (user is logged in)
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;

      await ApiClient().dio.post(
        'device-tokens',
        data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
      await prefs.setString('fcm_token', token);
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  // ── Existing methods (PRESERVED EXACTLY) ──

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Triggering Native Notification Display...');

    const String groupKey = 'com.sela.app.NOTIFICATION_GROUP';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'sela_high_importance_channel',
          'Sela High Importance Notifications',
          channelDescription: 'Notifikasi penting untuk aktivitas Sela.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: AppColors.primaryTeal,
          colorized: true,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
          groupKey: groupKey,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    const AndroidNotificationDetails summaryAndroidDetails =
        AndroidNotificationDetails(
          'sela_high_importance_channel',
          'Sela High Importance Notifications',
          channelDescription: 'Notifikasi penting untuk aktivitas Sela.',
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          icon: '@mipmap/ic_launcher',
          color: AppColors.primaryTeal,
        );

    const NotificationDetails summaryNotificationDetails = NotificationDetails(
      android: summaryAndroidDetails,
      iOS: DarwinNotificationDetails(), // iOS groups automatically
    );

    try {
      // Show the actual notification
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // Show the summary notification to group them (use a fixed ID for the summary)
      await _notificationsPlugin.show(
        88888, // Fixed ID for summary to avoid collision
        'Sela Notifications',
        'You have new notifications',
        summaryNotificationDetails,
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
