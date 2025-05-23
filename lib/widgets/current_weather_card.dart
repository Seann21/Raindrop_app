import 'package:flutter/material.dart';
import '../models/weather.dart';

class CurrentWeatherCard extends StatelessWidget {
  final Weather weather;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 381,
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 169, 162, 239), Color(0xFF6A5ACD)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Weather icon
          Positioned(
            top: 30,
            left: 30,
            child: _getWeatherIcon(weather.description),
          ),
          
          // City name
          Positioned(
            top: 50,
            right: 20,
            child: Text(
              weather.cityName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Temperature
          Positioned(
            top: 91,
            right: 20,
            child: Text(
              '${weather.temperature.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Weather description
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              weather.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Min/Max temperature
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                      Text(
                        '${weather.tempMax.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                      Text(
                        '${weather.tempMin.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String description) {
    // You would replace this with actual asset images from your assets folder
    switch (description.toLowerCase()) {
      case 'clear':
        return Image.asset('assets/clear.png', width: 152, height: 150);
      case 'clouds':
        return Image.asset('assets/cloudy.png', width: 152, height: 150);
      case 'rain':
        return Image.asset('assets/rainy.png', width: 152, height: 150);
      case 'drizzle':
        return Image.asset('assets/rainy.png', width: 152, height: 150);
      case 'thunderstorm':
        return Image.asset('assets/thunder.png', width: 152, height: 150);
      case 'snow':
        return Image.asset('assets/snowy.png', width: 152, height: 150);
      default:
        return Image.asset('assets/cloudy.png', width: 152, height: 150);
    }
  }
}
