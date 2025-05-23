import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';

class ForecastList extends StatefulWidget {
  final List<DailyForecast> forecast;
  final Function onInfoPressed; // Menambahkan callback untuk info button

  const ForecastList({
    super.key,
    required this.forecast,
    required this.onInfoPressed,
  });

  @override
  State<ForecastList> createState() => _ForecastListState();
}

class _ForecastListState extends State<ForecastList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 164, 163, 201).withAlpha(100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with day forecast text and info icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Day forecast',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.now_widgets_outlined,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () {
                      widget.onInfoPressed();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Animated forecast list - Sekarang menggunakan Expanded dan ListView
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      heightFactor: 1.0 - _heightFactor.value,
                      child: child,
                    ),
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount:
                      widget.forecast.length > 5 ? 5 : widget.forecast.length,
                  itemBuilder: (context, index) {
                    final day = widget.forecast[index];

                    // Determine day name
                    String dayName;
                    if (index == 0) {
                      dayName = 'Today';
                    } else if (index == 1) {
                      dayName = 'Tomorrow';
                    } else {
                      dayName = DateFormat('EEEE').format(day.date);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color:
                            index == 0
                                ? const Color(0xFF8282FF)
                                : const Color.fromARGB(
                                  255,
                                  125,
                                  114,
                                  192,
                                ).withAlpha(400),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Day name
                            SizedBox(
                              width: 100,
                              child: Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      index == 0
                                          ? Colors.white
                                          : Colors.white.withAlpha(80),
                                ),
                              ),
                            ),

                            // Weather icon
                            _getWeatherIcon(day.description),

                            // Temperature range
                            Row(
                              children: [
                                // Max temperature
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '↑ ${day.tempMax.round()}°',
                                        style: TextStyle(
                                          color:
                                              index == 0
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(80),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Min temperature
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '↓ ${day.tempMin.round()}°',
                                        style: TextStyle(
                                          color:
                                              index == 0
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(80),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getWeatherIcon(String description) {
    try {
      // You would replace this with actual asset images from your assets folder
      switch (description.toLowerCase()) {
        case 'clear':
          return Image.asset('assets/clear.png', width: 50, height: 50);
        case 'clouds':
          return Image.asset('assets/cloudy.png', width: 50, height: 50);
        case 'rain':
          return Image.asset('assets/rainy.png', width: 50, height: 50);
        case 'drizzle':
          return Image.asset('assets/rainy.png', width: 50, height: 50);
        case 'thunderstorm':
          return Image.asset('assets/thunder.png', width: 50, height: 50);
        case 'snow':
          return Image.asset('assets/snowy.png', width: 50, height: 50);
        default:
          return Image.asset('assets/cloudy.png', width: 50, height: 50);
      }
    } catch (e) {
      // Fallback to an icon if asset loading fails
      // ignore: avoid_print
      print('Error loading weather icon: $e');
      return const Icon(Icons.cloud, size: 40, color: Colors.white);
    }
  }
}
