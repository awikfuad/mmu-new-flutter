import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Layanan notifikasi lokal (tanpa FCM) — berbasis `flutter_local_notifications`.
///
/// Menampilkan notifikasi langsung ([showNow]) maupun terjadwal berulang mingguan
/// ([scheduleWeeklyReminder]) yang otomatis muncul di status bar Android.
/// Waktu lokal dipaksa ke `Asia/Jakarta` agar reminder jadwal madrasah konsisten.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'mmu_notifications';
  static const String _channelName = 'Notifikasi MMU A-44';
  static const String _channelDescription =
      'Notifikasi jadwal pelajaran, izin, kegiatan, pengumuman, dan pembayaran';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;

  bool get isInitialized => _initialized;
  bool get permissionGranted => _permissionGranted;

  /// Inisialisasi plugin + timezone Asia/Jakarta + minta izin notifikasi.
  /// Web tidak didukung `flutter_local_notifications` → aman di-skip.
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // timezone DB tidak memuat lokasi → tetap pakai default (UTC).
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _plugin.initialize(settings);
      _initialized = true;

      _permissionGranted = await _requestPermissions();
    } catch (e) {
      debugPrint('[NOTIF] init gagal: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      bool? granted = true;
      if (android != null) {
        granted = await android.requestNotificationsPermission();
      }
      if (ios != null) {
        await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
      return granted ?? true;
    } catch (e) {
      debugPrint('[NOTIF] requestPermissions gagal: $e');
      return _permissionGranted;
    }
  }

  /// Minta izin notifikasi ulang (dipanggil dari UI bila izin semula ditolak).
  Future<bool> requestPermissionAgain() async {
    _permissionGranted = await _requestPermissions();
    return _permissionGranted;
  }

  /// Tampilkan notifikasi segera (muncul di status bar / heads-up).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_permissionGranted) return;
    try {
      await _plugin.show(id, title, body, _details(), payload: payload);
    } catch (e) {
      debugPrint('[NOTIF] showNow gagal: $e');
    }
  }

  /// Jadwalkan reminder berulang MINGGUAN pada hari & jam tertentu
  /// (mis. 15 menit sebelum jam mengajar), muncul di status bar walau app tertutup.
  /// Menggunakan schedule inexact agar tidak butuh izin SCHEDULE_EXACT_ALARM.
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime firstFire,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    final tzWhen = tz.TZDateTime.from(firstFire.toLocal(), tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NOTIF] scheduleWeeklyReminder gagal: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[NOTIF] cancel gagal: $e');
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NOTIF] cancelAll gagal: $e');
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
}