import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../providers/theme_provider.dart';

// Provider untuk layanan cuaca
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// Provider untuk data cuaca berdasarkan kota
final weatherProvider = FutureProvider.family<Weather, String>((
  ref,
  city,
) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getWeatherByCity(city);
});

// Provider untuk data prakiraan cuaca berdasarkan kota
final forecastProvider = FutureProvider.family<List<DailyForecast>, String>((
  ref,
  city,
) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getForecast(city);
});

// Provider untuk kota yang sedang aktif
final currentCityProvider = StateProvider<String>((ref) {
  return 'Kediri'; // Default city
});

// Provider untuk mendapatkan posisi pengguna saat ini
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    // Cek izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Dapatkan posisi pengguna
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  } catch (e) {
    // print('Error getting position: $e');
    return null;
  }
});

// Provider untuk mendapatkan cuaca berdasarkan posisi
final weatherByPositionProvider = FutureProvider<Weather>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) {
    throw Exception('Could not get current position');
  }

  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getWeatherByCoordinates(
    position.latitude,
    position.longitude,
  );
});

// Provider untuk lokasi favorit
final favoriteLocationsProvider =
    StateNotifierProvider<FavoriteLocationsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return FavoriteLocationsNotifier(prefs);
    });

class FavoriteLocationsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const String key = 'favoriteLocations';

  FavoriteLocationsNotifier(this.prefs) : super(prefs.getStringList(key) ?? []);

  void add(String city) {
    if (!state.contains(city)) {
      state = [...state, city];
      prefs.setStringList(key, state);
    }
  }

  void remove(String city) {
    state = state.where((item) => item != city).toList();
    prefs.setStringList(key, state);
  }

  bool isFavorite(String city) {
    return state.contains(city);
  }
}

final lastLocationProvider = StateProvider<String?>((ref) {
  return null;
});
