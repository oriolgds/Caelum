import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _hourlyForecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentWeather => _currentWeather;
  List<Map<String, dynamic>> get hourlyForecast => _hourlyForecast;
  List<Map<String, dynamic>> get dailyForecast => _dailyForecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeatherData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener la ubicación actual
      Position position = await _determinePosition();

      // Obtener el tiempo actual
      final currentWeatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=${dotenv.env['OPENWEATHER_API_KEY']}'));

      if (currentWeatherResponse.statusCode == 200) {
        _currentWeather = json.decode(currentWeatherResponse.body);
      }

      // Obtener pronóstico por horas
      final hourlyForecastResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=${dotenv.env['OPENWEATHER_API_KEY']}'));

      if (hourlyForecastResponse.statusCode == 200) {
        final data = json.decode(hourlyForecastResponse.body);
        _hourlyForecast = List<Map<String, dynamic>>.from(data['list']);

        // Procesar pronóstico diario
        _processDailyForecast(data['list']);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Los permisos de ubicación están permanentemente denegados.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _processDailyForecast(List<dynamic> forecastList) {
    _dailyForecast = [];
    Map<String, dynamic> dailyData = {};

    for (var forecast in forecastList) {
      String date = forecast['dt_txt'].split(' ')[0];

      if (!dailyData.containsKey(date)) {
        dailyData = {
          'date': date,
          'temp_min': double.infinity,
          'temp_max': double.negativeInfinity,
          'weather': forecast['weather'][0],
          'humidity': 0,
          'wind_speed': 0,
        };
      }

      double temp = forecast['main']['temp'].toDouble();
      dailyData['temp_min'] =
          temp < dailyData['temp_min'] ? temp : dailyData['temp_min'];
      dailyData['temp_max'] =
          temp > dailyData['temp_max'] ? temp : dailyData['temp_max'];
      dailyData['humidity'] = forecast['main']['humidity'];
      dailyData['wind_speed'] = forecast['wind']['speed'];

      if (forecast['dt_txt'].contains('12:00:00')) {
        _dailyForecast.add(Map<String, dynamic>.from(dailyData));
      }
    }
  }
}
