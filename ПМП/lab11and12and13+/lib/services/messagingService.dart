import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Фоновое сообщение получено: ${message.messageId}');
  }
}

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Запрос разрешений на уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('Статус разрешений: ${settings.authorizationStatus}');
    }

    // Инициализация локальных уведомлений
    await _initializeLocalNotifications();

    // Обработчик фоновых сообщений
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Обработчик сообщений когда приложение открыто
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработчик нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Было ли приложение открыто из уведомления
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    String? token = await _messaging.getToken();
    if (kDebugMode && token != null) {
      print('FCM Token: $token');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('Новый FCM Token: $newToken');
      }
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Обработка уведомлений когда приложение открыто
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Получено сообщение в foreground: ${message.messageId}');
      print('Данные: ${message.data}');
      print('Уведомление: ${message.notification?.title}');
    }
    await _showLocalNotification(message);
  }

  // Показать локальное уведомление
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Уведомления',
      channelDescription: 'Канал для уведомлений приложения',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Новое уведомление',
      notification.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Уведомление нажато: ${response.payload}');
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    if (kDebugMode) {
      print('Приложение открыто из уведомления: ${message.messageId}');
      print('Данные: ${message.data}');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Подписан на: $topic');
    }
  }
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Отписан от: $topic');
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

