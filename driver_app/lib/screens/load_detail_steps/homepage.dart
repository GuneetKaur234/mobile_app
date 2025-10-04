import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../preferences_provider.dart';
import 'package:driver_app/screens/load_detail_steps/Settings.dart';
import 'load_detail.dart'; // <-- import the new LoadDetailScreen
import '../../main.dart';
import '../../l10n/app_localizations.dart';

class LatestLoadsScreen extends StatefulWidget {
  final int driverId;

  const LatestLoadsScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _LatestLoadsScreenState createState() => _LatestLoadsScreenState();
}

class _LatestLoadsScreenState extends State<LatestLoadsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _loads = [];

  @override
  void initState() {
    super.initState();
    _fetchLatestLoads();
  }

    String localizedStatus(AppLocalizations loc, String? status) {
    if (status == null || status.isEmpty) return '-';
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pickup_pending':
        return loc.pending;
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

  // Helper: Converts status string to Title Case
  String formatStatus(String? status) {
    if (status == null || status.isEmpty) return '-';
    return status
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Fetch the latest 10 loads for this driver
  Future<void> _fetchLatestLoads() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('${baseUrl}get-latest-loads/${widget.driverId}/');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('loads')) {
          final loadsList = data['loads'];
          setState(() {
            _loads = List<Map<String, dynamic>>.from(loadsList);
          });
        } else {
          setState(() => _loads = []);
        }
      } else {
        setState(() => _loads = []);
      }
    } catch (e) {
      print("Error fetching loads: $e");
      setState(() => _loads = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Create a new load via API and navigate to LoadDetailScreen
  Future<void> _createNewLoad() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('${baseUrl}create-new-load/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driver_id': widget.driverId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newLoadId = data['load_id'];
        final status = data['status'] ?? 'Pickup Pending';

        if (newLoadId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoadDetailScreen(
                driverId: widget.driverId,
                loadId: newLoadId,
                status: formatStatus(status), // <-- Title Case here
              ),
            ),
          );
        } else {
          print("Error: API did not return a load_id");
        }
      } else {
        print("Failed to create new load: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("Error creating new load: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.isDarkMode ? const Color(0xFF1F2F56) : const Color(0xFFF8FAFB),
        title: Row(
          children: [
            Image.asset(
              theme.isDarkMode
                  ? 'assets/images/FOH_logo_white.png'
                  : 'assets/images/FOH_logo_dark.png',
              height: 60,
            ),
            const SizedBox(width: 8),
            Text(
              loc.dashboard,
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(driverId: widget.driverId),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: theme.isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.isDarkMode ? Colors.white : Colors.black,
              ),
            )
          : _loads.isEmpty
              ? Center(
                  child: Text(
                    loc.noRecentLoads, 
                    style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLatestLoads,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _loads.length,
                    itemBuilder: (context, index) {
                      final load = _loads[index];
                      final formattedStatus = localizedStatus(loc, load['status']);// <-- format here
                      return Card(
                        color: theme.isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: Text(
                            '${loc.load}: ${load['load_number'] ?? '-'}',
                            style: TextStyle(
                              color: theme.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                 '${loc.customer}: ${load['customer_name'] ?? '-'}',
                                style: TextStyle(
                                  color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${loc.status}: $formattedStatus',
                                style: TextStyle(
                                  color: (load['status']?.toLowerCase() == 'delivered')
                                      ? Colors.green
                                      : (theme.isDarkMode ? Colors.orangeAccent : Colors.orange),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoadDetailScreen(
                                  driverId: widget.driverId,
                                  loadId: load['load_id'],
                                  status: formattedStatus, // <-- Title Case here too
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.isDarkMode ? Colors.orangeAccent : Colors.blue,
        child: const Icon(Icons.add, size: 32),
        onPressed: _createNewLoad,
      ),
    );
  }
}
