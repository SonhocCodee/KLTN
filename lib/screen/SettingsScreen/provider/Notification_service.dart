
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ── Notification IDs ──
  static const int _dailyAnimalMorningId   = 1001;
  static const int _dailyAnimalAfternoonId = 1002;
  static const int _dailyAnimalEveningId   = 1003;
  static const int _streakMorningId        = 2001;
  static const int _streakAfternoonId      = 2002;
  static const int _streakEveningId        = 2003;
  static const int _testNotifId            = 9999;

  // ── SharedPreferences Keys ──
  static const String _keyAllNotif   = 'notif_all_enabled';
  static const String _keyDailyNotif = 'notif_daily_animal';
  static const String _keyStreakNotif = 'notif_streak';
  static const String _keyLastOpen   = 'notif_last_open_date'; // "yyyy-MM-dd"

  // ── Khởi tạo ──
  Future<void> init() async {
    tz.initializeTimeZones();

    // Đặt timezone về Asia/Ho_Chi_Minh (UTC+7)
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  // ── Xin quyền (Android 13+) ──
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS tự hỏi khi init
  }

  // ────────────────────────────────────────────────
  //  Ghi lại ngày mở app (gọi ở main.dart / initState của HomeScreen)
  // ────────────────────────────────────────────────
  Future<void> markAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    await prefs.setString(_keyLastOpen, today);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ────────────────────────────────────────────────
  //  Lấy / Lưu trạng thái toggle
  // ────────────────────────────────────────────────
  Future<bool> isAllEnabled()   async => (await _prefs()).getBool(_keyAllNotif)   ?? true;
  Future<bool> isDailyEnabled() async => (await _prefs()).getBool(_keyDailyNotif) ?? true;
  Future<bool> isStreakEnabled() async => (await _prefs()).getBool(_keyStreakNotif) ?? true;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // ────────────────────────────────────────────────
  //  Cập nhật toàn bộ thông báo dựa trên trạng thái
  // ────────────────────────────────────────────────
  Future<void> setAllNotifications(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyAllNotif, enabled);
    if (!enabled) {
      await cancelAll();
    } else {
      // Bật lại theo cài đặt cũ
      final daily  = prefs.getBool(_keyDailyNotif) ?? true;
      final streak = prefs.getBool(_keyStreakNotif) ?? true;
      if (daily)  await scheduleDailyAnimalNotifications();
      if (streak) await scheduleStreakNotifications();
    }
  }

  Future<void> setDailyAnimalNotif(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyDailyNotif, enabled);
    final allOn = prefs.getBool(_keyAllNotif) ?? true;
    if (!allOn) return; // Tổng đang tắt thì không làm gì

    if (enabled) {
      await scheduleDailyAnimalNotifications();
    } else {
      await _plugin.cancel(_dailyAnimalMorningId);
      await _plugin.cancel(_dailyAnimalAfternoonId);
      await _plugin.cancel(_dailyAnimalEveningId);
    }
  }

  Future<void> setStreakNotif(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyStreakNotif, enabled);
    final allOn = prefs.getBool(_keyAllNotif) ?? true;
    if (!allOn) return;

    if (enabled) {
      await scheduleStreakNotifications();
    } else {
      await _plugin.cancel(_streakMorningId);
      await _plugin.cancel(_streakAfternoonId);
      await _plugin.cancel(_streakEveningId);
    }
  }

  // ────────────────────────────────────────────────
  //  Lên lịch thông báo "Động vật của ngày"
  //  3 lần/ngày: 8h, 13h, 19h — bỏ qua nếu user đã mở app hôm nay
  // ────────────────────────────────────────────────
  Future<void> scheduleDailyAnimalNotifications() async {
    await _plugin.cancel(_dailyAnimalMorningId);
    await _plugin.cancel(_dailyAnimalAfternoonId);
    await _plugin.cancel(_dailyAnimalEveningId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_animal_channel',
        'Động vật của ngày',
        channelDescription: 'Nhắc nhở khám phá động vật mới mỗi ngày',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    final messages = [
      (id: _dailyAnimalMorningId,   hour: 8,  title: '🌅 Buổi sáng cùng thế giới động vật!',   body: 'Hôm nay bạn đã khám phá loài vật mới chưa? Vào xem ngay!'),
      (id: _dailyAnimalAfternoonId, hour: 13, title: '🌞 Giờ nghỉ trưa, khám phá động vật nào!', body: 'Một loài vật thú vị đang chờ bạn khám phá hôm nay!'),
      (id: _dailyAnimalEveningId,   hour: 19, title: '🌙 Buổi tối, đừng bỏ lỡ!',                body: 'Bạn vẫn chưa xem động vật của ngày hôm nay. Còn kịp đấy!'),
    ];

    for (final m in messages) {
      await _plugin.zonedSchedule(
        m.id,
        m.title,
        m.body,
        _nextScheduledTime(m.hour, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // lặp mỗi ngày
        payload: 'daily_animal',
      );
    }
  }

  // ────────────────────────────────────────────────
  //  Lên lịch thông báo "Streak"
  //  3 lần/ngày: 9h, 14h, 20h
  // ────────────────────────────────────────────────
  Future<void> scheduleStreakNotifications() async {
    await _plugin.cancel(_streakMorningId);
    await _plugin.cancel(_streakAfternoonId);
    await _plugin.cancel(_streakEveningId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'streak_channel',
        'Nhắc nhở Streak',
        channelDescription: 'Nhắc duy trì chuỗi ngày liên tiếp',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    final messages = [
      (id: _streakMorningId,   hour: 9,  title: '🔥 Chuỗi của bạn đang chờ!',          body: 'Đừng để chuỗi bị phá vỡ! Vào làm nhiệm vụ ngay nhé.'),
      (id: _streakAfternoonId, hour: 14, title: '⚡ Streak vẫn còn đó, nhanh vào thôi!', body: 'Bạn đang làm rất tốt! Duy trì chuỗi thêm một ngày nữa.'),
      (id: _streakEveningId,   hour: 20, title: '⏰ Còn ít thời gian giữ Streak!',        body: 'Đêm nay bạn đừng quên vào hoàn thành nhiệm vụ nhé!'),
    ];

    for (final m in messages) {
      await _plugin.zonedSchedule(
        m.id,
        m.title,
        m.body,
        _nextScheduledTime(m.hour, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'streak',
      );
    }
  }

  // ────────────────────────────────────────────────
  //  Thông báo TEST — bắn ngay lập tức
  // ────────────────────────────────────────────────
  Future<void> showTestNotification() async {
    await _plugin.show(
      _testNotifId,
      '🧪 Thông báo thử nghiệm',
      'Test test test tét',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          channelDescription: 'Kênh thử nghiệm thông báo',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  Hủy tất cả thông báo
  // ────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ────────────────────────────────────────────────
  //  Helper: tính thời điểm tiếp theo cho giờ:phút
  // ────────────────────────────────────────────────
  tz.TZDateTime _nextScheduledTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ────────────────────────────────────────────────
  //  Kiểm tra user đã mở app hôm nay chưa
  //  (Dùng để quyết định có gửi thông báo không — logic này
  //   nên xử lý phía native nếu muốn chính xác hoàn toàn,
  //   hoặc dùng background fetch để check trước khi gửi)
  // ────────────────────────────────────────────────
  Future<bool> hasOpenedToday() async {
    final prefs = await _prefs();
    final lastOpen = prefs.getString(_keyLastOpen);
    return lastOpen == _todayString();
  }
}