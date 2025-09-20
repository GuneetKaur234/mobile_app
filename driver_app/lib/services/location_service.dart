import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position>? _positionStream;
  Stream<Position> startTracking({int distanceFilter = 5}) {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter, // meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);
    return _positionStream!;
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void stopTracking() {
    // Streams will close automatically when the widget disposes,
    // but if needed, we can cancel subscription externally.
  }
}
