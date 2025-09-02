
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/vehicle.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _fln.initialize(initSettings);
    tzdata.initializeTimeZones();
  }

  Future<void> scheduleForVehicle(Vehicle v) async {
    if (v.id == null) return;
    await cancelForVehicle(v.id!);
    final entries = <_Sched>[];

    void add(DateTime? d, String type) {
      if (d == null) return;
      final days = [20, 10, 2, 0, -1];
      for (final dd in days) {
        final date = DateTime(d.year, d.month, d.day);
        DateTime when;
        if (dd >= 0) {
          when = date.subtract(Duration(days: dd));
        } else {
          when = date.add(const Duration(days: 1)); // for "expired" next day morning
        }
        // Schedule at 9:30 AM local time
        when = DateTime(when.year, when.month, when.day, 9, 30);
        if (when.isBefore(DateTime.now())) continue;
        entries.add(_Sched(
          id: _makeId(v.id!, type, dd),
          when: when,
          title: 'Reminder: $type – ${v.vehicleNumber}',
          body: dd > 0
              ? '$dd दिन बाद expiry है.'
              : (dd == 0 ? 'आज expiry है.' : 'Expiry हो चुकी है.'),
        ));
      }
    }

    add(v.insuranceExpiry, 'Insurance');
    add(v.fitnessExpiry, 'Fitness');
    add(v.pucExpiry, 'PUC');

    for (final e in entries) {
      await _fln.zonedSchedule(
        e.id,
        e.title,
        e.body,
        tz.TZDateTime.from(e.when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('reminders', 'Reminders',
              importance: Importance.max, priority: Priority.high),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  Future<void> cancelForVehicle(int vehicleId) async {
    for (final id in _allIdsForVehicle(vehicleId)) {
      await _fln.cancel(id);
    }
  }

  Iterable<int> _allIdsForVehicle(int id) sync* {
    for (final type in ['Insurance','Fitness','PUC']) {
      for (final dd in [20,10,2,0,-1]) {
        yield _makeId(id, type, dd);
      }
    }
  }

  int _makeId(int id, String type, int dd) {
    final typeNum = {'Insurance':1,'Fitness':2,'PUC':3}[type] ?? 0;
    // Construct unique id
    return id * 100 + typeNum * 10 + (dd == -1 ? 9 : dd);
  }
}

class _Sched {
  final int id;
  final DateTime when;
  final String title;
  final String body;
  _Sched({required this.id, required this.when, required this.title, required this.body});
}
