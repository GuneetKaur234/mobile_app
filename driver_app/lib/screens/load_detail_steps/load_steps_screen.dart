import 'package:flutter/material.dart';
import 'pickup_info.dart';
import 'trailer_photos.dart';
import 'delivery_info.dart';

class LoadStepsScreen extends StatefulWidget {
  final int driverId;

  const LoadStepsScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _LoadStepsScreenState createState() => _LoadStepsScreenState();
}

class _LoadStepsScreenState extends State<LoadStepsScreen> {
  int _currentStep = 0; // Track which step is active
  int? _loadId; // Will be set after Pickup Info is saved

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213D),
      appBar: AppBar(
        title: const Text("Load Steps"),
        backgroundColor: const Color(0xFF1F2F56),
      ),
      body: Column(
        children: [
          // Stepper Top Row
          _buildStepNavigator(),

          // Active Step Screen
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(),
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepNavigator() {
    final steps = ["Pickup Info", "Trailer Photos", "Delivery Info"];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          int index = entry.key;
          String title = entry.value;

          Color circleColor;
          Color textColor;

          if (_currentStep > index) {
            // Completed step
            circleColor = Colors.green;
            textColor = Colors.white;
          } else if (_currentStep == index) {
            // Current step
            circleColor = Colors.orange;
            textColor = Colors.white;
          } else {
            // Future step
            circleColor = Colors.grey;
            textColor = Colors.white70;
          }

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Step Circle
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: circleColor,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Draw line after each circle except the last one
                    if (index != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: (_currentStep > index)
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
    return PickupInfoScreen(
      driverId: widget.driverId,
      loadId: _loadId!,
    );
    } else if (_currentStep == 1) {
      return TrailerPhotosScreen(
        driverId: widget.driverId,
        loadId: _loadId!,
      );
    } else {
      return DeliveryInfoScreen(
        driverId: widget.driverId,
        loadId: _loadId!,
      );
    }
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Back"),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          if (_currentStep < 2)
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2980B9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Next"),
              ),
            ),
        ],
      ),
    );
  }
}
