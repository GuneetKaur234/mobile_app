import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'TripCompletedScreen.dart';
import 'package:provider/provider.dart';
import 'package:driver_app/screens/preferences_provider.dart';
import 'horizontal_stepper.dart'; // stepper widget

class DeliveryInfoScreen extends StatefulWidget {
  final int loadId;
  final int driverId;

  const DeliveryInfoScreen({Key? key, required this.loadId, required this.driverId})
      : super(key: key);

  @override
  _DeliveryInfoScreenState createState() => _DeliveryInfoScreenState();
}

class _DeliveryInfoScreenState extends State<DeliveryInfoScreen> {
  final TextEditingController _deliveryNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<File> _podNewFiles = [];
  List<Map<String, dynamic>> _podExistingFiles = [];
  List<int> _existingIds = [];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isSubmitting = false;

  int _currentStep = 2; // Delivery step index
  final List<String> _steps = ["Pickup Info", "Trailer Photos", "Delivery Info"];

  @override
  void initState() {
    super.initState();
    _fetchExistingDeliveryInfo();
  }

  Future<void> _fetchExistingDeliveryInfo() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
          "http://10.0.2.2:8000/api/driver/driver/get-delivery-info/${widget.loadId}/");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        setState(() {
          _deliveryNumberController.text = data["delivery_number"] ?? '';
          _notesController.text = data["notes"] ?? '';
          _podExistingFiles = (data["pod"] ?? [])
              .map<Map<String, dynamic>>((e) => {"id": e["id"], "url": e["url"]})
              .toList();
          _existingIds = _podExistingFiles.map((e) => e["id"] as int).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load delivery info")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _podNewFiles.addAll(pickedFiles.map((x) => File(x.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking images: $e")));
    }
  }

  InputDecoration _inputDecoration(String label, bool isDarkMode) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF16213D).withOpacity(0.3) : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildFilePicker(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("POD Files",
            style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.upload_file),
            label: Text(_podNewFiles.isEmpty && _podExistingFiles.isEmpty
                ? 'Upload'
                : 'Add More Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2980B9),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._podExistingFiles.asMap().entries.map((entry) {
          int index = entry.key;
          var file = entry.value;
          String fileName = file["url"].split('/').last;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(fileName,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black),
                      overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _existingIds.remove(file["id"]);
                    _podExistingFiles.removeAt(index);
                  });
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          );
        }),
        ..._podNewFiles.asMap().entries.map((entry) {
          int index = entry.key;
          File file = entry.value;
          String fileName = path.basename(file.path);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(fileName,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black),
                      overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _podNewFiles.removeAt(index);
                  });
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveDelivery() async {
    setState(() => _isSubmitting = true);
    final uri = Uri.parse("http://10.0.2.2:8000/api/driver/driver/save-delivery-info/");
    final request = http.MultipartRequest('POST', uri);

    request.fields['load_id'] = widget.loadId.toString();
    request.fields['driver_id'] = widget.driverId.toString();
    request.fields['delivery_number'] = _deliveryNumberController.text;
    request.fields['notes'] = _notesController.text;
    request.fields['pod_existing_ids'] = _existingIds.join(',');

    for (var file in _podNewFiles) {
      request.files.add(await http.MultipartFile.fromPath('pod_files', file.path));
    }

    try {
      final streamedResponse = await request.send();
      final responseStr = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery info saved successfully')),
        );
        setState(() => _podNewFiles.clear());
        await _fetchExistingDeliveryInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ${streamedResponse.statusCode}: $responseStr")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendDeliveryEmail() async {
    if (_deliveryNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Delivery Number")),
      );
      return;
    }

    if (_podNewFiles.isEmpty && _podExistingFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one POD file")),
      );
      return;
    }

    await _saveDelivery();

    setState(() => _isSubmitting = true);
    final uri = Uri.parse(
        "http://10.0.2.2:8000/api/driver/driver/send-delivery-email/${widget.loadId}/");

    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delivery email sent successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripCompletedScreen(driverId: widget.driverId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${response.statusCode}: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDarkMode = theme.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Delivery Info"),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
body: _isLoading
    ? Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      )
    : SafeArea(
        child: Column(
          children: [
            // Stepper always below AppBar
            HorizontalStepper(
              currentStep: _currentStep,
              steps: _steps,
            ),

            // Card area scrollable + centered horizontally
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Card(
                      color: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _deliveryNumberController,
                              style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black),
                              decoration: _inputDecoration("Delivery Number *", isDarkMode),
                            ),
                            const SizedBox(height: 16),
                            _buildFilePicker(isDarkMode),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black),
                              decoration: _inputDecoration("Notes", isDarkMode),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _saveDelivery,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF39C12),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Save',
                                            style: TextStyle(color: Colors.white, fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _sendDeliveryEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Send Email',
                                            style: TextStyle(color: Colors.white, fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),


    );
  }
}
