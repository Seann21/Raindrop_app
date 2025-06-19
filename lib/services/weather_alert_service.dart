import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import 'weather_service.dart';
import './enchanced_notification_service.dart';

class WeatherAlertService {
  static final WeatherAlertService _instance = WeatherAlertService._internal();
  factory WeatherAlertService() => _instance;
  WeatherAlertService._internal();

  final WeatherService _weatherService = WeatherService();
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();

  Timer? _alertTimer;
  final Duration _checkInterval = const Duration(minutes: 30);

  // Start monitoring weather alerts
  Future<void> startWeatherMonitoring() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alertsEnabled = prefs.getBool('weather_alerts_enabled') ?? true;

    if (!alertsEnabled) return;

    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(_checkInterval, (timer) {
      _checkWeatherAlerts();
    });

    // Initial check
    _checkWeatherAlerts();
  }

  // Stop monitoring weather alerts
  void stopWeatherMonitoring() {
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  // Check for weather alerts
  Future<void> _checkWeatherAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> monitoredCities =
          prefs.getStringList('monitored_cities') ?? [];

      // Add current city if not in monitored cities
      final String? currentCity = prefs.getString('current_city');
      if (currentCity != null && !monitoredCities.contains(currentCity)) {
        monitoredCities.add(currentCity);
      }

      for (String city in monitoredCities) {
        await _checkCityWeatherAlerts(city);
      }
    } catch (e) {
      developer.log('Error checking weather alerts: $e');
    }
  }

  // Check weather alerts for specific city
  Future<void> _checkCityWeatherAlerts(String city) async {
    try {
      final Weather weather = await _weatherService.getWeatherByCity(city);
      final List<WeatherAlert> alerts = _analyzeWeatherForAlerts(weather);

      for (WeatherAlert alert in alerts) {
        // Check if we've already sent this type of alert recently
        if (!await _hasRecentAlert(city, alert.alertType)) {
          await _notificationService.showExtremeWeatherAlert(
            city: city,
            alertType: alert.alertType,
            description: alert.description,
            additionalInfo: alert.additionalInfo,
          );

          // Mark alert as sent
          await _markAlertAsSent(city, alert.alertType);
        }
      }
    } catch (e) {
      developer.log('Error checking alerts for $city: $e');
    }
  }

  // Analyze weather data for potential alerts
  List<WeatherAlert> _analyzeWeatherForAlerts(Weather weather) {
    List<WeatherAlert> alerts = [];

    // Temperature alerts
    if (weather.temperature > 40) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'Extreme Heat',
          description:
              'Temperature is extremely high at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity: AlertSeverity.extreme,
          additionalInfo:
              'Stay hydrated and avoid outdoor activities during peak hours.',
        ),
      );
    } else if (weather.temperature > 35) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'High Temperature',
          description: 'Very hot weather at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity: AlertSeverity.high,
          additionalInfo: 'Take precautions when going outside.',
        ),
      );
    }

    if (weather.temperature < -5) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'Extreme Cold',
          description:
              'Temperature is extremely low at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity: AlertSeverity.extreme,
          additionalInfo: 'Dress warmly and limit time outdoors.',
        ),
      );
    } else if (weather.temperature < 5) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'Cold Weather',
          description: 'Cold temperature at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity: AlertSeverity.moderate,
          additionalInfo: 'Wear appropriate clothing.',
        ),
      );
    }

    // Wind alerts
    if (weather.windSpeed > 25) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'Strong Winds',
          description: 'Very strong winds at ${weather.windSpeed.round()} m/s',
          timestamp: DateTime.now(),
          severity: AlertSeverity.high,
          additionalInfo: 'Avoid outdoor activities and secure loose objects.',
        ),
      );
    } else if (weather.windSpeed > 15) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: 'Windy Conditions',
          description: 'Strong winds at ${weather.windSpeed.round()} m/s',
          timestamp: DateTime.now(),
          severity: AlertSeverity.moderate,
          additionalInfo: 'Be cautious when driving or walking.',
        ),
      );
    }

    // Weather condition alerts
    switch (weather.description.toLowerCase()) {
      case 'thunderstorm':
        alerts.add(
          WeatherAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            city: weather.cityName,
            alertType: 'Thunderstorm',
            description: 'Thunderstorm conditions detected',
            timestamp: DateTime.now(),
            severity: AlertSeverity.high,
            additionalInfo: 'Stay indoors and avoid electrical appliances.',
          ),
        );
        break;
      case 'snow':
        alerts.add(
          WeatherAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            city: weather.cityName,
            alertType: 'Snow',
            description: 'Snow conditions detected',
            timestamp: DateTime.now(),
            severity: AlertSeverity.moderate,
            additionalInfo: 'Drive carefully and dress warmly.',
          ),
        );
        break;
    }

    return alerts;
  }

  // Check if we've sent a similar alert recently
  Future<bool> _hasRecentAlert(String city, String alertType) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'last_alert_${city}_$alertType';
    final int? lastAlertTime = prefs.getInt(key);

    if (lastAlertTime == null) return false;

    final DateTime lastAlert = DateTime.fromMillisecondsSinceEpoch(
      lastAlertTime,
    );
    final Duration timeSinceLastAlert = DateTime.now().difference(lastAlert);

    // Don't send same type of alert within 2 hours
    return timeSinceLastAlert.inHours < 2;
  }

  // Mark alert as sent
  Future<void> _markAlertAsSent(String city, String alertType) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'last_alert_${city}_$alertType';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  // Add city to monitoring list
  Future<void> addCityToMonitoring(String city) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> monitoredCities =
        prefs.getStringList('monitored_cities') ?? [];

    if (!monitoredCities.contains(city)) {
      monitoredCities.add(city);
      await prefs.setStringList('monitored_cities', monitoredCities);
    }
  }

  // Remove city from monitoring list
  Future<void> removeCityFromMonitoring(String city) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> monitoredCities =
        prefs.getStringList('monitored_cities') ?? [];

    monitoredCities.remove(city);
    await prefs.setStringList('monitored_cities', monitoredCities);
  }
}
