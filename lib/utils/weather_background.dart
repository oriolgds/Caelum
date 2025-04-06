import 'package:flutter/material.dart';

class WeatherBackground {
  static String getBackgroundUrl(String weatherCondition, TimeOfDay timeOfDay) {
    // Mañana (6:00 - 12:00)
    if (timeOfDay.hour >= 6 && timeOfDay.hour < 12) {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'https://i.imgur.com/8jKQGX3.jpg'; // Amanecer soleado
        case 'rain':
          return 'https://i.imgur.com/ZKoqHlE.jpg'; // Lluvia matinal
        case 'clouds':
          return 'https://i.imgur.com/Y2ONpEZ.jpg'; // Nubes matinales
        case 'snow':
          return 'https://i.imgur.com/vQGHHAA.jpg'; // Nieve matinal
        case 'thunderstorm':
          return 'https://i.imgur.com/kJbQPLH.jpg'; // Tormenta matinal
        default:
          return 'https://i.imgur.com/8jKQGX3.jpg';
      }
    }
    // Tarde (12:00 - 18:00)
    else if (timeOfDay.hour >= 12 && timeOfDay.hour < 18) {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'https://i.imgur.com/VxQROYx.jpg'; // Día soleado
        case 'rain':
          return 'https://i.imgur.com/IHp8GZs.jpg'; // Lluvia diurna
        case 'clouds':
          return 'https://i.imgur.com/Y2ONpEZ.jpg'; // Nubes diurnas
        case 'snow':
          return 'https://i.imgur.com/vQGHHAA.jpg'; // Nieve diurna
        case 'thunderstorm':
          return 'https://i.imgur.com/kJbQPLH.jpg'; // Tormenta diurna
        default:
          return 'https://i.imgur.com/VxQROYx.jpg';
      }
    }
    // Noche (18:00 - 6:00)
    else {
      switch (weatherCondition.toLowerCase()) {
        case 'clear':
          return 'https://i.imgur.com/4tKjFeH.jpg'; // Noche despejada
        case 'rain':
          return 'https://i.imgur.com/IHp8GZs.jpg'; // Lluvia nocturna
        case 'clouds':
          return 'https://i.imgur.com/Y2ONpEZ.jpg'; // Nubes nocturnas
        case 'snow':
          return 'https://i.imgur.com/vQGHHAA.jpg'; // Nieve nocturna
        case 'thunderstorm':
          return 'https://i.imgur.com/kJbQPLH.jpg'; // Tormenta nocturna
        default:
          return 'https://i.imgur.com/4tKjFeH.jpg';
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
