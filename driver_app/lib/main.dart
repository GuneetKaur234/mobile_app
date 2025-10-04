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
import 'screens/load_detail_steps/my_profile.dart';

// Import your preferences provider
import 'screens/preferences_provider.dart';

// Import localization
import 'l10n/app_localizations.dart';

// 🌐 Base API URL for Azure
const String baseUrl =
    'https://mobile-app-gpehf7f5c4h9cre6.canadacentral-01.azurewebsites.net/api/driver/driver/';

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

          // 🔹 Localization setup
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: prefs.locale, // Use provider locale

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

// PreferencesScreen with language selector
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesProvider>(context);
    final isDarkMode = prefs.isDarkMode;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(loc.appPreferences),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle
            SwitchListTile(
              title: Text(loc.darkMode, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
              value: prefs.isDarkMode,
              onChanged: (val) => prefs.toggleTheme(),
            ),
            const SizedBox(height: 20),

            // Font Size Slider
            Text("${loc.fontSize}: ${prefs.fontSize.toStringAsFixed(0)}",
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
            Slider(
              min: 12,
              max: 24,
              divisions: 6,
              value: prefs.fontSize,
              label: prefs.fontSize.toStringAsFixed(0),
              activeColor: isDarkMode ? Colors.blue[300] : Colors.blue,
              inactiveColor: isDarkMode ? Colors.white24 : Colors.black26,
              onChanged: (val) => prefs.setFontSize(val),
            ),
            const SizedBox(height: 20),

            // Language Selector
            Text(loc.language, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: prefs.languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (val) {
                if (val != null) prefs.setLanguage(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
