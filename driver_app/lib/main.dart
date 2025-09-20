import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your screens
import 'screens/welcome_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/load_detail_steps/pickup_info.dart';
import 'screens/load_detail_steps/trailer_photos.dart';
import 'screens/load_detail_steps/delivery_info.dart';
import 'screens/load_detail_steps/homepage.dart';

// Import your preferences provider
import 'screens/preferences_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PreferencesProvider(),
      child: const DriverApp(),
    ),
  );
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, prefs, child) {
        return MaterialApp(
          title: 'Driver App',
          debugShowCheckedModeBanner: false,
          themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // 🌞 LIGHT THEME
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: prefs.fontSize / 16.0,
                  bodyColor: Colors.black,
                  displayColor: Colors.black,
                ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFE0E0E0),
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),

          // 🌙 DARK THEME
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF16213d),
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: prefs.fontSize / 16.0,
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F2F56),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3460),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          home: const InitialScreen(),
        );
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isFirstTime = true;
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _checkDriverInfo();
  }

  Future<void> _checkDriverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final driverName = prefs.getString('driver_name');
    final driverIdStr = prefs.getString('driver_id');

    setState(() {
      _isFirstTime = driverName == null || driverIdStr == null;
      _driverId = driverIdStr != null ? int.tryParse(driverIdStr) : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // First-time user → Welcome
    if (_isFirstTime || _driverId == null) {
      return const WelcomeScreen();
    }

    // Otherwise → Latest Loads home
    return LatestLoadsScreen(driverId: _driverId!);
  }
}
