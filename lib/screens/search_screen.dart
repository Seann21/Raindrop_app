import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/weather.dart';

// Provider untuk menyimpan riwayat pencarian
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SearchHistoryNotifier(prefs);
    });

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const String key = 'searchHistory';

  SearchHistoryNotifier(this.prefs) : super(prefs.getStringList(key) ?? []);

  void addSearch(String city) {
    // Hapus jika sudah ada untuk menghindari duplikat
    if (state.contains(city)) {
      state = state.where((item) => item != city).toList();
    }

    // Tambahkan ke awal list (paling baru)
    state = [city, ...state];

    // Batasi jumlah riwayat
    if (state.length > 5) {
      state = state.sublist(0, 5);
    }

    prefs.setStringList(key, state);
  }

  void removeSearch(String city) {
    state = state.where((item) => item != city).toList();
    prefs.setStringList(key, state);
  }

  void clearHistory() {
    state = [];
    prefs.setStringList(key, state);
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _searchQuery;
  bool _isSearching = false;
  String? _selectedCity; // Tambahkan variabel untuk menyimpan kota yang dipilih

  @override
  void initState() {
    super.initState();
    // Ambil kota yang sedang aktif dari provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentCity = ref.read(currentCityProvider);
      setState(() {
        _selectedCity = currentCity;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });

      // Tambahkan ke riwayat pencarian
      ref.read(searchHistoryProvider.notifier).addSearch(query);
    }
  }

  Color _getCardColor(String city, bool isDarkMode) {
    // Jika kota ini adalah kota yang dipilih, gunakan warna ungu
    if (city == _selectedCity) {
      return const Color(0xFF8B80F8);
    }
    // Jika tidak, gunakan warna abu-abu yang sesuai dengan mode
    return isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFAAAAAA).withAlpha(200);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteLocations = ref.watch(favoriteLocationsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFEEEEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage the city',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a city',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon:
                      _controller.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _searchQuery = null;
                                _isSearching = false;
                              });
                            },
                          )
                          : null,
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 20),

            // Search results or history
            if (_isSearching && _searchQuery != null)
              _buildSearchResults(_searchQuery!)
            else
              _buildSearchHistory(searchHistory),

            const SizedBox(height: 20),

            // Favorite locations section
            if (favoriteLocations.isNotEmpty) ...[
              Text(
                'Favorite location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteLocations.length,
                  itemBuilder: (context, index) {
                    final location = favoriteLocations[index];
                    return _buildWeatherCard(
                      location,
                      isFavorite: true,
                      color: _getCardColor(location, isDarkMode),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Search for a city to see weather information',
          style: TextStyle(
            color: ref.watch(themeProvider) ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final city = history[index];
          return _buildWeatherCard(
            city,
            isFavorite: ref
                .read(favoriteLocationsProvider.notifier)
                .isFavorite(city),
            color: _getCardColor(city, ref.watch(themeProvider)),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    return Expanded(
      child: Consumer(
        builder: (context, ref, child) {
          final weatherService = ref.read(weatherServiceProvider);
          final validCities = weatherService.searchCities(query);

          if (validCities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'City not found: $query',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check the spelling and try again',
                    style: TextStyle(
                      color:
                          ref.watch(themeProvider)
                              ? Colors.white70
                              : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          // Jika ada kota yang valid, ambil kota pertama
          final city = validCities.first;
          final weatherAsync = ref.watch(weatherProvider(city));

          return weatherAsync.when(
            data: (weather) {
              return _buildWeatherCard(
                weather.cityName,
                weather: weather,
                isFavorite: ref
                    .read(favoriteLocationsProvider.notifier)
                    .isFavorite(weather.cityName),
                color: _getCardColor(
                  weather.cityName,
                  ref.watch(themeProvider),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => Center(
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
                        'City not found: $query',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check the spelling and try again',
                        style: TextStyle(
                          color:
                              ref.watch(themeProvider)
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(
    String city, {
    Weather? weather,
    required bool isFavorite,
    required Color color,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        // If weather is not provided, fetch it
        final weatherAsync =
            weather != null
                ? AsyncValue.data(weather)
                : ref.watch(weatherProvider(city));

        return Container(
          height: 80, // Mengatur tinggi kartu agar lebih kecil
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: weatherAsync.when(
            data: (weatherData) {
              return InkWell(
                onTap: () {
                  // Update kota yang dipilih
                  setState(() {
                    _selectedCity = weatherData.cityName;
                  });

                  // Update provider kota saat ini
                  ref
                      .read(currentCityProvider.notifier)
                      .update((state) => weatherData.cityName);

                  // Kembali ke halaman sebelumnya dengan kota yang dipilih
                  Navigator.pop(context, weatherData.cityName);
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // City name with location icon
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              weatherData.cityName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),

                      // Weather info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${weatherData.temperature.round()}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            weatherData.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Favorite button
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final notifier = ref.read(
                            favoriteLocationsProvider.notifier,
                          );
                          if (isFavorite) {
                            notifier.remove(weatherData.cityName);
                          } else {
                            notifier.add(weatherData.cityName);
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            error:
                (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Text(
                    'Error loading weather for $city',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
          ),
        );
      },
    );
  }
}
