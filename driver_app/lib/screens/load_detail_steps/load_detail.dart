import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../preferences_provider.dart';
import 'pickup_info.dart';
import 'trailer_photos.dart';
import 'homepage.dart'; // <-- Import your homepage
import 'delivery_info.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLoadDetails();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLoadDetails();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLoadDetails() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          'http://10.0.2.2:8000/api/driver/driver/get-load-detail/${widget.loadId}/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Load details fetched: $data");

        setState(() {
          _loadData = data;
          _loading = false;

          // Map stepper completion strictly based on status
final status = (data['status'] ?? '').toString().toLowerCase().replaceAll(' ', '_');

if (status == 'pending') {
  pickupCompleted = false;
  trailerCompleted = false;
  deliveryCompleted = false;
} else if (status == 'in_transit') {
  pickupCompleted = true;
  trailerCompleted = false;
  deliveryCompleted = false;
} else if (status == 'pickup_completed') {
  pickupCompleted = true;
  trailerCompleted = true;
  deliveryCompleted = false;
} else if (status == 'delivered') {
  pickupCompleted = true;
  trailerCompleted = true;
  deliveryCompleted = true;
} else {
  pickupCompleted = false;
  trailerCompleted = false;
  deliveryCompleted = false;
}

        });
      } else {
        print("Failed to fetch load: ${response.body}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error fetching load: $e");
      setState(() => _loading = false);
    }
  }

void _onStepTapped(String step) {
  if (step == "Pickup Info" && !pickupCompleted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupInfoScreen(
          driverId: widget.driverId,
          loadId: widget.loadId,
        ),
      ),
    ).then((_) => _fetchLoadDetails());
  } else if (step == "Trailer Upload" && !trailerCompleted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrailerPhotosScreen(
          driverId: widget.driverId,
          loadId: widget.loadId,
        ),
      ),
    ).then((_) => _fetchLoadDetails());
  } else if (step == "Delivery Info") {
    if (deliveryCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed!')),
      );
    } else {
      // ✅ Navigate to DeliveryInfoScreen instead of showing SnackBar
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


  Widget _buildStep(String label, bool completed) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false);
    return ListTile(
      onTap: () => _onStepTapped(label),
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
          ? const Text("Completed", style: TextStyle(color: Colors.green))
          : const Text("Pending", style: TextStyle(color: Colors.orange)),
    );
  }

  Widget _buildLoadDetails() {
    final theme = Provider.of<PreferencesProvider>(context, listen: false);
    if (_loadData == null) return const SizedBox();

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
                    'Load Number: ${_loadData!['load_number'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup Number: ${_loadData!['pickup_number'] ?? '-'}',
                    style: TextStyle(
                        color:
                            theme.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  Text(
                    'Customer: ${_loadData!['customer_name'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    'Status: ${_loadData!['status'] ?? '-'}',
                    style: TextStyle(
                      color: (_loadData!['status']?.toLowerCase() == 'delivered')
                          ? Colors.green
                          : (theme.isDarkMode
                              ? Colors.orangeAccent
                              : Colors.orange),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStep("Pickup Info", pickupCompleted),
                  _buildStep("Trailer Upload", trailerCompleted),
                  _buildStep("Delivery Info", deliveryCompleted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Load Details"),
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
                    'No load details found.',
                    style: TextStyle(
                        color: theme.isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : _buildLoadDetails(),
    );
  }
}
