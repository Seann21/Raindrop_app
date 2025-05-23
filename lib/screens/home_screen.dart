import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../screens/search_screen.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_list.dart';
import '../widgets/weather_details_modal.dart';
import '../services/notification_service.dart';
import '../models/weather.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NotificationService notificationService = NotificationService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    notificationService.initNotification();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Jika izin ditolak, gunakan kota default
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Jika izin ditolak selamanya, gunakan kota default
        setState(() {
          isLoading = false;
        });

        // Tampilkan pesan untuk membuka pengaturan
        if (mounted) {
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

      // Dapatkan posisi pengguna
      final position = await ref.read(currentPositionProvider.future);
      if (position != null) {
        // Dapatkan cuaca berdasarkan posisi
        final weather = await ref.read(weatherByPositionProvider.future);

        // Update provider kota saat ini
        ref
            .read(currentCityProvider.notifier)
            .update((state) => weather.cityName);

        // Cek peringatan cuaca
        _checkForWeatherAlerts();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting location: $e');

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
      final weatherService = ref.read(weatherServiceProvider);
      final currentCity = ref.read(currentCityProvider);
      final hasAlert = await weatherService.hasExtremeWeatherAlert(currentCity);

      if (hasAlert) {
        await notificationService.showNotification(
          title: 'Weather Alert',
          body:
              'Extreme weather conditions expected in $currentCity. Stay safe!',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error checking for weather alerts: $e');
    }
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

    // Jika masih loading, tampilkan indikator loading
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
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.invalidate(weatherProvider(currentCity));
                          ref.invalidate(forecastProvider(currentCity));
                          _checkForWeatherAlerts();
                        },
                      ),

                      // Location button - now has two functions
                      IconButton(
                        icon: const Icon(Icons.location_on_outlined),
                        onPressed: () {
                          // Show dialog to choose between current location or search
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
                                            if (selectedCity != null) {
                                              ref
                                                  .read(
                                                    currentCityProvider
                                                        .notifier,
                                                  )
                                                  .update(
                                                    (state) => selectedCity,
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
                                  Text(
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

              // Forecast list - now includes the header inside with info button
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
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'day forecast',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ],
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
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'day forecast',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Please check your internet connection and try again.',
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
                              ],
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
