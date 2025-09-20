import 'package:flutter/material.dart';
import 'language_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for logo + text
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();

    // Slide animation for Start button
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();

  // Bounce animation for Welcome text (only once)
  _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600), // quick but visible
  );

  _bounceAnimation = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 50), // pop
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50), // settle
  ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

  _bounceController.forward(); // plays only once

  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213D),
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _bounceAnimation,
                    child: const Text(
                      'Welcome!!',
                      style: TextStyle(
                        fontSize: 52, // bigger text
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4BC0C0), // match Start button
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Image.asset(
                    'assets/images/FOH_logo_white.png',
                    width: 350, // bigger logo
                  ),
                ],
              ),
            ),
          ),
          // Start button at bottom-right
          Positioned(
            bottom: 40,
            right: 20,
            child: SlideTransition(
              position: _slideAnimation,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4BC0C0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
