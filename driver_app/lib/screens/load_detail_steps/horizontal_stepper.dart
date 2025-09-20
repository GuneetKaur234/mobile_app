import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_app/screens/preferences_provider.dart';

class HorizontalStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const HorizontalStepper({
    Key? key,
    required this.currentStep,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final bool isDark = theme.isDarkMode;

    // Step colors
    final Color activeColor = Colors.orange;
    final Color completedColor = Colors.green;
    final Color inactiveColor = isDark ? Colors.white54 : Colors.grey;

    // Background color of stepper
    final Color bgColor = isDark ? const Color(0xFF16213D) : const Color(0xFFF0F2F5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: steps.asMap().entries.map((entry) {
          int idx = entry.key;

          Color circleColor;
          if (currentStep > idx) {
            circleColor = completedColor;
          } else if (currentStep == idx) {
            circleColor = activeColor;
          } else {
            circleColor = inactiveColor;
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: circleColor,
                child: Text(
                  "${idx + 1}",
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (idx != steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  color: (currentStep > idx) ? completedColor : inactiveColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
