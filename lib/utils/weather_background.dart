import 'package:flutter/material.dart';

class WeatherBackground {
  static String getBackgroundUrl(String weatherCondition, TimeOfDay timeOfDay) {
    // Mañana (6:00 - 12:00)
    if (timeOfDay.hour >= 6 && timeOfDay.hour < 12) {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'assets/images/weather_backgrounds/morning_clear.jpg';
        case 'rain':
          return 'assets/images/weather_backgrounds/morning_rain.jpg';
        case 'clouds':
          return 'assets/images/weather_backgrounds/morning_clouds.jpg';
        case 'snow':
          return 'assets/images/weather_backgrounds/morning_snow.jpg';
        case 'thunderstorm':
          return 'assets/images/weather_backgrounds/morning_thunderstorm.jpg';
        default:
          return 'assets/images/weather_backgrounds/morning_clear.jpg';
      }
    }
    // Tarde (12:00 - 18:00)
    else if (timeOfDay.hour >= 12 && timeOfDay.hour < 18) {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'assets/images/weather_backgrounds/afternoon_clear.jpg';
        case 'rain':
          return 'assets/images/weather_backgrounds/afternoon_rain.jpg';
        case 'clouds':
          return 'assets/images/weather_backgrounds/afternoon_clouds.jpg';
        case 'snow':
          return 'assets/images/weather_backgrounds/afternoon_snow.jpg';
        case 'thunderstorm':
          return 'assets/images/weather_backgrounds/afternoon_thunderstorm.jpg';
        default:
          return 'assets/images/weather_backgrounds/afternoon_clear.jpg';
      }
    }
    // Noche (18:00 - 6:00)
    else {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'assets/images/weather_backgrounds/night_clear.jpg';
        case 'rain':
          return 'assets/images/weather_backgrounds/night_rain.jpg';
        case 'clouds':
          return 'assets/images/weather_backgrounds/night_clouds.jpg';
        case 'snow':
          return 'assets/images/weather_backgrounds/night_snow.jpg';
        case 'thunderstorm':
          return 'assets/images/weather_backgrounds/night_thunderstorm.jpg';
        default:
          return 'assets/images/weather_backgrounds/night_clear.jpg';
      }
    }
  }

  static Color getTextColor(String weatherCondition, TimeOfDay timeOfDay) {
    return Colors.white;
  }

  static BoxDecoration getOverlayDecoration(
      String weatherCondition, TimeOfDay timeOfDay) {
    Color overlayColor = Colors.black;
    double opacity = 0.3;

    if (timeOfDay.hour >= 6 && timeOfDay.hour < 18) {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          opacity = 0.1;
          break;
        case 'rain':
          opacity = 0.4;
          break;
        case 'clouds':
          opacity = 0.3;
          break;
        default:
          opacity = 0.2;
      }
    } else {
      opacity = 0.5;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          overlayColor.withOpacity(opacity),
          overlayColor.withOpacity(opacity + 0.2),
        ],
      ),
    );
  }
}
