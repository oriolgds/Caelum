import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _hourlyForecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  DateTime? _sunrise;
  DateTime? _sunset;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentWeather => _currentWeather;
  List<Map<String, dynamic>> get hourlyForecast => _hourlyForecast;
  List<Map<String, dynamic>> get dailyForecast => _dailyForecast;
  DateTime? get sunrise => _sunrise;
  DateTime? get sunset => _sunset;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeatherData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Verificar API key
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
            'La API key de OpenWeather no está configurada correctamente');
      }

      // Obtener la ubicación actual
      debugPrint('Obteniendo ubicación actual...');
      Position position = await _determinePosition();
      debugPrint(
          'Ubicación obtenida: ${position.latitude}, ${position.longitude}');

      // Obtener el tiempo actual
      debugPrint('Obteniendo datos de clima actual...');
      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';

      final currentWeatherResponse = await http
          .get(Uri.parse(currentWeatherUrl))
          .timeout(const Duration(seconds: 10));

      if (currentWeatherResponse.statusCode == 200) {
        _currentWeather = json.decode(currentWeatherResponse.body);
        debugPrint('Datos de clima actual obtenidos correctamente');

        // Extraer datos de amanecer y atardecer
        if (_currentWeather?['sys'] != null) {
          final sunriseTimestamp = _currentWeather!['sys']['sunrise'];
          final sunsetTimestamp = _currentWeather!['sys']['sunset'];

          _sunrise =
              DateTime.fromMillisecondsSinceEpoch(sunriseTimestamp * 1000);
          _sunset = DateTime.fromMillisecondsSinceEpoch(sunsetTimestamp * 1000);
          debugPrint('Amanecer: $_sunrise, Atardecer: $_sunset');
        }
      } else {
        throw Exception(
            'Error al obtener datos del clima actual: ${currentWeatherResponse.statusCode} - ${currentWeatherResponse.body}');
      }

      // Obtener pronóstico por horas
      debugPrint('Obteniendo pronóstico por horas...');
      final hourlyForecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';

      final hourlyForecastResponse = await http
          .get(Uri.parse(hourlyForecastUrl))
          .timeout(const Duration(seconds: 10));

      if (hourlyForecastResponse.statusCode == 200) {
        final data = json.decode(hourlyForecastResponse.body);
        final List<dynamic> list = data['list'];
        debugPrint('Datos de pronóstico obtenidos: ${list.length} entradas');

        // Convertir el pronóstico de 3 horas a 1 hora mediante interpolación
        _hourlyForecast = _convertToHourlyForecast(list);
        debugPrint(
            'Pronóstico por horas procesado: ${_hourlyForecast.length} horas');

        // Procesar pronóstico diario
        _processDailyForecast(list);
        debugPrint(
            'Pronóstico diario procesado: ${_dailyForecast.length} días');
      } else {
        throw Exception(
            'Error al obtener pronóstico por horas: ${hourlyForecastResponse.statusCode} - ${hourlyForecastResponse.body}');
      }
    } catch (e) {
      debugPrint('Error al obtener datos del clima: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Determinar si una hora específica está en día o noche
  bool isDaytime(DateTime time) {
    if (_sunrise == null || _sunset == null)
      return time.hour >= 6 && time.hour < 18;

    // Ajustar para el día actual
    final today = DateTime.now();
    final sunrise = DateTime(
        today.year, today.month, today.day, _sunrise!.hour, _sunrise!.minute);
    final sunset = DateTime(
        today.year, today.month, today.day, _sunset!.hour, _sunset!.minute);

    return time.isAfter(sunrise) && time.isBefore(sunset);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Solicitando permisos de ubicación...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Los permisos de ubicación están permanentemente denegados. Por favor, actívalos en la configuración del dispositivo.');
      }

      debugPrint('Obteniendo posición actual...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.low, // Precisión reducida para mayor velocidad
        timeLimit: const Duration(
            seconds: 5), // Límite de tiempo para obtener ubicación
      );
    } catch (e) {
      debugPrint('Error al determinar la posición: $e');
      rethrow;
    }
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

  // Método para convertir pronóstico de 3 horas a pronóstico por hora
  List<Map<String, dynamic>> _convertToHourlyForecast(
      List<dynamic> threeHourForecast) {
    List<Map<String, dynamic>> hourlyForecast = [];

    // Asegurarse de que tenemos al menos dos puntos para interpolar
    if (threeHourForecast.length < 2) {
      return List<Map<String, dynamic>>.from(threeHourForecast);
    }

    // Verificar si estamos obteniendo todos los datos correctamente
    print("Datos de 3 horas recibidos: ${threeHourForecast.length}");

    for (int i = 0; i < threeHourForecast.length - 1; i++) {
      final current = threeHourForecast[i];
      final next = threeHourForecast[i + 1];

      final DateTime currentTime = DateTime.parse(current['dt_txt']);
      final DateTime nextTime = DateTime.parse(next['dt_txt']);

      // Añadir el punto actual
      hourlyForecast.add(Map<String, dynamic>.from(current));

      // Calcular cuántas horas hay entre los dos puntos
      final int hours = nextTime.difference(currentTime).inHours;

      print(
          "Horas entre puntos: $hours (${currentTime.toString()} a ${nextTime.toString()})");

      if (hours > 1) {
        for (int hour = 1; hour < hours; hour++) {
          final DateTime interpolatedTime =
              currentTime.add(Duration(hours: hour));
          final double ratio = hour / hours;

          // Interpolar valores
          final Map<String, dynamic> interpolatedForecast = {
            'dt': current['dt'] + (hour * 3600),
            'dt_txt': interpolatedTime.toIso8601String(),
            'main': {
              'temp': _interpolate(
                  current['main']['temp'], next['main']['temp'], ratio),
              'temp_min': _interpolate(
                  current['main']['temp_min'], next['main']['temp_min'], ratio),
              'temp_max': _interpolate(
                  current['main']['temp_max'], next['main']['temp_max'], ratio),
              'humidity': _interpolate(current['main']['humidity'],
                      next['main']['humidity'], ratio)
                  .round(),
              'feels_like': _interpolate(current['main']['feels_like'],
                  next['main']['feels_like'], ratio),
            },
            'weather': [
              Map<String, dynamic>.from(current['weather'][0])
            ], // Usar el icono del tiempo actual
            'wind': {
              'speed': _interpolate(
                  current['wind']['speed'], next['wind']['speed'], ratio),
            }
          };

          hourlyForecast.add(interpolatedForecast);
        }
      }
    }

    // Ordenar por fecha
    hourlyForecast.sort((a, b) =>
        DateTime.parse(a['dt_txt']).compareTo(DateTime.parse(b['dt_txt'])));

    // Filtrar para asegurar que tenemos exactamente una entrada por hora
    final filteredHourlyForecast = <Map<String, dynamic>>[];
    DateTime? lastHour;

    for (var forecast in hourlyForecast) {
      final DateTime forecastTime = DateTime.parse(forecast['dt_txt']);
      final DateTime hourOnly = DateTime(forecastTime.year, forecastTime.month,
          forecastTime.day, forecastTime.hour);

      if (lastHour == null || hourOnly.difference(lastHour).inHours >= 1) {
        filteredHourlyForecast.add(forecast);
        lastHour = hourOnly;
      }
    }

    print(
        "Pronóstico por horas generado: ${filteredHourlyForecast.length} horas");

    // Limitar a 24 horas
    return filteredHourlyForecast.take(24).toList();
  }

  // Método auxiliar para interpolar valores
  double _interpolate(dynamic a, dynamic b, double ratio) {
    return (a as num).toDouble() +
        ((b as num).toDouble() - (a as num).toDouble()) * ratio;
  }
}
