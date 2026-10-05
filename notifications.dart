import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'store.dart';
import 'util.dart';

class Notif {
  static final _p = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('diary_reminders', 'Reminders',
        channelDescription: 'Smart Diary reminders', importance: Importance.high, priority: Priority.high),
  );

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}
    await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    try {
      await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (_) {}
  }

  static Future<void> _at(int id, String title, String body, DateTime when) async {
    if (when.isBefore(DateTime.now())) return;
    try {
      await _p.zonedSchedule(id, title, body, tz.TZDateTime.from(when, tz.local), _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    } catch (_) {}
  }

  static Future<void> _daily(int id, String title, String body, int hour) async {
    final now = tz.TZDateTime.now(tz.local);
    var w = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (w.isBefore(now)) w = w.add(const Duration(days: 1));
    try {
      await _p.zonedSchedule(id, title, body, w, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time);
    } catch (_) {}
  }

  static Future<void> rescheduleAll(Store st) async {
    try {
      await _p.cancelAll();
    } catch (_) {}
    final s = st.s;
    if (s.morningOn) await _daily(1, '🌅 सुप्रभात${s.name.isEmpty ? '' : ' ${s.name}'}', 'आजच्या मीटिंग्स आणि कामं बघा.', s.morningHour);
    if (s.eodOn) await _daily(2, '🌙 दिवसाचा शेवट', 'बाकी कामं उद्यावर ढकलायची का? आजची नोंद लिहा.', s.eodHour);
    var count = 0;
    final before = Duration(minutes: s.remindBefore);
    for (final e in sortItems(st.items.where((x) => x.timed && !x.done).toList())) {
      final w = whenOf(e.date, e.time);
      if (w == null || w.isBefore(DateTime.now())) continue;
      final icon = e.type == 'meeting' ? '🤝' : '⏰';
      final who = e.person.isNotEmpty ? ' · ${e.person}' : '';
      if (s.remindBefore > 0) {
        await _at(100000 + e.id * 2, '$icon ${s.remindBefore} मिनिटांनी: ${e.title}', '${e.time}$who', w.subtract(before));
      }
      await _at(100000 + e.id * 2 + 1, '$icon ${e.title}', 'आता वेळ झाली (${e.time})$who', w);
      if (++count > 60) break;
    }
    for (final t in st.items.where((x) => x.type == 'trip' && !x.done)) {
      for (var i = 0; i < t.trip.length && i < 20; i++) {
        final it = t.trip[i];
        final w = whenOf(it.date, it.time);
        if (it.d || w == null) continue;
        await _at(500000 + t.id * 20 + i, '✈️ ${t.title}: ${it.k}', '${it.detail} (${it.time})', w.subtract(const Duration(minutes: 60)));
      }
    }
  }
}
