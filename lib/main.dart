import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Importación completa de material
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'providers/weather_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Simular carga de splash para asegurar que se muestra
      await Future.delayed(const Duration(seconds: 2));

      // Navegar a Home
      if (mounted && _error == null) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF78A7FF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo con efecto de brillo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: Image.asset(
                  'assets/images/logos/logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white10,
                      child: const Icon(
                        CupertinoIcons.cloud_sun_fill,
                        color: CupertinoColors.white,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Nombre de la aplicación con estilo
            const Text(
              'Caelum',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: CupertinoColors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            // Subtítulo
            const Text(
              'Tu pronóstico del tiempo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 30),
            // Indicador de carga o error
            if (_isLoading)
              const CupertinoActivityIndicator(
                color: CupertinoColors.white,
              ),
            if (_error != null)
              Column(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: CupertinoColors.systemYellow,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Error al iniciar la aplicación',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: CupertinoColors.white.withOpacity(0.3),
                    child: const Text('Reintentar'),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _initializeApp();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Restringir la orientación a solo vertical (portrait)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await dotenv.load(fileName: ".env");
    await initializeDateFormatting('es');
    runApp(const MyApp());
  } catch (e) {
    // Si hay errores durante la inicialización, mostrar una pantalla de error genérica
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF78A7FF),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error al iniciar Caelum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WeatherProvider(),
      child: const CupertinoApp(
        title: 'Caelum',
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.systemBlue,
            textStyle: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              letterSpacing: -0.41,
              color: CupertinoColors.label,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        home: SplashScreen(), // Usar el SplashScreen como pantalla inicial
      ),
    );
  }
}
