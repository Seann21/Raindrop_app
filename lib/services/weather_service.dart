import 'package:dio/dio.dart';
import '../models/weather.dart';

class WeatherService {
  final Dio _dio = Dio();
  final String apiKey = 'de58dab75faaf6520c258ceabd233a49';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Daftar kota yang valid (bisa diperluas)
  final List<String> validCities = [
    // JAWA TIMUR
    'Surabaya',
    'Malang',
    'Madiun',
    'Bojonegoro',
    'Blitar',
    'Banyuwangi',
    'Probolinggo',
    'Sidoarjo',
    'Jember',
    'Tulungagung',
    'Lamongan',
    'Pasuruan',
    'Kediri',
    'Magetan',
    'Bondowoso',
    'Yogyakarta',
    'Sukorejo',
    'Ponorogo',
    'Tuban',
    'Bojonegoro',
    'Nganjuk',
    'Lumajang',
    'Situbondo',
    'Gresik',
    'Pacitan',
    'Trenggalek',
    'Sampang',
    'Mojokerto',
    'Jombang',
    'Kuala Tungkal',
    'Bangil',

    // JAWA TENGAH
    'Semarang',
    'Solo',
    'Magelang',
    'Tegal',
    'Cilacap',
    'Purwokerto',
    'Salatiga',
    'Sragen',
    'Klaten',
    'Pekalongan',
    'Jepara',
    'Demak',
    'Kudus',
    'Rembang',
    'Banjarnegara',
    'Wonosobo',
    'Temanggung',
    'Karanganyar',
    'Blora',
    'Pati',
    'Sukoharjo',
    'Brebes',
    'Kebumen',
    'Batang',
    'Purbalingga',

    // JAWA BARAT
    'Bandung',
    'Bekasi',
    'Bogor',
    'Cimahi',
    'Depok',
    'Tasikmalaya',
    'Sukabumi',
    'Cirebon',
    'Purwakarta',
    'Kuningan',
    'Subang',
    'Indramayu',
    'Garut',
    'Bandung Barat',
    'Sumedang',
    'Majalengka',
    'Ciamis',
    'Banjar',
    'Sampang',
    'Serang',
    'Jakarta',

    // Bali
    'Denpasar',
    'Badung',
    'Buleleng',
    'Gianyar',
    'Karangasem',
    'Klungkung',
    'Tabanan',
    'Jembrana',

    // Kalimantan
    'Balikpapan',
    'Banjarmasin',
    'Pontianak',
    'Samarinda',
    'Tarakan',
    'Banjarbaru',
    'Palangkaraya',
    'Bontang',
    'Sungai Penuh',
    'Kutim',
    'Pangkalan Bun',
    'Sampit',
    'Tanjung Redeb',
    'Tanjung Selor',
    'Muara Teweh',

    // Sumatra
    'Medan',
    'Palembang',
    'Bandar Lampung',
    'Pekanbaru',
    'Padang',
    'Jambi',
    'Bengkulu',
    'Aceh',
    'Binjai',
    'Lhokseumawe',

    // Sulawesi
    'Makassar',
    'Manado',
    'Palu',
    'Manado',
    'Gorontalo',
    'Kendari',

    // Nusa Tenggara
    'Mataram',
    'Kupang',
    'Bima',

    // Maluku
    'Ambon',
    'Tual',

    // Papua
    'Jayapura',
    'Sorong',
    'Biak',
    'Merauke',

    // THE WORLD
    'New York',
    'Los Angeles',
    'London',
    'Paris',
    'Tokyo',
    'Sydney',
    'Shanghai',
    'Berlin',
    'Moscow',
    'Dubai',
    'Singapore',
    'Hong Kong',
    'Rio de Janeiro',
    'Barcelona',
    'Buenos Aires',
    'Lagos',
    'Mumbai',
    'Delhi',
    'Kuala Lumpur',
    'Seoul',
    'Beijing',
    'Madrid',
    'Mumbai',
    'San Francisco',
    'Chicago',
    'Bangalore',
    'Cape Town',
    'Lagos',
    'Kolkata',
    'Lima',
    'Santiago',
    'Kuwait City',
    'Lagos',
    'Manila',
    'Abu Dhabi',
    'Ho Chi Minh City',
  ];

  // Metode untuk mencari kota yang cocok dengan query
  List<String> searchCities(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return validCities
        .where((city) => city.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  Future<Weather> getWeatherByCity(String city) async {
    try {
      final response = await _dio.get(
        '$baseUrl/weather',
        queryParameters: {'q': city, 'appid': apiKey, 'units': 'metric'},
      );
      return Weather.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get weather data: $e');
    }
  }

  Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '$baseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
        },
      );
      return Weather.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get weather data: $e');
    }
  }

  Future<List<DailyForecast>> getForecast(String city) async {
    try {
      // First get coordinates from city name
      final cityResponse = await _dio.get(
        '$baseUrl/weather',
        queryParameters: {'q': city, 'appid': apiKey, 'units': 'metric'},
      );

      final lat = cityResponse.data['coord']['lat'];
      final lon = cityResponse.data['coord']['lon'];

      // Use 5 day forecast API instead of One Call API (which requires subscription)
      final response = await _dio.get(
        '$baseUrl/forecast',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      // Process the 5-day forecast data (every 3 hours)
      // We'll take one forecast per day
      Map<String, DailyForecast> dailyForecasts = {};

      for (var item in response.data['list']) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        String dateKey = '${date.year}-${date.month}-${date.day}';

        if (!dailyForecasts.containsKey(dateKey)) {
          dailyForecasts[dateKey] = DailyForecast(
            date: date,
            tempMax: item['main']['temp_max'].toDouble(),
            tempMin: item['main']['temp_min'].toDouble(),
            description: item['weather'][0]['main'],
            icon: item['weather'][0]['icon'],
          );
        }
      }

      List<DailyForecast> result = dailyForecasts.values.toList();
      result.sort((a, b) => a.date.compareTo(b.date));

      // Limit to 5 days
      return result.take(5).toList();
    } catch (e) {
      throw Exception('Failed to get forecast data: $e');
    }
  }

  Future<bool> hasExtremeWeatherAlert(String city) async {
    try {
      // First get coordinates from city name
      final cityResponse = await _dio.get(
        '$baseUrl/weather',
        queryParameters: {'q': city, 'appid': apiKey},
      );

      final lat = cityResponse.data['coord']['lat'];
      final lon = cityResponse.data['coord']['lon'];

      // Check current weather for extreme conditions
      final response = await _dio.get(
        '$baseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      // Check for extreme weather conditions
      final temp = response.data['main']['temp'].toDouble();
      final windSpeed = response.data['wind']['speed'].toDouble();
      final weatherId = response.data['weather'][0]['id'];

      // Extreme weather conditions:
      // - Very high temperature (>35°C)
      // - Very low temperature (<0°C)
      // - Strong wind (>20 m/s)
      // - Thunderstorm, heavy rain, etc. (based on weather ID)
      return temp > 35 ||
          temp < 0 ||
          windSpeed > 20 ||
          (weatherId < 300) || // Thunderstorm
          (weatherId >= 500 &&
              weatherId < 600 &&
              weatherId % 100 >= 2); // Heavy rain
    } catch (e) {
      return false;
    }
  }
}
