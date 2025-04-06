import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/current_weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<WeatherProvider>(context, listen: false)
        .fetchWeatherData());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (weatherProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${weatherProvider.error}',
                    style:
                        const TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () => weatherProvider.fetchWeatherData(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => weatherProvider.fetchWeatherData(),
              ),
              SliverFillRemaining(
                child: CurrentWeather(
                  weather: weatherProvider.currentWeather,
                  hourlyForecast: weatherProvider.hourlyForecast,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
