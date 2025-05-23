import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteLocations = ref.watch(favoriteLocationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Locations'),
      ),
      body: favoriteLocations.isEmpty
          ? const Center(child: Text('No favorite locations yet'))
          : ListView.builder(
              itemCount: favoriteLocations.length,
              itemBuilder: (context, index) {
                final location = favoriteLocations[index];
                return Consumer(
                  builder: (context, ref, child) {
                    final weatherAsync = ref.watch(weatherProvider(location));
                    
                    return weatherAsync.when(
                      data: (weather) {
                        return ListTile(
                          title: Text(weather.cityName),
                          subtitle: Text('${weather.temperature.toStringAsFixed(1)}°C, ${weather.description}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () {
                                  ref.read(favoriteLocationsProvider.notifier).remove(location);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  Navigator.pop(context, weather.cityName);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context, weather.cityName);
                          },
                        );
                      },
                      loading: () => ListTile(
                        title: Text(location),
                        trailing: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (error, stack) => ListTile(
                        title: Text(location),
                        subtitle: Text('Error: $error'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
