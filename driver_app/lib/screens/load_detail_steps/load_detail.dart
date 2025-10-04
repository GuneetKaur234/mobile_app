import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../preferences_provider.dart';
import 'pickup_info.dart';
import 'trailer_photos.dart';
import 'homepage.dart'; // <-- Import your homepage
import 'delivery_info.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';


class LoadDetailScreen extends StatefulWidget {
  final int driverId;
  final int loadId;
  final String status;

  const LoadDetailScreen({
    Key? key,
    required this.driverId,
    required this.loadId,
    required this.status,
  }) : super(key: key);

  @override
  _LoadDetailScreenState createState() => _LoadDetailScreenState();
}

class _LoadDetailScreenState extends State<LoadDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _loadData;

  bool pickupCompleted = false;
  bool trailerCompleted = false;
  bool deliveryCompleted = false;

  Timer? _pollingTimer;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _fetchLoadDetails();
    if (widget.status.toLowerCase() != 'delivered') {
      _startLocationUpdates();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  /// -------------------
  /// Load Details
  /// -------------------
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLoadDetails();
    });
  }

  Future<void> _fetchLoadDetails() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('${baseUrl}get-load-detail/${widget.loadId}/');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Load details fetched: $data");

        setState(() {
          _loadData = data;
          _loading = false;

          final status = (data['status'] ?? '')
              .toString()
              .toLowerCase()
              .replaceAll(' ', '_');

          pickupCompleted = status == 'in_transit' ||
              status == 'pickup_completed' ||
              status == 'delivered';
          trailerCompleted = status == 'pickup_completed' || status == 'delivered';
          deliveryCompleted = status == 'delivered';
        });

        print("Raw status from API: ${data['status']}");

      } else {
        print("Failed to fetch load: ${response.body}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error fetching load: $e");
      setState(() => _loading = false);
    }
  }

  void _onStepTapped(String step, AppLocalizations loc) {
    if (step == loc.pickupInfo && !pickupCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PickupInfoScreen(
            driverId: widget.driverId,
            loadId: widget.loadId,
          ),
        ),
      ).then((_) => _fetchLoadDetails());
    } else if (step == loc.trailerUpload && !trailerCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrailerPhotosScreen(
            driverId: widget.driverId,
            loadId: widget.loadId,
          ),
        ),
      ).then((_) => _fetchLoadDetails());
    } else if (step == loc.deliveryInfo) {
      if (deliveryCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.deliveryCompletedSnack)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryInfoScreen(
              driverId: widget.driverId,
              loadId: widget.loadId,
            ),
          ),
        ).then((_) => _fetchLoadDetails());
      }
    }
  }

  Widget _buildStep(String label, bool completed, AppLocalizations loc) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false);

    return ListTile(
      onTap: () => _onStepTapped(label, loc),
      leading: Icon(
        completed ? Icons.check_circle : Icons.access_time,
        color: completed ? Colors.green : Colors.orange,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: completed
          ? Text(loc.completed, style: TextStyle(color: Colors.green))
          : Text(loc.pending, style: TextStyle(color: Colors.orange)),
    );
  }

String _localizedStatus(AppLocalizations loc, String status) {
  final key = status.toLowerCase().replaceAll(' ', '_');

  switch (key) {
    case 'pickup_pending':
      return loc.pending; // maps to ARB "pending"
    case 'in_transit':
      return loc.status_in_transit;
    case 'pickup_completed':
      return loc.status_pickup_completed;
    case 'delivered':
      return loc.status_delivered;
    default:
      return status; // fallback
  }
}

  Widget _buildLoadDetails(AppLocalizations loc) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false);
    if (_loadData == null) return const SizedBox();

    print("Localized status: ${_localizedStatus(loc, _loadData!['status'] ?? '-')}");

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            color: theme.isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.loadNumber}: ${_loadData!['load_number'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${loc.pickupNumber}: ${_loadData!['pickup_number'] ?? '-'}',
                    style: TextStyle(
                        color:
                            theme.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  Text(
                    '${loc.customer}: ${_loadData!['customer_name'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${loc.status}: ${_localizedStatus(loc, _loadData!['status'] ?? '-')}',
                    style: TextStyle(
                      color: (_loadData!['status']?.toLowerCase() == 'delivered')
                          ? Colors.green
                          : (theme.isDarkMode ? Colors.orangeAccent : Colors.orange),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),
                    _buildStep(loc.pickupInfo, pickupCompleted, loc),
                    _buildStep(loc.trailerUpload, trailerCompleted, loc),
                    _buildStep(loc.deliveryInfo, deliveryCompleted, loc),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// -------------------
  /// Location Service
  /// -------------------
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  void _startLocationUpdates() async {
    bool permissionGranted = await _checkLocationPermission();
    if (permissionGranted) {
      _sendCurrentLocation(); // send immediately
    }

    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_loadData != null &&
          (_loadData!['status']?.toLowerCase() == 'delivered')) {
        timer.cancel();
        print("Load delivered: stopping location updates");
        return;
      }
      if (permissionGranted) {
        _sendCurrentLocation();
      }
    });
  }

  Future<void> _sendCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final url = Uri.parse('${baseUrl}update-location/');
      final body = jsonEncode({
        'driver_id': widget.driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        print("Location sent successfully: $body");
      } else {
        print("Failed to send location: ${response.body}");
      }
    } catch (e) {
      print("Error sending location: $e");
    }
  }

  /// -------------------
  /// Build
  /// -------------------
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.loadDetails),
        backgroundColor:
            theme.isDarkMode ? const Color(0xFF1F2F56) : const Color(0xFFF8FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LatestLoadsScreen(driverId: widget.driverId),
              ),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      backgroundColor:
          theme.isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.isDarkMode ? Colors.white : Colors.black,
              ),
            )
          : _loadData == null
              ? Center(
                  child: Text(
                    loc.noLoadDetails,
                    style: TextStyle(
                        color: theme.isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : _buildLoadDetails(loc),
    );
  }
}
