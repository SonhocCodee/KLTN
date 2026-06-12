import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_navigator.dart';
import '../firebase_options.dart';
import '../screen/update/update_screen.dart';

// BẮT BUỘC phải là top-level function.
// Hàm này chạy khi app ở background/terminated và nhận data message.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase có thể đã init rồi, bỏ qua.
  }

  debugPrint(
    '[FCM background] messageId=${message.messageId}, data=${message.data}',
  );
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _db = Supabase.instance.client;

  bool _initialized = false;

  static const String generalChannelId = 'push_general_channel';
  static const String updateChannelId = 'push_update_channel';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();
    await _requestPermission();
    await _saveCurrentToken();
    _listenTokenRefresh();
    _listenAuthChange();
    _listenForegroundMessages();
    await _handleInitialMessage();
    _listenNotificationOpened();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          _handleData(data);
        } catch (e) {
          debugPrint('[Push] parse payload error: $e');
        }
      },
    );

    final androidImpl = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        generalChannelId,
        'Thông báo chung',
        description: 'Thông báo từ quản trị viên và hệ thống',
        importance: Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        updateChannelId,
        'Cập nhật ứng dụng',
        description: 'Thông báo khi có phiên bản hoặc bản vá mới',
        importance: Importance.max,
      ),
    );
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[Push] permission=${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> _saveCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Push] token null');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final user = _db.auth.currentUser;

      await _db.from('user_push_tokens').upsert({
        'token': token,
        'user_id': user?.id,
        'platform': _platformName,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'enabled': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');

      debugPrint(
        '[Push] token saved: ${token.substring(0, token.length > 12 ? 12 : token.length)}...',
      );
    } catch (e) {
      debugPrint('[Push] save token error: $e');
    }
  }

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      debugPrint('[Push] token refresh');
      await _saveCurrentToken();
    });
  }

  void _listenAuthChange() {
    _db.auth.onAuthStateChange.listen((event) async {
      // Khi user đăng nhập/đăng xuất thì cập nhật lại user_id cho token hiện tại.
      await _saveCurrentToken();
    });
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        '[Push foreground] ${message.notification?.title} | ${message.data}',
      );
      await _showForegroundNotification(message);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'ZooTrek';
    final body =
        message.notification?.body ??
        message.data['body'] ??
        'Bạn có thông báo mới';
    final type = message.data['type']?.toString() ?? 'general';

    final channelId = type == 'update' ? updateChannelId : generalChannelId;
    final channelName = type == 'update'
        ? 'Cập nhật ứng dụng'
        : 'Thông báo chung';

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: type == 'update'
              ? 'Thông báo khi có phiên bản hoặc bản vá mới'
              : 'Thông báo từ quản trị viên và hệ thống',
          importance: type == 'update' ? Importance.max : Importance.high,
          priority: type == 'update' ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _handleInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Đợi app dựng xong Navigator rồi mới chuyển trang.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleData(initial.data);
      });
    }
  }

  void _listenNotificationOpened() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleData(message.data);
    });
  }

  void _handleData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'general';
    debugPrint('[Push tap] type=$type data=$data');

    if (type == 'update') {
      _openUpdateScreen();
      return;
    }

    // Có thể mở thêm các màn khác sau này:
    // type == 'animal' + animal_id => mở AnimalDetailScreen
    // type == 'daily_fact' => mở trang fact
  }

  void _openUpdateScreen() {
    final nav = AppNavigator.navigatorKey.currentState;
    if (nav == null) return;

    nav.push(MaterialPageRoute(builder: (_) => const UpdateScreen()));
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
