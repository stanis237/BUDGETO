import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Default config
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleIntelligentWeeklyNotification({
    required double spentThisWeek,
    required double needs,
    required double expectations,
  }) async {
    // Determine the message based on progress
    String title = 'Bilan de la semaine 📊';
    String body = 'Vous avez dépensé ${spentThisWeek.toStringAsFixed(2)}€ cette semaine. ';
    
    if (needs > 0 && expectations > 0) {
      double totalBudget = needs + expectations;
      // Rough estimation: 1 week is ~1/4 of the month budget
      double weeklyBudget = totalBudget / 4; 
      
      if (spentThisWeek > weeklyBudget) {
        body += 'Attention, vous êtes au-dessus de votre rythme idéal pour atteindre vos attentes mensuelles !';
      } else {
        body += 'Super ! Vous êtes sur la bonne voie pour respecter vos besoins et vos attentes.';
      }
    } else {
      body += 'Pensez à faire le point sur vos objectifs dans l\'application.';
    }

    // Schedule for next Sunday at 18:00
    DateTime now = DateTime.now();
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday < 0) daysUntilSunday += 7;
    
    DateTime nextSunday = DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilSunday));
    nextSunday = nextSunday.add(const Duration(hours: 18));
    
    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      title,
      body,
      tz.TZDateTime.from(nextSunday, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budgeto_weekly',
          'Suivi Hebdomadaire',
          channelDescription: 'Notifications de résumé hebdomadaire',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly
    );
  }
}
