import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../screens/search_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/alert_history_screen.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_list.dart';
import '../widgets/weather_details_modal.dart';
import '../services/enchanced_notification_service.dart';
import '../services/weather_alert_service.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  final WeatherAlertService _alertService = WeatherAlertService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertService.stopWeatherMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _alertService.startWeatherMonitoring();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        _alertService.stopWeatherMonitoring();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.initNotification();
      await _alertService.startWeatherMonitoring();

      await _notificationService.showGeneralNotification(
        title: '🌤️ Weather App',
        body:
            'Weather monitoring is now active. You\'ll receive alerts for extreme weather.',
        payload: 'welcome',
      );
    } catch (e) {
      developer.log('Error getting location: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Izin lokasi ditolak. Silakan aktifkan di pengaturan.',
              ),
              action: SnackBarAction(
                label: 'Pengaturan',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      final position = await ref.read(currentPositionProvider.future);
      if (position != null && mounted) {
        final weather = await ref.read(weatherByPositionProvider.future);

        ref
            .read(currentCityProvider.notifier)
            .update((state) => weather.cityName);

        await _alertService.addCityToMonitoring(weather.cityName);
        await _checkForWeatherAlerts();
      }
    } catch (e) {
      developer.log('Error getting location: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error mendapatkan lokasi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkForWeatherAlerts() async {
    try {
      final currentCity = ref.read(currentCityProvider);
      final weatherService = ref.read(weatherServiceProvider);

      final weather = await weatherService.getWeatherByCity(currentCity);
      final alerts = _analyzeWeatherForAlerts(weather);

      for (var alert in alerts) {
        await _notificationService.showExtremeWeatherAlert(
          city: alert.city,
          alertType: alert.alertType,
          description: alert.description,
          additionalInfo: alert.additionalInfo,
        );
      }
    } catch (e) {
      developer.log('Error getting location: $e');
    }
  }

  List<WeatherAlert> _analyzeWeatherForAlerts(Weather weather) {
    List<WeatherAlert> alerts = [];

    if (weather.temperature > 35) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType:
              weather.temperature > 40 ? 'Extreme Heat' : 'High Temperature',
          description:
              'Temperature is ${weather.temperature > 40 ? 'extremely' : 'very'} high at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity:
              weather.temperature > 40
                  ? AlertSeverity.extreme
                  : AlertSeverity.high,
          additionalInfo:
              weather.temperature > 40
                  ? 'Stay indoors and stay hydrated. Avoid outdoor activities.'
                  : 'Take precautions when going outside. Stay hydrated.',
        ),
      );
    }

    if (weather.temperature < 5) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType: weather.temperature < 0 ? 'Extreme Cold' : 'Cold Weather',
          description:
              'Temperature is ${weather.temperature < 0 ? 'extremely' : 'very'} low at ${weather.temperature.round()}°C',
          timestamp: DateTime.now(),
          severity:
              weather.temperature < 0
                  ? AlertSeverity.extreme
                  : AlertSeverity.high,
          additionalInfo:
              weather.temperature < 0
                  ? 'Dress warmly and limit time outdoors. Risk of frostbite.'
                  : 'Wear appropriate warm clothing.',
        ),
      );
    }

    if (weather.windSpeed > 15) {
      alerts.add(
        WeatherAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: weather.cityName,
          alertType:
              weather.windSpeed > 25 ? 'Strong Winds' : 'Windy Conditions',
          description:
              '${weather.windSpeed > 25 ? 'Very strong' : 'Strong'} winds at ${weather.windSpeed.round()} m/s',
          timestamp: DateTime.now(),
          severity:
              weather.windSpeed > 25
                  ? AlertSeverity.high
                  : AlertSeverity.moderate,
          additionalInfo:
              weather.windSpeed > 25
                  ? 'Avoid outdoor activities. Secure loose objects.'
                  : 'Be cautious when driving or walking.',
        ),
      );
    }

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
            additionalInfo:
                'Stay indoors and avoid electrical appliances. Do not use umbrellas.',
          ),
        );
        break;
      case 'rain':
        if (weather.humidity > 85) {
          alerts.add(
            WeatherAlert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              city: weather.cityName,
              alertType: 'Heavy Rain',
              description: 'Heavy rain conditions with high humidity',
              timestamp: DateTime.now(),
              severity: AlertSeverity.moderate,
              additionalInfo: 'Drive carefully and avoid flooded areas.',
            ),
          );
        }
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
            additionalInfo:
                'Drive carefully and dress warmly. Roads may be slippery.',
          ),
        );
        break;
    }

    return alerts;
  }

  void _showWeatherDetails(Weather weather) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeatherDetailsModal(weather: weather),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentCity = ref.watch(currentCityProvider);

    if (isLoading) {
      return Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFEEEEFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Mendapatkan lokasi Anda...',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFEEEEFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dark mode toggle
                  Switch(
                    value: isDarkMode,
                    onChanged: (_) {
                      ref.read(themeProvider.notifier).toggle();
                    },
                    activeColor: Colors.indigo,
                  ),

                  Row(
                    children: [
                      // Notification settings button
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        tooltip: 'Notification Settings',
                      ),

                      // Alert history button
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AlertHistoryScreen(),
                            ),
                          );
                        },
                        tooltip: 'Alert History',
                      ),

                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.invalidate(weatherProvider(currentCity));
                          ref.invalidate(forecastProvider(currentCity));
                          _checkForWeatherAlerts();
                        },
                        tooltip: 'Refresh Weather',
                      ),

                      // Location button
                      IconButton(
                        icon: const Icon(Icons.location_on_outlined),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Location Options'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.my_location),
                                        title: const Text(
                                          'Use current location',
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _getCurrentLocation();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.search),
                                        title: const Text('Search for a city'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const SearchScreen(),
                                            ),
                                          ).then((selectedCity) {
                                            if (selectedCity != null &&
                                                mounted) {
                                              ref
                                                  .read(
                                                    currentCityProvider
                                                        .notifier,
                                                  )
                                                  .update(
                                                    (state) => selectedCity,
                                                  );
                                              _alertService.addCityToMonitoring(
                                                selectedCity,
                                              );
                                              _checkForWeatherAlerts();
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                          );
                        },
                        tooltip: 'Change Location',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Current weather card
              Consumer(
                builder: (context, ref, child) {
                  final weatherAsync = ref.watch(weatherProvider(currentCity));

                  return weatherAsync.when(
                    data: (weather) => CurrentWeatherCard(weather: weather),
                    loading:
                        () => const Center(
                          child: SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    error:
                        (error, stack) => Center(
                          child: SizedBox(
                            height: 200,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error loading weather data',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.invalidate(
                                        weatherProvider(currentCity),
                                      );
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Forecast list
              Consumer(
                builder: (context, ref, child) {
                  final weatherAsync = ref.watch(weatherProvider(currentCity));
                  final forecastAsync = ref.watch(
                    forecastProvider(currentCity),
                  );

                  return forecastAsync.when(
                    data:
                        (forecast) => ForecastList(
                          forecast: forecast,
                          onInfoPressed: () {
                            weatherAsync.whenData((weather) {
                              _showWeatherDetails(weather);
                            });
                          },
                        ),
                    loading:
                        () => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A5ACD).withAlpha(60),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    error:
                        (error, stack) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A5ACD).withAlpha(60),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load forecast data',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.invalidate(
                                        forecastProvider(currentCity),
                                      );
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
