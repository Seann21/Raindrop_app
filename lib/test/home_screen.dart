// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/theme_provider.dart';
// import '../providers/weather_provider.dart';
// import '../screens/search_screen.dart';
// import '../screens/notification_settings_screen.dart';
// import '../screens/alert_history_screen.dart';
// import '../widgets/current_weather_card.dart';
// import '../widgets/forecast_list.dart';
// import '../widgets/weather_details_modal.dart';
// import '../services/enchanced_notification_service.dart';
// import '../services/weather_alert_service.dart';
// import '../models/weather.dart';
// import '../models/weather_alert.dart';
// import 'package:geolocator/geolocator.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen>
//     with WidgetsBindingObserver {
//   final EnhancedNotificationService _notificationService =
//       EnhancedNotificationService();
//   final WeatherAlertService _alertService = WeatherAlertService();
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeServices();
//     _getCurrentLocation();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _alertService.stopWeatherMonitoring();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     switch (state) {
//       case AppLifecycleState.resumed:
//         _alertService.startWeatherMonitoring();
//         break;
//       case AppLifecycleState.paused:
//         break;
//       case AppLifecycleState.detached:
//         _alertService.stopWeatherMonitoring();
//         break;
//       default:
//         break;
//     }
//   }

//   Future<void> _initializeServices() async {
//     try {
//       await _notificationService.initNotification();
//       await _alertService.startWeatherMonitoring();

//       await _notificationService.showGeneralNotification(
//         title: '🌤️ Weather App',
//         body:
//             'Weather monitoring is now active. You\'ll receive alerts for extreme weather.',
//         payload: 'welcome',
//       );
//     } catch (e) {}
//   }

//   Future<void> _getCurrentLocation() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           if (mounted) {
//             setState(() {
//               isLoading = false;
//             });
//           }
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           setState(() {
//             isLoading = false;
//           });

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Izin lokasi ditolak. Silakan aktifkan di pengaturan.',
//               ),
//               action: SnackBarAction(
//                 label: 'Pengaturan',
//                 onPressed: () => Geolocator.openAppSettings(),
//               ),
//             ),
//           );
//         }
//         return;
//       }

//       final position = await ref.read(currentPositionProvider.future);
//       if (position != null && mounted) {
//         final weather = await ref.read(weatherByPositionProvider.future);

//         ref
//             .read(currentCityProvider.notifier)
//             .update((state) => weather.cityName);

//         await _alertService.addCityToMonitoring(weather.cityName);
//         await _checkForWeatherAlerts();
//       }
//     } catch (e) {
//       print('Error getting location: $e');

//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error mendapatkan lokasi: $e')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _checkForWeatherAlerts() async {
//     try {
//       final currentCity = ref.read(currentCityProvider);
//       final weatherService = ref.read(weatherServiceProvider);

//       final weather = await weatherService.getWeatherByCity(currentCity);
//       final alerts = _analyzeWeatherForAlerts(weather);

//       for (var alert in alerts) {
//         await _notificationService.showExtremeWeatherAlert(
//           city: alert.city,
//           alertType: alert.alertType,
//           description: alert.description,
//           additionalInfo: alert.additionalInfo,
//         );
//       }
//     } catch (e) {
//       print('Error checking for weather alerts: $e');
//     }
//   }

//   List<WeatherAlert> _analyzeWeatherForAlerts(Weather weather) {
//     List<WeatherAlert> alerts = [];

//     if (weather.temperature > 35) {
//       alerts.add(
//         WeatherAlert(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           city: weather.cityName,
//           alertType:
//               weather.temperature > 40 ? 'Extreme Heat' : 'High Temperature',
//           description:
//               'Temperature is ${weather.temperature > 40 ? 'extremely' : 'very'} high at ${weather.temperature.round()}°C',
//           timestamp: DateTime.now(),
//           severity:
//               weather.temperature > 40
//                   ? AlertSeverity.extreme
//                   : AlertSeverity.high,
//           additionalInfo:
//               weather.temperature > 40
//                   ? 'Stay indoors and stay hydrated. Avoid outdoor activities.'
//                   : 'Take precautions when going outside. Stay hydrated.',
//         ),
//       );
//     }

//     if (weather.temperature < 5) {
//       alerts.add(
//         WeatherAlert(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           city: weather.cityName,
//           alertType: weather.temperature < 0 ? 'Extreme Cold' : 'Cold Weather',
//           description:
//               'Temperature is ${weather.temperature < 0 ? 'extremely' : 'very'} low at ${weather.temperature.round()}°C',
//           timestamp: DateTime.now(),
//           severity:
//               weather.temperature < 0
//                   ? AlertSeverity.extreme
//                   : AlertSeverity.high,
//           additionalInfo:
//               weather.temperature < 0
//                   ? 'Dress warmly and limit time outdoors. Risk of frostbite.'
//                   : 'Wear appropriate warm clothing.',
//         ),
//       );
//     }

//     if (weather.windSpeed > 15) {
//       alerts.add(
//         WeatherAlert(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           city: weather.cityName,
//           alertType:
//               weather.windSpeed > 25 ? 'Strong Winds' : 'Windy Conditions',
//           description:
//               '${weather.windSpeed > 25 ? 'Very strong' : 'Strong'} winds at ${weather.windSpeed.round()} m/s',
//           timestamp: DateTime.now(),
//           severity:
//               weather.windSpeed > 25
//                   ? AlertSeverity.high
//                   : AlertSeverity.moderate,
//           additionalInfo:
//               weather.windSpeed > 25
//                   ? 'Avoid outdoor activities. Secure loose objects.'
//                   : 'Be cautious when driving or walking.',
//         ),
//       );
//     }

//     switch (weather.description.toLowerCase()) {
//       case 'thunderstorm':
//         alerts.add(
//           WeatherAlert(
//             id: DateTime.now().millisecondsSinceEpoch.toString(),
//             city: weather.cityName,
//             alertType: 'Thunderstorm',
//             description: 'Thunderstorm conditions detected',
//             timestamp: DateTime.now(),
//             severity: AlertSeverity.high,
//             additionalInfo:
//                 'Stay indoors and avoid electrical appliances. Do not use umbrellas.',
//           ),
//         );
//         break;
//       case 'rain':
//         if (weather.humidity > 85) {
//           alerts.add(
//             WeatherAlert(
//               id: DateTime.now().millisecondsSinceEpoch.toString(),
//               city: weather.cityName,
//               alertType: 'Heavy Rain',
//               description: 'Heavy rain conditions with high humidity',
//               timestamp: DateTime.now(),
//               severity: AlertSeverity.moderate,
//               additionalInfo: 'Drive carefully and avoid flooded areas.',
//             ),
//           );
//         }
//         break;
//       case 'snow':
//         alerts.add(
//           WeatherAlert(
//             id: DateTime.now().millisecondsSinceEpoch.toString(),
//             city: weather.cityName,
//             alertType: 'Snow',
//             description: 'Snow conditions detected',
//             timestamp: DateTime.now(),
//             severity: AlertSeverity.moderate,
//             additionalInfo:
//                 'Drive carefully and dress warmly. Roads may be slippery.',
//           ),
//         );
//         break;
//     }

//     return alerts;
//   }

//   void _showWeatherDetails(Weather weather) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => WeatherDetailsModal(weather: weather),
//     );
//   }

//   // Helper method untuk show snackbar dengan mounted check
//   void _showSnackBar(String message, {Color? backgroundColor}) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message), backgroundColor: backgroundColor),
//       );
//     }
//   }

//   // Test methods dengan proper mounted checks
//   Future<void> _testBasicNotification() async {
//     try {
//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Jakarta',
//         alertType: 'Test Alert',
//         description: 'Ini adalah test notifikasi cuaca buruk',
//         additionalInfo: 'Jika Anda melihat ini, notifikasi berhasil!',
//       );

//       _showSnackBar(
//         '✅ Test notifikasi dikirim!',
//         backgroundColor: Colors.green,
//       );
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _testExtremeHeat() async {
//     try {
//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Jakarta',
//         alertType: 'Extreme Heat',
//         description: 'Suhu sangat tinggi 45°C',
//         additionalInfo: 'Hindari aktivitas outdoor!',
//       );

//       _showSnackBar('🔥 Test Extreme Heat dikirim!');
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _testStrongWind() async {
//     try {
//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Surabaya',
//         alertType: 'Strong Winds',
//         description: 'Angin kencang 30 m/s',
//         additionalInfo: 'Amankan barang-barang lepas!',
//       );

//       _showSnackBar('💨 Test Strong Wind dikirim!');
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _testThunderstorm() async {
//     try {
//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Bandung',
//         alertType: 'Thunderstorm',
//         description: 'Badai petir terdeteksi',
//         additionalInfo: 'Tetap di dalam ruangan!',
//       );

//       _showSnackBar('⛈️ Test Thunderstorm dikirim!');
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _testMultipleAlerts() async {
//     try {
//       // Kirim 3 alert sekaligus dengan delay
//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Jakarta',
//         alertType: 'Extreme Heat',
//         description: 'Suhu 45°C',
//         additionalInfo: 'Alert 1 dari 3',
//       );

//       await Future.delayed(const Duration(seconds: 2));

//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Surabaya',
//         alertType: 'Strong Winds',
//         description: 'Angin 30 m/s',
//         additionalInfo: 'Alert 2 dari 3',
//       );

//       await Future.delayed(const Duration(seconds: 2));

//       await _notificationService.showExtremeWeatherAlert(
//         city: 'Bandung',
//         alertType: 'Thunderstorm',
//         description: 'Badai petir',
//         additionalInfo: 'Alert 3 dari 3',
//       );

//       _showSnackBar('🚀 Test Multiple Alerts dikirim!');
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _testBackgroundMonitoring() async {
//     try {
//       await _alertService.startWeatherMonitoring();
//       _showSnackBar('🔄 Background monitoring started!');
//     } catch (e) {
//       _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
//     }
//   }

//   Future<void> _checkPermissions() async {
//     try {
//       final isEnabled = await _notificationService.areNotificationsEnabled();

//       _showSnackBar(
//         isEnabled ? '✅ Notifications ENABLED' : '❌ Notifications DISABLED',
//         backgroundColor: isEnabled ? Colors.green : Colors.red,
//       );

//       if (!isEnabled) {
//         await _notificationService.requestNotificationPermissions();
//       }
//     } catch (e) {
//       _showSnackBar(
//         '❌ Error checking permissions: $e',
//         backgroundColor: Colors.red,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = ref.watch(themeProvider);
//     final currentCity = ref.watch(currentCityProvider);

//     if (isLoading) {
//       return Scaffold(
//         backgroundColor:
//             isDarkMode ? const Color(0xFF121212) : const Color(0xFFEEEEFF),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               Text(
//                 'Mendapatkan lokasi Anda...',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: isDarkMode ? Colors.white : Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor:
//           isDarkMode ? const Color(0xFF121212) : const Color(0xFFEEEEFF),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Dark mode toggle
//                   Switch(
//                     value: isDarkMode,
//                     onChanged: (_) {
//                       ref.read(themeProvider.notifier).toggle();
//                     },
//                     activeColor: Colors.indigo,
//                   ),

//                   Row(
//                     children: [
//                       // Notification settings button
//                       IconButton(
//                         icon: const Icon(Icons.notifications_outlined),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) =>
//                                       const NotificationSettingsScreen(),
//                             ),
//                           );
//                         },
//                         tooltip: 'Notification Settings',
//                       ),

//                       // Alert history button
//                       IconButton(
//                         icon: const Icon(Icons.history),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const AlertHistoryScreen(),
//                             ),
//                           );
//                         },
//                         tooltip: 'Alert History',
//                       ),

//                       // Refresh button
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: () {
//                           ref.invalidate(weatherProvider(currentCity));
//                           ref.invalidate(forecastProvider(currentCity));
//                           _checkForWeatherAlerts();
//                         },
//                         tooltip: 'Refresh Weather',
//                       ),

//                       // Location button
//                       IconButton(
//                         icon: const Icon(Icons.location_on_outlined),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder:
//                                 (context) => AlertDialog(
//                                   title: const Text('Location Options'),
//                                   content: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       ListTile(
//                                         leading: const Icon(Icons.my_location),
//                                         title: const Text(
//                                           'Use current location',
//                                         ),
//                                         onTap: () {
//                                           Navigator.pop(context);
//                                           _getCurrentLocation();
//                                         },
//                                       ),
//                                       ListTile(
//                                         leading: const Icon(Icons.search),
//                                         title: const Text('Search for a city'),
//                                         onTap: () {
//                                           Navigator.pop(context);
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder:
//                                                   (context) =>
//                                                       const SearchScreen(),
//                                             ),
//                                           ).then((selectedCity) {
//                                             if (selectedCity != null &&
//                                                 mounted) {
//                                               ref
//                                                   .read(
//                                                     currentCityProvider
//                                                         .notifier,
//                                                   )
//                                                   .update(
//                                                     (state) => selectedCity,
//                                                   );
//                                               _alertService.addCityToMonitoring(
//                                                 selectedCity,
//                                               );
//                                               _checkForWeatherAlerts();
//                                             }
//                                           });
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                           );
//                         },
//                         tooltip: 'Change Location',
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // TOMBOL TESTING NOTIFIKASI
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withAlpha(25),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.orange, width: 2),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '🧪 TESTING NOTIFIKASI',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange[800],
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     // Test Basic Notification
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testBasicNotification,
//                         icon: const Icon(Icons.notification_add),
//                         label: const Text('🧪 TEST BASIC'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),

//                     // Test Extreme Heat
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testExtremeHeat,
//                         icon: const Icon(Icons.wb_sunny),
//                         label: const Text('🔥 EXTREME HEAT'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),

//                     // Test Strong Wind
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testStrongWind,
//                         icon: const Icon(Icons.air),
//                         label: const Text('💨 STRONG WIND'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),

//                     // Test Thunderstorm
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testThunderstorm,
//                         icon: const Icon(Icons.flash_on),
//                         label: const Text('⛈️ THUNDERSTORM'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.purple,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),

//                     // Test Multiple Alerts
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testMultipleAlerts,
//                         icon: const Icon(Icons.notifications_active),
//                         label: const Text('🚀 MULTIPLE ALERTS'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.deepOrange,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),

//                     // Test Background Monitoring
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _testBackgroundMonitoring,
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('🔄 BACKGROUND TEST'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),

//                     // Check Permissions
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ElevatedButton.icon(
//                         onPressed: _checkPermissions,
//                         icon: const Icon(Icons.security),
//                         label: const Text('🔒 CHECK PERMISSIONS'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Current weather card
//               Consumer(
//                 builder: (context, ref, child) {
//                   final weatherAsync = ref.watch(weatherProvider(currentCity));

//                   return weatherAsync.when(
//                     data: (weather) => CurrentWeatherCard(weather: weather),
//                     loading:
//                         () => const Center(
//                           child: SizedBox(
//                             height: 200,
//                             child: Center(child: CircularProgressIndicator()),
//                           ),
//                         ),
//                     error:
//                         (error, stack) => Center(
//                           child: SizedBox(
//                             height: 200,
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(
//                                     Icons.error_outline,
//                                     size: 48,
//                                     color: Colors.red,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   const Text(
//                                     'Error loading weather data',
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       ref.invalidate(
//                                         weatherProvider(currentCity),
//                                       );
//                                     },
//                                     child: const Text('Retry'),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 20),

//               // Forecast list
//               Consumer(
//                 builder: (context, ref, child) {
//                   final weatherAsync = ref.watch(weatherProvider(currentCity));
//                   final forecastAsync = ref.watch(
//                     forecastProvider(currentCity),
//                   );

//                   return forecastAsync.when(
//                     data:
//                         (forecast) => ForecastList(
//                           forecast: forecast,
//                           onInfoPressed: () {
//                             weatherAsync.whenData((weather) {
//                               _showWeatherDetails(weather);
//                             });
//                           },
//                         ),
//                     loading:
//                         () => Expanded(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF6A5ACD).withAlpha(60),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: const Center(
//                               child: CircularProgressIndicator(),
//                             ),
//                           ),
//                         ),
//                     error:
//                         (error, stack) => Expanded(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF6A5ACD).withAlpha(60),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(
//                                     Icons.error_outline,
//                                     size: 48,
//                                     color: Colors.red,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   const Text(
//                                     'Failed to load forecast data',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       ref.invalidate(
//                                         forecastProvider(currentCity),
//                                       );
//                                     },
//                                     child: const Text('Retry'),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
