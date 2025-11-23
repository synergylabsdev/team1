// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import '../models/event_model.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     tz.initializeTimeZones();
    
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
    
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (response) {
//         // Handle notification tap
//       },
//     );
//   }

//   // Schedule event reminders
//   static Future<void> scheduleEventReminders(EventModel event) async {
//     // 24 hours before
//     final reminder24h = event.dateStart.subtract(const Duration(hours: 24));
//     if (reminder24h.isAfter(DateTime.now())) {
//       await _scheduleNotification(
//         id: event.id.hashCode,
//         title: 'Event Reminder',
//         body: '${event.storeName} starts in 24 hours!',
//         scheduledDate: reminder24h,
//       );
//     }

//     // 1 hour before
//     final reminder1h = event.dateStart.subtract(const Duration(hours: 1));
//     if (reminder1h.isAfter(DateTime.now())) {
//       await _scheduleNotification(
//         id: event.id.hashCode + 1,
//         title: 'Event Starting Soon',
//         body: '${event.storeName} starts in 1 hour!',
//         scheduledDate: reminder1h,
//       );
//     }
//   }

//   static Future<void> _scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledDate,
//   }) async {
//     await _notifications.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledDate, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'event_reminders',
//           'Event Reminders',
//           channelDescription: 'Notifications for upcoming events',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       // uiLocalNotificationDateInterpretation:
//       //     UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   // Cancel reminders for an event
//   static Future<void> cancelEventReminders(String eventId) async {
//     await _notifications.cancel(eventId.hashCode);
//     await _notifications.cancel(eventId.hashCode + 1);
//   }
// }

