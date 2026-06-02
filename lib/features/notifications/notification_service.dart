import 'package:flutter/foundation.dart'; // <-- DODANE DLA kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../schedule/models/schedule_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Jeśli to przeglądarka Chrome (Web), uciekamy stąd natychmiast!
    if (kIsWeb) return;

    tz.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static tz.TZDateTime _nextInstanceOf(int dayOfWeek, String timeStr, int offsetMinutes) {
    final now = tz.TZDateTime.now(tz.local);
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute).subtract(Duration(minutes: offsetMinutes));

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> rescheduleAll(List<ScheduleItem> items) async {
    // 2. Podwójne zabezpieczenie dla Weba
    if (kIsWeb) return;

    await _notifications.cancelAll();

    for (var item in items) {
      if (item.id == null || item.subject == null) continue;

      final scheduledTime = _nextInstanceOf(item.dayOfWeek, item.startTime, item.reminderOffset);
      final notificationId = item.id.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        'Zajęcia za ${item.reminderOffset} minut!',
        '${item.subject!.name} (${item.classType}) w sali ${item.location ?? "brak danych"}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'uni_schedule_channel',
            'Przypomnienia o zajęciach',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}