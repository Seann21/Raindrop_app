import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../models/weather_alert.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String extremeWeatherChannelId = 'extreme_weather';
  static const String dailyForecastChannelId = 'daily_forecast';
  static const String generalChannelId = 'general';

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Extreme weather channel (high priority) - WITHOUT LED configuration
    const AndroidNotificationChannel extremeWeatherChannel =
        AndroidNotificationChannel(
          extremeWeatherChannelId,
          'Extreme Weather Alerts',
          description: 'Critical weather alerts and warnings',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          // Removed LED configuration to avoid errors
        );

    // Daily forecast channel (normal priority)
    const AndroidNotificationChannel dailyForecastChannel =
        AndroidNotificationChannel(
          dailyForecastChannelId,
          'Daily Weather Forecast',
          description: 'Daily weather updates and forecasts',
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: true,
        );

    // General channel (low priority)
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          generalChannelId,
          'General Weather Updates',
          description: 'General weather information and updates',
          importance: Importance.low,
          enableVibration: false,
          playSound: false,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(extremeWeatherChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(dailyForecastChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    developer.log('Notification tapped: ${notificationResponse.payload}');
  }

  // Show extreme weather alert - FIXED VERSION
  Future<void> showExtremeWeatherAlert({
    required String city,
    required String alertType,
    required String description,
    String? additionalInfo,
  }) async {
    // Simplified Android notification details without LED
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          extremeWeatherChannelId,
          'Extreme Weather Alerts',
          channelDescription: 'Critical weather alerts and warnings',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          // Removed all LED-related configurations
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 $alertType - $city',
      '$description${additionalInfo != null ? '\n$additionalInfo' : ''}',
      notificationDetails,
      payload: 'extreme_weather:$city:$alertType',
    );

    // Save alert to history
    await _saveAlertToHistory(
      WeatherAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        city: city,
        alertType: alertType,
        description: description,
        timestamp: DateTime.now(),
        severity: AlertSeverity.extreme,
        additionalInfo: additionalInfo,
      ),
    );
  }

  // Show daily forecast notification
  Future<void> showDailyForecast({
    required String city,
    required String forecast,
    required String temperature,
  }) async {
    if (!await _isNotificationEnabled('daily_forecast')) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          dailyForecastChannelId,
          'Daily Weather Forecast',
          channelDescription: 'Daily weather updates and forecasts',
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      '🌤️ Daily Weather - $city',
      '$forecast, $temperature',
      notificationDetails,
      payload: 'daily_forecast:$city',
    );
  }

  // Schedule daily weather notifications
  Future<void> scheduleDailyWeatherNotification({
    required String city,
    required int hour,
    required int minute,
  }) async {
    if (!await _isNotificationEnabled('daily_forecast')) return;

    await _notificationsPlugin.zonedSchedule(
      2,
      '🌤️ Daily Weather Update',
      'Check today\'s weather forecast for $city',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          dailyForecastChannelId,
          'Daily Weather Forecast',
          channelDescription: 'Daily weather updates and forecasts',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'scheduled_daily:$city',
    );
  }

  // Show general weather notification
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await _isNotificationEnabled('general')) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          generalChannelId,
          'General Weather Updates',
          channelDescription: 'General weather information and updates',
          importance: Importance.low,
          enableVibration: false,
          playSound: false,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      3,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Helper methods
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<bool> _isNotificationEnabled(String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_$type') ?? true;
  }

  Future<void> _saveAlertToHistory(WeatherAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alertHistory =
        prefs.getStringList('alert_history') ?? [];

    alertHistory.insert(0, alert.toJson());

    // Keep only last 50 alerts
    if (alertHistory.length > 50) {
      alertHistory.removeRange(50, alertHistory.length);
    }

    await prefs.setStringList('alert_history', alertHistory);
  }

  Future<List<WeatherAlert>> getAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alertHistory =
        prefs.getStringList('alert_history') ?? [];

    return alertHistory
        .map((alertJson) => WeatherAlert.fromJson(alertJson))
        .toList();
  }

  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    return true; // Assume enabled for other platforms
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission() ??
          false;
    }

    return true; // Assume granted for other platforms
  }
}
