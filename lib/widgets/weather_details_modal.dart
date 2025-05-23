import 'package:flutter/material.dart';
import '../models/weather.dart';

class WeatherDetailsModal extends StatelessWidget {
  final Weather weather;

  const WeatherDetailsModal({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B4B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: const Center(
              child: Text(
                'Weather details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Details content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF5F5F5),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // First row: Temperature and Humidity
                    Expanded(
                      child: Row(
                        children: [
                          // Temperature
                          Expanded(
                            child: _buildDetailItem(
                              title: 'Temperature',
                              value: '${weather.temperature.round()}°C',
                            ),
                          ),
                          
                          // Humidity
                          Expanded(
                            child: _buildDetailItem(
                              title: 'Humidity',
                              value: '${weather.humidity}%',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Second row: Wind and UV
                    Expanded(
                      child: Row(
                        children: [
                          // Wind
                          Expanded(
                            child: _buildDetailItem(
                              title: 'Wind',
                              value: '${weather.windSpeed} km/h',
                            ),
                          ),
                          
                          // UV
                          Expanded(
                            child: _buildDetailItem(
                              title: 'UV',
                              value: _getUVIndex(weather.temperature),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Third row: Visibility and Air pressure
                    Expanded(
                      child: Row(
                        children: [
                          // Visibility
                          Expanded(
                            child: _buildDetailItem(
                              title: 'Visibility',
                              value: '${(weather.humidity < 80) ? 10 : 5}km',
                            ),
                          ),
                          
                          // Air pressure
                          Expanded(
                            child: _buildDetailItem(
                              title: 'Air pressure',
                              value: '${weather.pressure}hPa',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String title, required String value}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getUVIndex(double temperature) {
    // This is a simplified logic for UV index based on temperature
    // In a real app, you would get this from an API
    if (temperature > 30) {
      return 'Very high';
    } else if (temperature > 25) {
      return 'High';
    } else if (temperature > 20) {
      return 'Moderate';
    } else {
      return 'Very weak';
    }
  }
}
