import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../utils/weather_background.dart';
import '../providers/weather_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class CurrentWeather extends StatefulWidget {
  final Map<String, dynamic>? weather;
  final List<Map<String, dynamic>> hourlyForecast;

  const CurrentWeather({
    super.key,
    this.weather,
    required this.hourlyForecast,
  });

  @override
  State<CurrentWeather> createState() => _CurrentWeatherState();
}

class _CurrentWeatherState extends State<CurrentWeather> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  double _headerHeight = 210.0; // Aumentada de 180 a 210 para evitar overflow
  final double _minHeaderHeight = 80.0;

  @override
  void initState() {
    super.initState();
    // Añadir el listener después de que el widget esté completamente montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(_onScroll);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Verificar que el controlador esté adjunto antes de acceder al offset
    if (!_scrollController.hasClients) return;

    final double offset = _scrollController.offset;
    final double maxScrollAllowed = 110.0;
    final double scrollPercentage = (offset / maxScrollAllowed).clamp(0.0, 1.0);

    final double newHeight =
        _headerHeight - ((_headerHeight - _minHeaderHeight) * scrollPercentage);

    setState(() {
      _isCollapsed = scrollPercentage > 0.5;
      _headerHeight = newHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather == null) return const SizedBox.shrink();

    final timeOfDay = TimeOfDay.now();
    final weatherCondition = widget.weather!['weather'][0]['main'];
    final backgroundUrl =
        WeatherBackground.getBackgroundUrl(weatherCondition, timeOfDay);
    final textColor =
        WeatherBackground.getTextColor(weatherCondition, timeOfDay);
    final overlayDecoration =
        WeatherBackground.getOverlayDecoration(weatherCondition, timeOfDay);

    // Verificar si el scrollController está adjunto y obtener el offset,
    // de lo contrario usar 0.0
    final double currentOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    return Stack(
      children: [
        // Fondo
        Positioned.fill(
          child: Image.asset(
            backgroundUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Error cargando imagen: $error");
              return Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar la imagen: $error',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Overlay gradiente
        Positioned.fill(
          child: Container(
            decoration: overlayDecoration,
          ),
        ),
        // Contenido
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false, // Para evitar el padding inferior automático
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Añadir espacio superior para que no esté pegado arriba
                SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
                // Header animado que se fija
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    minHeight: _minHeaderHeight,
                    maxHeight:
                        210.0, // Aumentada para coincidir con _headerHeight
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: _headerHeight,
                      child:
                          _buildHeaderWithBlurEffect(textColor, currentOffset),
                    ),
                  ),
                  pinned: true,
                ),
                // Contenido principal
                SliverToBoxAdapter(
                  child: _buildContent(textColor, context),
                ),
                // Añadir espacio inferior para evitar overflow
                SliverToBoxAdapter(
                  child: SizedBox(height: 50),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.weather!['name'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            '${widget.weather!['main']['temp'].round()}°',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w200,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _minHeaderHeight,
          maxHeight: 210.0, // Asegurar que tenga suficiente espacio
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.weather!['name'],
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.weather!['main']['temp'].round()}°',
              style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w200,
                color: textColor,
              ),
            ),
            Text(
              widget.weather!['weather'][0]['description'].toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'H:${widget.weather!['main']['temp_max'].round()}° L:${widget.weather!['main']['temp_min'].round()}°',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainContent(textColor),
          _buildHourlyForecast(textColor, context),
          _buildDailyForecast(textColor),
        ],
      ),
    );
  }

  Widget _buildMainContent(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
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
                const SizedBox(height: 10), // Reducido aún más
                // Fila con información principal, asegura que no desborde
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 85), // Limitar altura
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Alineación superior
                    children: [
                      _buildWeatherInfo(
                        Icons.water_drop,
                        'HUMEDAD',
                        '${widget.weather!['main']['humidity']}%',
                        textColor,
                      ),
                      _buildWeatherInfo(
                        Icons.air,
                        'VIENTO',
                        '${widget.weather!['wind']['speed']} m/s',
                        textColor,
                      ),
                      _buildWeatherInfo(
                        Icons.thermostat,
                        'SENSACIÓN',
                        '${widget.weather!['main']['feels_like'].round()}°',
                        textColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(
      IconData icon, String label, String value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 22), // Aumentado de 20 a 22
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, // Aumentado de 10 a 11
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15, // Aumentado de 14 a 15
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(Color textColor, BuildContext context) {
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    final DateTime? sunrise = weatherProvider.sunrise;
    final DateTime? sunset = weatherProvider.sunset;

    // Generar elementos del pronóstico junto con amanecer y atardecer
    List<Widget> forecastItems = [];
    List<Map<String, dynamic>> forecastWithSunEvents = [];

    // Convertir amanecer y atardecer a elementos que se puedan intercalar
    DateTime now = DateTime.now();

    // Añadir los pronósticos regulares primero para tener los datos
    for (var forecast in widget.hourlyForecast) {
      final time = DateTime.parse(forecast['dt_txt']);
      forecastWithSunEvents.add({
        ...forecast,
        'time': time,
        'isSunrise': false,
        'isSunset': false,
      });
    }

    // Ordenar por hora los pronósticos
    forecastWithSunEvents.sort((a, b) => a['time'].compareTo(b['time']));

    // Ahora añadir amanecer y atardecer con temperaturas interpoladas
    if (sunrise != null) {
      final sunriseTime =
          DateTime(now.year, now.month, now.day, sunrise.hour, sunrise.minute);

      // Encontrar la temperatura interpolada para la hora del amanecer
      double sunriseTemp = 0.0;
      // Buscar pronósticos antes y después del amanecer para interpolar
      var beforeSunrise = forecastWithSunEvents
          .where((f) => f['time'].isBefore(sunriseTime))
          .toList();
      var afterSunrise = forecastWithSunEvents
          .where((f) => f['time'].isAfter(sunriseTime))
          .toList();

      if (beforeSunrise.isNotEmpty && afterSunrise.isNotEmpty) {
        // Interpolar entre los pronósticos más cercanos
        var before = beforeSunrise.last;
        var after = afterSunrise.first;
        var beforeTime = before['time'].millisecondsSinceEpoch;
        var afterTime = after['time'].millisecondsSinceEpoch;
        var sunriseTimeMs = sunriseTime.millisecondsSinceEpoch;

        // Calcular ratio para interpolación
        var ratio = (sunriseTimeMs - beforeTime) / (afterTime - beforeTime);
        sunriseTemp = before['main']['temp'] +
            (after['main']['temp'] - before['main']['temp']) * ratio;
      } else if (beforeSunrise.isNotEmpty) {
        // Si no hay datos después, usar el último disponible
        sunriseTemp = beforeSunrise.last['main']['temp'];
      } else if (afterSunrise.isNotEmpty) {
        // Si no hay datos antes, usar el primero disponible
        sunriseTemp = afterSunrise.first['main']['temp'];
      } else {
        // Si no hay datos, usar un valor predeterminado (promedio de todas las temperaturas)
        sunriseTemp = forecastWithSunEvents
                .map((f) => f['main']['temp'] as num)
                .reduce((a, b) => a + b) /
            forecastWithSunEvents.length;
      }

      forecastWithSunEvents.add({
        'dt_txt': sunriseTime.toIso8601String(),
        'isSunrise': true,
        'isSunset': false,
        'time': sunriseTime,
        'main': {
          'temp': sunriseTemp,
          'temp_min': sunriseTemp,
          'temp_max': sunriseTemp,
        },
      });
    }

    if (sunset != null) {
      final sunsetTime =
          DateTime(now.year, now.month, now.day, sunset.hour, sunset.minute);

      // Encontrar la temperatura interpolada para la hora del atardecer
      double sunsetTemp = 0.0;
      // Buscar pronósticos antes y después del atardecer para interpolar
      var beforeSunset = forecastWithSunEvents
          .where((f) => f['time'].isBefore(sunsetTime))
          .toList();
      var afterSunset = forecastWithSunEvents
          .where((f) => f['time'].isAfter(sunsetTime))
          .toList();

      if (beforeSunset.isNotEmpty && afterSunset.isNotEmpty) {
        // Interpolar entre los pronósticos más cercanos
        var before = beforeSunset.last;
        var after = afterSunset.first;
        var beforeTime = before['time'].millisecondsSinceEpoch;
        var afterTime = after['time'].millisecondsSinceEpoch;
        var sunsetTimeMs = sunsetTime.millisecondsSinceEpoch;

        // Calcular ratio para interpolación
        var ratio = (sunsetTimeMs - beforeTime) / (afterTime - beforeTime);
        sunsetTemp = before['main']['temp'] +
            (after['main']['temp'] - before['main']['temp']) * ratio;
      } else if (beforeSunset.isNotEmpty) {
        // Si no hay datos después, usar el último disponible
        sunsetTemp = beforeSunset.last['main']['temp'];
      } else if (afterSunset.isNotEmpty) {
        // Si no hay datos antes, usar el primero disponible
        sunsetTemp = afterSunset.first['main']['temp'];
      } else {
        // Si no hay datos, usar un valor predeterminado (promedio de todas las temperaturas)
        sunsetTemp = forecastWithSunEvents
                .map((f) => f['main']['temp'] as num)
                .reduce((a, b) => a + b) /
            forecastWithSunEvents.length;
      }

      forecastWithSunEvents.add({
        'dt_txt': sunsetTime.toIso8601String(),
        'isSunrise': false,
        'isSunset': true,
        'time': sunsetTime,
        'main': {
          'temp': sunsetTemp,
          'temp_min': sunsetTemp,
          'temp_max': sunsetTemp,
        },
      });
    }

    // Ordenar de nuevo para incluir amanecer y atardecer
    forecastWithSunEvents.sort((a, b) => a['time'].compareTo(b['time']));

    // Extraer temperaturas del pronóstico actualizado (incluyendo amanecer/atardecer)
    final List<double> temperatures = forecastWithSunEvents
        .map((forecast) => (forecast['main']['temp'] as num).toDouble())
        .toList();

    // Extraer temperaturas mínimas y máximas para el área sombreada
    final List<double> minTemps = forecastWithSunEvents
        .map((forecast) => (forecast['main']['temp_min'] as num).toDouble())
        .toList();

    final List<double> maxTemps = forecastWithSunEvents
        .map((forecast) => (forecast['main']['temp_max'] as num).toDouble())
        .toList();

    // Calcular el rango de temperaturas para el gráfico
    final double minTemp = minTemps.reduce((a, b) => a < b ? a : b);
    final double maxTemp = maxTemps.reduce((a, b) => a > b ? a : b);
    final double range = maxTemp - minTemp;

    // Añadir un margen al rango para que el gráfico no toque los bordes
    final double graphMinTemp = minTemp - (range * 0.1);
    final double graphMaxTemp = maxTemp + (range * 0.1);
    final double graphRange = graphMaxTemp - graphMinTemp;

    // Configuración de tamaño
    const double elementWidth = 60.0; // Ancho de cada elemento
    const double elementMargin = 8.0; // Margen horizontal de cada elemento
    const double totalElementWidth =
        elementWidth + (elementMargin * 2); // Ancho total incluyendo márgenes

    // Generar los widgets
    for (var item in forecastWithSunEvents) {
      if (item['isSunrise'] || item['isSunset']) {
        // Card de amanecer o atardecer
        forecastItems.add(
          Container(
            width: elementWidth,
            margin: EdgeInsets.symmetric(horizontal: elementMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hora
                Text(
                  DateFormat('HH:mm').format(item['time']),
                  style: TextStyle(
                    fontSize: 13, // Aumentado de 12 a 13
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Icono de amanecer o atardecer
                Icon(
                  item['isSunrise'] ? Icons.wb_sunny : Icons.nightlight_round,
                  color: item['isSunrise'] ? Colors.orange : Colors.deepOrange,
                  size: 34, // Aumentado de 32 a 34
                ),
                const SizedBox(height: 6),
                // Texto de amanecer o atardecer
                Text(
                  item['isSunrise'] ? 'Amanecer' : 'Atardecer',
                  style: TextStyle(
                    fontSize: 11, // Aumentado de 10 a 11
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                // Temperatura interpolada
                const SizedBox(height: 2),
                Text(
                  '${item['main']['temp'].round()}°',
                  style: TextStyle(
                    fontSize: 13, // Aumentado de 12 a 13
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Card normal de pronóstico
        final temp = item['main']['temp'].round();
        final weatherIcon = item['weather'][0]['icon'];

        forecastItems.add(
          Container(
            width: elementWidth,
            margin: EdgeInsets.symmetric(horizontal: elementMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hora
                Text(
                  DateFormat('HH:mm').format(item['time']),
                  style: TextStyle(
                    fontSize: 13, // Aumentado de 12 a 13
                    color: textColor,
                  ),
                ),
                // Icono del tiempo
                Image.network(
                  'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                  width: 34, // Aumentado de 32 a 34
                  height: 34, // Aumentado de 32 a 34
                  errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.wb_sunny,
                      color: textColor,
                      size: 34), // Aumentado de 32 a 34
                ),
                // Temperatura
                Text(
                  '$temp°',
                  style: TextStyle(
                    fontSize: 15, // Aumentado de 14 a 15
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Calcular el ancho total con el nuevo número de elementos
    final double totalContentWidth = forecastItems.length * totalElementWidth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // Título
                Text(
                  'PRONÓSTICO POR HORAS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                // Gráfico y pronóstico
                SizedBox(
                  height: 160,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalContentWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          children: [
                            // Gráfico de temperatura
                            Positioned.fill(
                              child: CustomPaint(
                                painter: XiaomiStyleGraphPainter(
                                  temperatures: temperatures,
                                  minTemps: minTemps,
                                  maxTemps: maxTemps,
                                  minTemp: graphMinTemp,
                                  maxTemp: graphMaxTemp,
                                  range: graphRange,
                                  color: textColor,
                                  itemWidth: totalElementWidth,
                                  elementCenterOffset: totalElementWidth / 2,
                                ),
                              ),
                            ),
                            // Pronóstico por horas
                            Row(
                              children: forecastItems,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyForecast(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRONÓSTICO DE 7 DÍAS',
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
                  padding: EdgeInsets.zero,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = DateTime.now().add(Duration(days: index));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Día de la semana con más espacio
                          SizedBox(
                            width: 80,
                            child: Text(
                              DateFormat('EEE', 'es').format(day).capitalize(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Espacio adicional
                          const SizedBox(width: 10),
                          // Icono del clima
                          Icon(
                            index % 3 == 0
                                ? Icons.wb_sunny
                                : index % 3 == 1
                                    ? Icons.cloud
                                    : Icons.water_drop,
                            color: textColor,
                            size: 22,
                          ),
                          // Espacio adicional
                          const SizedBox(width: 16),
                          // Temperatura y barra
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${(20 + index % 5).toString()}°',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Container(
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
                                ),
                                const SizedBox(width: 12),
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithBlurEffect(Color textColor, double scrollOffset) {
    // Calculamos la intensidad del blur basado en el scroll
    final double maxScrollForBlur = 60.0;
    final double blurIntensity =
        (scrollOffset / maxScrollForBlur).clamp(0.0, 1.0) * 10.0;
    final double opacityValue =
        (scrollOffset / maxScrollForBlur).clamp(0.0, 0.15);

    // Siempre usamos el efecto de blur, pero con intensidad 0 al inicio
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          color: textColor.withOpacity(opacityValue),
          child: _isCollapsed
              ? _buildCollapsedHeader(textColor)
              : _buildExpandedHeader(textColor),
        ),
      ),
    );
  }
}

// Extensión para capitalizar texto
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class XiaomiStyleGraphPainter extends CustomPainter {
  final List<double> temperatures;
  final List<double> minTemps;
  final List<double> maxTemps;
  final double minTemp;
  final double maxTemp;
  final double range;
  final Color color;
  final double itemWidth;
  final double elementCenterOffset;

  XiaomiStyleGraphPainter({
    required this.temperatures,
    required this.minTemps,
    required this.maxTemps,
    required this.minTemp,
    required this.maxTemp,
    required this.range,
    required this.color,
    required this.itemWidth,
    this.elementCenterOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;

    // Dibujar la línea de temperatura actual con curva suave
    final List<Offset> points = [];
    for (var i = 0; i < temperatures.length; i++) {
      final x = i * itemWidth + elementCenterOffset;
      final y = height - ((temperatures[i] - minTemp) / range * height);
      points.add(Offset(x, y));
    }

    final linePath = Path();
    final linePaint = Paint()
      ..color = color.withOpacity(0.5) // Opacidad de la línea
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length > 1) {
      linePath.moveTo(points.first.dx, points.first.dy);

      // Crear curva suave usando puntos de control
      for (var i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPointX = (current.dx + next.dx) / 2;

        linePath.cubicTo(controlPointX, current.dy, controlPointX, next.dy,
            next.dx, next.dy);
      }

      canvas.drawPath(linePath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
