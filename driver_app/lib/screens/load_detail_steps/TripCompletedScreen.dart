import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'pickup_info.dart';
import 'package:provider/provider.dart';
import 'package:driver_app/screens/preferences_provider.dart';
import 'homepage.dart';

class TripCompletedScreen extends StatefulWidget {
  final int driverId;

  const TripCompletedScreen({Key? key, required this.driverId})
      : super(key: key);

  @override
  _TripCompletedScreenState createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => LatestLoadsScreen(driverId: widget.driverId)),
      (route) => false, // removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDarkMode = theme.isDarkMode;

    final backgroundColor = isDarkMode ? const Color(0xFF16213D) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1F2F56) : Colors.green;
    final titleColor = Colors.white;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.white70;
    final buttonColor = isDarkMode ? const Color(0xFF2980B9) : const Color(0xFF2980B9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
            createParticlePath: _drawStar,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 20,
            minBlastForce: 5,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: titleColor,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Trip Completed!",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Delivery info has been sent successfully 🎉",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32), // <- added spacing before button
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Go to Dashboard",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = 360 / 5;
    final rotation = -pi / 2;

    for (int i = 0; i <= 5; i++) {
      final angle = rotation + (i * degreesPerStep) * (pi / 180);
      final radius = i.isEven ? externalRadius : internalRadius;
      final x = halfWidth + radius * cos(angle);
      final y = halfWidth + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
