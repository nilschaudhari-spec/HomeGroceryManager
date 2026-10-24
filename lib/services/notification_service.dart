import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/grocery_item.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final dynamic local = await FlutterTimezone.getLocalTimezone();
      final String name = local is String ? local : (local as dynamic).name as String;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
    }
  }

  int _id(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h == 0 ? 1 : h;
  }

  Future<void> schedule(GroceryItem item) async {
    if (!_ready || !item.reminderEnabled) {
      await cancel(item.id);
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      item.reminderHour,
      item.reminderMinute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _id(item.id),
      '${item.name} reorder reminder',
      'Check your ${item.name} stock and reorder if needed.',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grocery_reminders',
          'Grocery reminders',
          channelDescription: 'Local grocery reorder reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: item.id,
    );
  }

  Future<void> lowStock(GroceryItem item) async {
    if (!_ready) return;
    await _plugin.show(
      _id('${item.id}_low'),
      '${item.name} is running low',
      'Current stock: ${item.quantity} ${item.unit}. Add it to your shopping list.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock',
          'Low stock alerts',
          channelDescription: 'Alerts for groceries that need replenishing',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancel(String id) async => _plugin.cancel(_id(id));
}
