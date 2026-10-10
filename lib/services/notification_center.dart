import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';

import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';
import 'notification_service.dart';

/// Pusat pengecekan notifikasi lokal (role-aware).
///
/// Dipanggil berkala setelah login. Semua fetch dibungkus try/catch diam-diam
/// sehingga kegagalan jaringan tidak pernah mengganggu aplikasi.
///
/// Role:
/// - teacher → pengumuman + kegiatan guru + reminder jadwal mingguan (/my-week)
/// - admin   → pengumuman + kegiatan + izin guru AKTIF + izin/sakit MENUNGGU
/// - user    → pengumuman + kegiatan murid
/// - parent  → pengumuman + tagihan iuran (bulan Hijriyah berjalan) per anak
class LocalNotificationCenter {
  LocalNotificationCenter._();

  static final LocalNotificationCenter instance = LocalNotificationCenter._();

  static const int _idAnnounce = 100000;
  static const int _idKegiatan = 200000;
  static const int _idReminder = 300000;
  static const int _idIzinGuru = 400001;
  static const int _idIzinSiswa = 400002;
  static const int _idTagihan = 500000;

  static const String _prefSeen = 'notif_seen';
  static const String _prefScheduleIds = 'notif_schedule_ids';

  final ApiService _api = ApiService();

  bool _running = false;

  /// Titik masuk utama: cek semua notifikasi sesuai role user yang login.
  Future<void> runChecks() async {
    if (kIsWeb) return;
    if (_running) return;
    _running = true;
    try {
      final user = await LocalStorage.getUser();
      if (user == null) return;
      final role = (user['role'] as String?) ?? '';

      switch (role) {
        case 'teacher':
        case 'admin':
          await _checkAnnouncements();
          await _checkKegiatan(role);
          if (role == 'teacher') {
            await _scheduleClassReminders(user);
          } else {
            await _checkIzinGuru();
            await _checkIzinSiswa();
          }
          break;
        case 'user':
          await _checkAnnouncements();
          await _checkKegiatan('user');
          break;
        case 'parent':
          await _checkAnnouncements();
          await _checkParentTagihan();
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('[NOTIF] runChecks error: $e');
    } finally {
      _running = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Pengumuman (semua role)
  // ---------------------------------------------------------------------------
  Future<void> _checkAnnouncements() async {
    try {
      final res = await _api.dio.get('/pengumuman/published', queryParameters: {'limit': 10});
      final data = res.data;
      if (data is! Map || data['success'] != true) return;
      final list = (data['data'] as List?) ?? [];
      final prefs = await SharedPreferences.getInstance();
      final seen = _seenSet(prefs);

      for (final raw in list) {
        if (raw is! Map) continue;
        final id = raw['id'];
        if (id == null) continue;
        final key = 'announce_$id';
        if (seen.contains(key)) continue;

        final judul = raw['judul']?.toString() ?? 'Pengumuman';
        final isi = raw['isi']?.toString() ?? '';
        final kategori = raw['kategori']?.toString() ?? 'UMUM';
        final short = _shorten(isi.isEmpty ? '(tanpa isi)' : isi);

        await NotificationService.instance.showNow(
          id: _idAnnounce + (int.tryParse('$id') ?? id.hashCode) % 10000,
          title: '📢 $kategori — $judul',
          body: short,
        );
        seen.add(key);
      }
      if (seen.isNotEmpty) await prefs.setStringList(_prefSeen, seen.toList());
    } catch (e) {
      debugPrint('[NOTIF] pengumuman: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Kegiatan istighosah / non-akademik
  // ---------------------------------------------------------------------------
  Future<void> _checkKegiatan(String role) async {
    try {
      final target = role == 'user' ? 'murid' : (role == 'teacher' ? 'guru' : null);
      final res = await _api.dio.get(
        '/kegiatan',
        queryParameters: target == null ? null : {'target': target},
      );
      final data = res.data;
      if (data is! Map || data['success'] != true) return;
      final list = (data['data'] as List?) ?? [];
      final prefs = await SharedPreferences.getInstance();
      final seen = _seenSet(prefs);

      final now = DateTime.now();
      final today = _dateOnly(now);
      for (final raw in list) {
        if (raw is! Map) continue;
        final id = raw['id'];
        if (id == null) continue;
        final key = 'kegiatan_$id';
        if (seen.contains(key)) continue;

        final nama = raw['activity_name']?.toString() ?? 'Kegiatan';
        final dateStr = raw['activity_date']?.toString() ?? '';
        final desc = raw['description']?.toString() ?? '';
        final repeatType = raw['repeat_type']?.toString() ?? 'ONCE';

        final activityDate = DateTime.tryParse(dateStr);
        if (activityDate == null) continue;
        final diff = activityDate.difference(today).inDays;

        // Reminder: H-1 (ONCE) atau hari ini (WEEKLY/ONCE yang jatuh hari ini).
        bool shouldNotif = false;
        String label;
        if (repeatType == 'WEEKLY') {
          shouldNotif = true; // kegiatan mingguan rutin — ingatkan sekali per pekan
          label = 'Kegiatan mingguan';
        } else if (diff == 0) {
          shouldNotif = true;
          label = 'Kegiatan hari ini';
        } else if (diff == 1) {
          shouldNotif = true;
          label = 'Kegiatan besok';
        } else {
          shouldNotif = false;
          label = 'Kegiatan';
        }
        if (!shouldNotif) continue;

        final waktu = raw['waktu_pelaksanaan']?.toString();
        final waktuTxt = (waktu != null && waktu.isNotEmpty) ? ' • $waktu' : '';

        await NotificationService.instance.showNow(
          id: _idKegiatan + (int.tryParse('$id') ?? id.hashCode) % 10000,
          title: '🗓️ $label: $nama',
          body: _shorten(desc.isEmpty ? label : '$label • $desc') + waktuTxt,
        );
        seen.add(key);
      }
      if (seen.isNotEmpty) await prefs.setStringList(_prefSeen, seen.toList());
    } catch (e) {
      debugPrint('[NOTIF] kegiatan: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reminder jadwal mengajar (teacher, mingguan berulang via /my-week)
  // ---------------------------------------------------------------------------
  Future<void> _scheduleClassReminders(Map<String, dynamic> user) async {
    try {
      final res = await _api.dio.get('/my-week');
      final body = res.data;
      if (body is! Map || body['success'] != true) return;
      final list = (body['data'] as List?) ?? [];
      if (list.isEmpty) return;

      final teacherId = user['id'];
      final prefs = await SharedPreferences.getInstance();

      // Batalkan reminder lama (ganti jadwal / ganti akun guru)
      final oldIds = prefs.getStringList(_prefScheduleIds) ?? const [];
      for (final raw in oldIds) {
        final id = int.tryParse(raw);
        if (id != null) await NotificationService.instance.cancel(id);
      }
      await prefs.remove(_prefScheduleIds);

      final newIds = <String>[];

      for (final raw in list) {
        if (raw is! Map) continue;
        final schedId = raw['schedule_id'];
        if (schedId == null) continue;

        // Hanya jadwal milik guru yang login (bukan badal yang diambil admin).
        if (raw['is_mine'] == false) continue;
        if (teacherId != null && raw['teacher_id'] != null) {
          final ownerId = raw['teacher_id'];
          if (ownerId != raw['substitute_teacher_id'] &&
              '$teacherId'.compareTo('$ownerId') != 0) {
            continue;
          }
        }

        final notifId = _idReminder + (int.tryParse('$schedId') ?? schedId.hashCode) % 10000;

        final subjectName = raw['subject_name']?.toString() ?? 'Pelajaran';
        final className = raw['class_name']?.toString() ?? 'Kelas';
        final day = raw['day_of_week']?.toString().toUpperCase() ?? '';
        final start = raw['start_time']?.toString() ?? '';
        final sesi = raw['session_name']?.toString() ?? '';
        final teachingStatus = raw['teaching_status']?.toString() ?? 'UTAMA';

        final firstFire = _nextOccurrence(day, start, minutesBefore: 15);
        if (firstFire == null) continue;

        final title = teachingStatus == 'PIKET'
            ? '⏰ Masuk Piket (badal) — $sesi'
            : '⏰ Mengajar — $sesi';
        final body =
            '$sesi $subjectName • $className • pukul ${_to12Hour(start)}';
        newIds.add(notifId.toString());

        await NotificationService.instance.scheduleWeeklyReminder(
          id: notifId,
          title: title,
          body: body,
          firstFire: firstFire,
          payload: 'schedule_$schedId',
        );
      }

      if (newIds.isNotEmpty) {
        await prefs.setStringList(_prefScheduleIds, newIds);
      }
    } catch (e) {
      debugPrint('[NOTIF] reminder jadwal: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Izin guru aktif hari ini (admin)
  // ---------------------------------------------------------------------------
  Future<void> _checkIzinGuru() async {
    try {
      final mid = _dayString(DateTime.now());
      final res = await _api.dio.get(
        '/izin-guru',
        queryParameters: {
          'status': 'AKTIF',
          'tanggal_from': mid,
          'tanggal_to': mid,
        },
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) return;
      final count = (body['count'] as num?)?.toInt() ?? 0;
      if (count <= 0) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = _seenSet(prefs);
      final key = 'izinguru_$mid';
      if (seen.contains(key)) return;

      final list = (body['data'] as List?) ?? [];
      final names =
          list.whereType<Map>().where((r) => r['teacher_name'] != null).take(3)
              .map((r) => r['teacher_name'].toString())
              .toList();
      final detail = names.isEmpty ? '' : ': ${names.join(', ')}';

      await NotificationService.instance.showNow(
        id: _idIzinGuru,
        title: '👥 $count guru izin hari ini',
        body: 'Cek jadwal & tunjuk pengganti$detail',
      );
      seen.add(key);
      await prefs.setStringList(_prefSeen, seen.toList());
    } catch (e) {
      debugPrint('[NOTIF] izin guru: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Izin/sakit murid menunggu persetujuan (admin)
  // ---------------------------------------------------------------------------
  Future<void> _checkIzinSiswa() async {
    try {
      final mid = _dayString(DateTime.now());
      final res = await _api.dio.get(
        '/izin-sakit',
        queryParameters: {'status': 'MENUNGGU'},
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) return;
      final list = (body['data'] as List?) ?? [];
      if (list.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = _seenSet(prefs);
      final key = 'izinsiswa_$mid';
      if (seen.contains(key)) return;

      final pending = list.whereType<Map>().toList();
      final count = pending.length;
      final names = pending
          .where((r) => r['student_name'] != null)
          .take(3)
          .map((r) => r['student_name'].toString())
          .toList();
      final detail = names.isEmpty ? '' : ': ${names.join(', ')}';

      await NotificationService.instance.showNow(
        id: _idIzinSiswa,
        title: '📝 $count permintaan izin/sakit menunggu',
        body: 'Ada $count siswa yang butuh persetujuan$detail',
      );
      seen.add(key);
      await prefs.setStringList(_prefSeen, seen.toList());
    } catch (e) {
      debugPrint('[NOTIF] izin siswa: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Tagihan iuran bulan (parent) — hitung bulan Hijriyah berjalan
  // ---------------------------------------------------------------------------
  Future<void> _checkParentTagihan() async {
    try {
      final childrenRes = await _api.dio.get('/parents/me/children');
      final cBody = childrenRes.data;
      if (cBody is! Map || cBody['success'] != true) return;
      final children = (cBody['data'] as List?) ?? [];
      if (children.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = _seenSet(prefs);

      final hijri = HijriCalendar.now();
      final monthName = _hijriMonthName(hijri.hMonth);
      final monthKey = _normalize(monthName);
      final year = hijri.hYear;

      int shown = 0;
      for (final child in children) {
        if (child is! Map || shown >= 3) continue;
        final nim = child['student_nim']?.toString();
        final name = child['student_name']?.toString() ?? 'ananda';
        if (nim == null || nim.isEmpty) continue;

        final txnKey = 'tagihan_${nim}_$monthName';
        if (seen.contains(txnKey)) continue;

        final payRes = await _api.dio.get('/parents/me/children/$nim/pembayaran');
        final pBody = payRes.data;
        if (pBody is! Map || pBody['success'] != true) continue;
        final tx = (pBody['data'] as List?) ?? [];

        final hasYaumiyah = tx.whereType<Map>().any((t) {
          if ((t['payment_type']?.toString() ?? '').toUpperCase() != 'YAUMIYAH') {
            return false;
          }
          final m = _normalize(t['month']?.toString() ?? '');
          return m == monthKey || _monthMatches(t['month']?.toString() ?? '', monthKey);
        });
        if (hasYaumiyah) continue;

        await NotificationService.instance.showNow(
          id: _idTagihan + (shown % 999),
          title: '💰 Iuran $name belum dibayar',
          body: 'YAUMIYAH bulan $monthName $year H — segera lakukan pembayaran',
        );
        seen.add(txnKey);
        shown++;
      }

      if (seen.isNotEmpty) await prefs.setStringList(_prefSeen, seen.toList());
    } catch (e) {
      debugPrint('[NOTIF] tagihan: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pembersihan saat logout: batalkan reminder jadwal tersisa
  // ---------------------------------------------------------------------------
  Future<void> clearScheduleReminders() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefScheduleIds) ?? const [];
      for (final raw in ids) {
        final id = int.tryParse(raw);
        if (id != null) await NotificationService.instance.cancel(id);
      }
      await prefs.remove(_prefScheduleIds);
    } catch (e) {
      debugPrint('[NOTIF] clear reminders: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Set<String> _seenSet(SharedPreferences prefs) =>
      (prefs.getStringList(_prefSeen) ?? const []).toSet();

  String _shorten(String text, {int max = 80}) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dayString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const Map<String, int> _weekday = {
    'AHAD': 7,
    'SENIN': 1,
    'SELASA': 2,
    'RABU': 3,
    'KAMIS': 4,
    'JUMAT': 5,
    'SABTU': 6,
  };

  /// Hitung kejadian berikutnya dari jadwal mingguan (day + start), dikurangi
  /// [minutesBefore] menit. Selalu di masa depan (lompat 7 hari bila sudah lewat).
  DateTime? _nextOccurrence(String day, String start, {int minutesBefore = 15}) {
    final weekday = _weekday[day];
    if (weekday == null) return null;
    final parts = start.split(':');
    if (parts.length < 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;

    final now = DateTime.now();
    var fire = DateTime(now.year, now.month, now.day, hh, mm)
        .subtract(Duration(minutes: minutesBefore));

    var delta = (weekday - now.weekday) % 7;
    if (delta < 0) delta += 7;
    fire = DateTime(now.year, now.month, now.day + delta, hh, mm)
        .subtract(Duration(minutes: minutesBefore));

    // Bila hari ini jadwalnya sudah lewat → ambil pekan depan.
    if (!fire.isAfter(now)) {
      fire = fire.add(const Duration(days: 7));
    }
    return fire;
  }

  String _to12Hour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  // ---------------------------------------------------------------------------
  // Bulan Hijriyah
  // ---------------------------------------------------------------------------
  /// Nama bulan pendek (kasir / hijri package 0-indexed) → bulan ke-1 = Muharram.
  static const List<String> _hijriShort = [
    'Muharram',
    'Shafar',
    'Rb. Ula',
    'Rb. Tsani',
    'Jmd. Ula',
    'Jmd. Tsani',
    'Rajab',
    "Sya'ban",
    'Ramadan',
    'Syawal',
    "Dz. Qo'dah",
    'Dz. Hijjah',
  ];

  String _hijriMonthName(int hMonth) {
    final idx = (((hMonth - 1) % 12) + 12) % 12;
    return _hijriShort[idx];
  }

  static const Map<String, List<String>> _monthAliases = {
    'muharram': ['muharram'],
    'shafar': ['shafar', 'safar'],
    'rbula': ['rbula', 'rbula', 'rb. ula', 'rubiul awal', 'rabiul awal'],
    'rbtsani': ['rbtsani', 'rb. tsani', 'rubiul akhir', 'rabiul akhir'],
    'jmdula': ['jmdula', 'jmd. ula', 'jumadil awal', 'jumadilula'],
    'jmdtsani': ['jmdtsani', 'jmd. tsani', 'jumadil akhir', 'jumadilakhir'],
    'rajab': ['rajab'],
    'syaban': ['syaban', "sya'ban"],
    'ramadan': ['ramadan', 'ramadhan', 'ramadlan'],
    'syawal': ['syawal'],
    'dzulqodah': ['dzulqodah', "dz. qo'dah", 'dzulqa\'dah', 'dzulqadah', 'zulqadah'],
    'dzulhijjah': ['dzulhijjah', 'dz. hijjah', 'dzulhijjah', 'zulhijah'],
  };

  String _normalize(String s) => s.replaceAll(RegExp(r"[^a-zA-Z0-9]"), '').toLowerCase();

  bool _monthMatches(String stored, String canonicalKey) {
    final aliases = _monthAliases[canonicalKey] ?? const [];
    final norm = _normalize(stored);
    return aliases.any((a) => norm == _normalize(a));
  }
}