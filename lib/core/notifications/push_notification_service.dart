import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may already be initialized for the background isolate.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'budget_alerts',
    'Budget alerts',
    description: 'Notifications for budget threshold alerts',
    importance: Importance.high,
  );

  bool _initialized = false;
  String? _lastSyncedToken;

  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.messageId}');
    });

    _messaging.onTokenRefresh.listen((token) {
      _lastSyncedToken = null;
      debugPrint('FCM token refreshed');
    });

    _initialized = true;
  }

  Future<void> syncToken(Dio dio) async {
    await initialize();

    final token = await _messaging.getToken();
    debugPrint('FCM token fetched: ${token ?? 'null'}');
    if (token == null || token.isEmpty) {
      debugPrint('FCM token missing, skip sync');
      return;
    }
    if (_lastSyncedToken == token) {
      debugPrint('FCM token already synced, skip');
      return;
    }

    try {
      final res = await dio.post(
        'device-tokens',
        data: {
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );

      _lastSyncedToken = token;
      debugPrint('FCM token synced: status=${res.statusCode}');
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
      rethrow;
    }
  }

  Future<void> clearSyncedToken() async {
    _lastSyncedToken = null;
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Ignore local cleanup failure.
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
