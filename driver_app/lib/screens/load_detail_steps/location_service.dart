import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService with ChangeNotifier {
  // Singleton
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _tracking = false;
  bool get tracking => _tracking;

  Timer? _timer;

  String? _loadStatus; 
  int? _driverId; // driver ID for backend

  // Base URL and endpoint
  static const String baseUrl =
      'https://mobile-app-gpehf7f5c4h9cre6.canadacentral-01.azurewebsites.net/api/driver/driver/';

  // Set load status and start/stop tracking accordingly
  void setLoadStatus(String status, {int? driverId}) {
    _loadStatus = status.toLowerCase();
    if (driverId != null) _driverId = driverId;

    // Allowed statuses for tracking
    if (_loadStatus == "pending_pickup" ||
        _loadStatus == "in_transit" ||
        _loadStatus == "pickup_completed") {
      if (!_tracking) startTracking();
    } else if (_loadStatus == "delivered") {
      stopTracking();
    }
  }

  // Start periodic location tracking
  void startTracking() async {
    if (_tracking) return;
    if (!(_loadStatus == "pending_pickup" ||
        _loadStatus == "in_transit" ||
        _loadStatus == "pickup_completed")) {
      print("Tracking not allowed for status: $_loadStatus");
      return;
    }
    if (_driverId == null) {
      print("Driver ID not set. Cannot send location to backend.");
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    _tracking = true;

    // Send location immediately and then every 5 minutes
    _sendCurrentLocation();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_loadStatus == "delivered") {
        stopTracking();
      } else {
        _sendCurrentLocation();
      }
    });

    print("Tracking started.");
  }

  // Stop location tracking
  void stopTracking() {
    if (_tracking) {
      _tracking = false;
      _timer?.cancel();
      _timer = null;
      notifyListeners();
      print("Tracking stopped.");
    }
  }

  // Get current position and send to backend
  Future<void> _sendCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();

      if (_currentPosition != null && _driverId != null) {
        final url = Uri.parse('${baseUrl}update-location/');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'driver_id': _driverId,
            'latitude': _currentPosition!.latitude.toString(),
            'longitude': _currentPosition!.longitude.toString(),
          }),
        );

        if (response.statusCode == 200) {
          print("Location sent successfully: ${response.body}");
        } else {
          print("Failed to send location: ${response.body}");
        }
      }
    } catch (e) {
      print("Error fetching/sending location: $e");
    }
  }
}
