import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/weather_background.dart';

class CurrentWeather extends StatelessWidget {
  final Map<String, dynamic>? weather;

  const CurrentWeather({super.key, this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) return const SizedBox.shrink();

    final timeOfDay = TimeOfDay.now();
    final weatherCondition = weather!['weather'][0]['main'];
    final backgroundUrl =
        WeatherBackground.getBackgroundUrl(weatherCondition, timeOfDay);
    final textColor =
        WeatherBackground.getTextColor(weatherCondition, timeOfDay);
    final overlayDecoration =
        WeatherBackground.getOverlayDecoration(weatherCondition, timeOfDay);

    return Stack(
      children: [
        // Fondo
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: backgroundUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar la imagen',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Overlay gradiente
        Positioned.fill(
          child: Container(
            decoration: overlayDecoration,
          ),
        ),
        // Contenido
        SafeArea(
          child: Column(
            children: [
              _buildHeader(textColor),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMainContent(textColor),
                      _buildHourlyForecast(textColor),
                      _buildDailyForecast(textColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weather!['name'],
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: textColor,
            ),
          ),
          Text(
            '${weather!['main']['temp'].round()}°',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w200,
              color: textColor,
            ),
          ),
          Text(
            weather!['weather'][0]['description'].toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'H:${weather!['main']['temp_max'].round()}° L:${weather!['main']['temp_min'].round()}°',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PRONÓSTICO DEL TIEMPO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                Icons.water_drop,
                'HUMEDAD',
                '${weather!['main']['humidity']}%',
                textColor,
              ),
              _buildWeatherInfo(
                Icons.air,
                'VIENTO',
                '${weather!['wind']['speed']} m/s',
                textColor,
              ),
              _buildWeatherInfo(
                Icons.thermostat,
                'SENSACIÓN',
                '${weather!['main']['feels_like'].round()}°',
                textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
      IconData icon, String label, String value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 24,
        itemBuilder: (context, index) {
          final hour = DateTime.now().add(Duration(hours: index));
          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(hour),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                Icon(Icons.wb_sunny, color: textColor),
                Text(
                  '${(20 + index % 5).toString()}°',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(Color textColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PRONÓSTICO DE 10 DÍAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = DateTime.now().add(Duration(days: index));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        DateFormat('EEEE', 'es').format(day),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.wb_sunny, color: textColor),
                    Row(
                      children: [
                        Text(
                          '${(20 + index % 5).toString()}°',
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.5),
                                Colors.red.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(25 + index % 5).toString()}°',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
