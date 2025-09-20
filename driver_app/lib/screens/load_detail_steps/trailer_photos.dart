import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../preferences_provider.dart';
import 'horizontal_stepper.dart';
import 'delivery_info.dart';
import 'package:driver_app/screens/load_detail_steps/load_detail.dart';

class BackendFile {
  final int id;
  final String url;

  BackendFile({required this.id, required this.url});
}

class TrailerPhotosScreen extends StatefulWidget {
  final int loadId;
  final int driverId;
  final String? equipmentType;

  const TrailerPhotosScreen({
    Key? key,
    required this.loadId,
    required this.driverId,
    this.equipmentType,   // <-- add this
  }) : super(key: key);

  @override
  _TrailerPhotosScreenState createState() => _TrailerPhotosScreenState();
}

class _TrailerPhotosScreenState extends State<TrailerPhotosScreen> {
  int _currentStep = 1; // Step 2
  final List<String> _steps = ["Pickup Info", "Trailer Info", "Delivery Info"];

  String? _equipmentType;

  List<File> trailerNew = [];
  List<BackendFile> trailerExisting = [];
  List<File> pulpNew = [];
  List<BackendFile> pulpExisting = [];
  List<File> reeferNew = [];
  List<BackendFile> reeferExisting = [];
  List<File> loadSecureNew = [];
  List<BackendFile> loadSecureExisting = [];
  List<File> sealedTrailerNew = [];
  List<BackendFile> sealedTrailerExisting = [];
  List<File> bolNew = [];
  List<BackendFile> bolExisting = [];

  final TextEditingController _reeferTempShipperController = TextEditingController();
  final TextEditingController _reeferTempBolController = TextEditingController();
  String _reeferTempUnit = "C";
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sealNumberController = TextEditingController();
  final TextEditingController _pulpReasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isSaved = false;
  bool _pulpYes = true;

  Map<String, List<int>> _existingIds = {
    'trailer_picture': [],
    'pulp_picture': [],
    'reefer_picture': [],
    'load_secure_picture': [],
    'sealed_trailer_picture': [],
    'bol_picture': [],
  };

@override
void initState() {
  super.initState();
  _equipmentType = widget.equipmentType?.trim().toLowerCase();
  _initializeData();
}

Future<void> _initializeData() async {
  if (_equipmentType == null) {
    final eqType = await _fetchEquipmentType();
    setState(() {
      _equipmentType = eqType?.trim().toLowerCase();
    });
  }
  await _fetchExistingFiles();
}

  @override
  void dispose() {
    _notesController.dispose();
    _sealNumberController.dispose();
    _pulpReasonController.dispose();
    _reeferTempShipperController.dispose();
    _reeferTempBolController.dispose();
    super.dispose();
  }

Future<void> _fetchExistingFiles() async {
  try {
    final uri = Uri.parse(
        "http://10.0.2.2:8000/api/driver/driver/get-uploads/${widget.loadId}/");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body));

      setState(() {
        // ----------------------------
        // Always visible files
        // ----------------------------
        trailerExisting = (data['trailer'] as List? ?? [])
            .map((e) => BackendFile(id: e['id'], url: e['url']))
            .toList();

        loadSecureExisting = (data['load_secure'] as List? ?? [])
            .map((e) => BackendFile(id: e['id'], url: e['url']))
            .toList();

        sealedTrailerExisting = (data['sealed_trailer'] as List? ?? [])
            .map((e) => BackendFile(id: e['id'], url: e['url']))
            .toList();

        bolExisting = (data['bol'] as List? ?? [])
            .map((e) => BackendFile(id: e['id'], url: e['url']))
            .toList();

        _notesController.text = data['pickup_notes'] ?? '';
        _sealNumberController.text = data['seal_number'] ?? '';

        // ----------------------------
        // Reefer-specific files
        // ----------------------------
        if (_equipmentType == "reefer") {
          pulpExisting = (data['pulp'] as List? ?? [])
              .map((e) => BackendFile(id: e['id'], url: e['url']))
              .toList();

          reeferExisting = (data['reefer'] as List? ?? [])
              .map((e) => BackendFile(id: e['id'], url: e['url']))
              .toList();

          _reeferTempShipperController.text = data['reefer_temp_shipper'] ?? '';
          _reeferTempBolController.text = data['reefer_temp_bol'] ?? '';
          _reeferTempUnit = data['reefer_temp_unit'] ?? 'C';

                    // ✅ Initialize pulp radio and reason from backend
          if ((data['pulp_reason'] ?? '').isNotEmpty) {
            _pulpYes = false;
            _pulpReasonController.text = data['pulp_reason'];
          } else {
            _pulpYes = true;
            _pulpReasonController.text = '';
          }

          
        }

        _isSaved = true;

        // ----------------------------
        // Store existing IDs
        // ----------------------------
        _existingIds['trailer_picture'] =
            trailerExisting.map((e) => e.id).toList();
        _existingIds['load_secure_picture'] =
            loadSecureExisting.map((e) => e.id).toList();
        _existingIds['sealed_trailer_picture'] =
            sealedTrailerExisting.map((e) => e.id).toList();
        _existingIds['bol_picture'] = bolExisting.map((e) => e.id).toList();

        if (_equipmentType == "reefer") {
          _existingIds['pulp_picture'] = pulpExisting.map((e) => e.id).toList();
          _existingIds['reefer_picture'] = reeferExisting.map((e) => e.id).toList();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load existing files")));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading files: $e")));
  }
}

  Future<void> _pickImages(String type) async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          final files = pickedFiles
              .map((x) => File(x.path))
              .where((file) {
                List<String> existingPaths = [];
                switch (type) {
                  case 'trailer_picture':
                    existingPaths = trailerNew.map((f) => f.path).toList()
                      ..addAll(trailerExisting.map((f) => f.url));
                    break;
                  case 'pulp_picture':
                    existingPaths = pulpNew.map((f) => f.path).toList()
                      ..addAll(pulpExisting.map((f) => f.url));
                    break;
                  case 'reefer_picture':
                    existingPaths = reeferNew.map((f) => f.path).toList()
                      ..addAll(reeferExisting.map((f) => f.url));
                    break;
                  case 'load_secure_picture':
                    existingPaths = loadSecureNew.map((f) => f.path).toList()
                      ..addAll(loadSecureExisting.map((f) => f.url));
                    break;
                  case 'sealed_trailer_picture':
                    existingPaths = sealedTrailerNew.map((f) => f.path).toList()
                      ..addAll(sealedTrailerExisting.map((f) => f.url));
                    break;
                  case 'bol_picture':
                    existingPaths = bolNew.map((f) => f.path).toList()
                      ..addAll(bolExisting.map((f) => f.url));
                    break;
                }
                return !existingPaths.contains(file.path);
              }).toList();

          switch (type) {
            case 'trailer_picture':
              trailerNew.addAll(files);
              break;
            case 'pulp_picture':
              pulpNew.addAll(files);
              break;
            case 'reefer_picture':
              reeferNew.addAll(files);
              break;
            case 'load_secure_picture':
              loadSecureNew.addAll(files);
              break;
            case 'sealed_trailer_picture':
              sealedTrailerNew.addAll(files);
              break;
            case 'bol_picture':
              bolNew.addAll(files);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')));
    }
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF16213D).withOpacity(0.3)
          : const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildFilePicker(
      String label, List<File> newFiles, List<BackendFile> existingFiles, String type, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _pickImages(type),
            icon: const Icon(Icons.upload_file),
            label: Text(newFiles.isEmpty && existingFiles.isEmpty
                ? 'Upload'
                : 'Add More Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2980B9),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...existingFiles.asMap().entries.map((entry) {
          int index = entry.key;
          BackendFile file = entry.value;
          String fileName = file.url.split('/').last;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(fileName,
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54),
                      overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _existingIds[type]!.remove(file.id);
                    existingFiles.removeAt(index);
                  });
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          );
        }),
        ...newFiles.asMap().entries.map((entry) {
          int index = entry.key;
          File file = entry.value;
          String fileName = path.basename(file.path);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(fileName,
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54),
                      overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    newFiles.removeAt(index);
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

  Future<bool> _saveStep3({bool continueAfterSave = false}) async {
    setState(() => _loading = true);

    final uri = Uri.parse(_isSaved
        ? "http://10.0.2.2:8000/api/driver/driver/update-upload/${widget.loadId}/"
        : "http://10.0.2.2:8000/api/driver/driver/save-upload/");

    final request = http.MultipartRequest('POST', uri);

    request.fields['load_id'] = widget.loadId.toString();
    request.fields['driver_id'] = widget.driverId.toString();
    request.fields['pickup_notes'] = _notesController.text;
    request.fields['seal_number'] = _sealNumberController.text;
    request.fields['reefer_temp_shipper'] = _reeferTempShipperController.text.trim();
    request.fields['reefer_temp_bol'] = _reeferTempBolController.text.trim();
    request.fields['reefer_temp_unit'] = _reeferTempUnit;

    final Map<String, List<File>> newFileMap = {
      'trailer_picture': trailerNew,
      'reefer_picture': reeferNew,
      'load_secure_picture': loadSecureNew,
      'sealed_trailer_picture': sealedTrailerNew,
      'bol_picture': bolNew,
    };

    if (_pulpYes) newFileMap['pulp_picture'] = pulpNew;

    for (var entry in newFileMap.entries) {
      for (var file in entry.value) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, file.path));
      }
    }

    _existingIds.forEach((key, ids) {
      if (key == 'pulp_picture' && !_pulpYes) return;
      request.fields['${key}_existing_ids'] = ids.join(',');
    });

    if (!_pulpYes) request.fields['pulp_reason'] = _pulpReasonController.text.trim();

    try {
      final streamedResponse = await request.send();
      final responseStr = await streamedResponse.stream.bytesToString();
      print("🔍 Response from backend: $responseStr");

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        setState(() => _isSaved = true);
        if (continueAfterSave) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DeliveryInfoScreen(loadId: widget.loadId, driverId: widget.driverId)),
          );
        }
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ${streamedResponse.statusCode}: $responseStr")));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Network error: $e")));
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

bool _validateBeforeEmail() {
  final missing = <String>[];

  // Always required
  if (trailerNew.isEmpty && trailerExisting.isEmpty) missing.add("Trailer Picture");
  if (loadSecureNew.isEmpty && loadSecureExisting.isEmpty) missing.add("Load Secure Picture");
  if (sealedTrailerNew.isEmpty && sealedTrailerExisting.isEmpty) missing.add("Sealed Trailer Picture");
  if (bolNew.isEmpty && bolExisting.isEmpty) missing.add("BOL");
  if (_sealNumberController.text.trim().isEmpty) missing.add("Seal Number");

  // Only validate Reefer-related fields if equipment type is Reefer
  if (_equipmentType == "reefer") {
    if (_pulpYes) {
      if (pulpNew.isEmpty && pulpExisting.isEmpty) missing.add("Pulp Picture");
    } else {
      if (_pulpReasonController.text.trim().isEmpty) missing.add("Pulp Reason");
    }

    if (reeferNew.isEmpty && reeferExisting.isEmpty) missing.add("Reefer Picture");

    if (_reeferTempShipperController.text.isEmpty || _reeferTempBolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Reefer temperatures")),
      );
      return false;
    }
  }

  // Show missing fields if any
  if (missing.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please provide: ${missing.join(', ')}")),
    );
    return false;
  }

  return true;
}

  Future<void> _sendPickupEmail() async {
    if (!_validateBeforeEmail()) return;

    setState(() => _loading = true);

    final saveSuccess = await _saveStep3(continueAfterSave: false);

    if (!saveSuccess) {
      setState(() => _loading = false);
      return;
    }

    final uri = Uri.parse(
        "http://10.0.2.2:8000/api/driver/driver/send-pickup-email/${widget.loadId}/");

    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pickup email sent successfully!")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DeliveryInfoScreen(loadId: widget.loadId, driverId: widget.driverId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ${response.statusCode}: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

Future<String?> _fetchEquipmentType() async {
  try {
    final uri = Uri.parse(
        "http://10.0.2.2:8000/api/driver/driver/get-load-detail/${widget.loadId}/");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['equipment_type']?.toString(); // <- ensure string
    }
  } catch (e) {
    print("Error fetching equipment type: $e");
  }
  return null;
}


  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF16213D) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Picture Upload'),
        backgroundColor: isDark ? const Color(0xFF1F2F56) : const Color(0xFFFDFDFD),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoadDetailScreen(
                  driverId: widget.driverId,
                  loadId: widget.loadId,
                  status: '',
                ),
              ),
            );
          },
        ),
      ),
body: SafeArea(
  child: Column(
    children: [
      HorizontalStepper(currentStep: _currentStep, steps: _steps),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Card(
              color: isDark
                  ? const Color(0xFF1F2F56)
                  : Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilePicker("Trailer Picture", trailerNew,
                        trailerExisting, "trailer_picture", isDark),

                    // ----------------------------
                    // Reefer-only fields
                    // ----------------------------
                    if (_equipmentType == "reefer") ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pulp",
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: Text("Yes",
                                      style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black)),
                                  value: true,
                                  groupValue: _pulpYes,
                                  onChanged: (val) {
                                    setState(() {
                                      _pulpYes = val!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: Text("No",
                                      style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black)),
                                  value: false,
                                  groupValue: _pulpYes,
                                  onChanged: (val) {
                                    setState(() {
                                      _pulpYes = val!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_pulpYes)
                            _buildFilePicker("Pulp Picture", pulpNew,
                                pulpExisting, "pulp_picture", isDark)
                          else
                            TextFormField(
                              controller: _pulpReasonController,
                              maxLines: 2,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                              decoration:
                                  _inputDecoration("If not, Why?", isDark),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      _buildFilePicker("Reefer Picture", reeferNew,
                          reeferExisting, "reefer_picture", isDark),
                       ],
                       const SizedBox(height: 16),

                      _buildFilePicker("Load Secure Picture", loadSecureNew,
                        loadSecureExisting, "load_secure_picture", isDark),
                    _buildFilePicker(
                        "Sealed Trailer Picture",
                        sealedTrailerNew,
                        sealedTrailerExisting,
                        "sealed_trailer_picture",
                        isDark),
                    _buildFilePicker("BOL", bolNew, bolExisting,
                        "bol_picture", isDark),
                    const SizedBox(height: 16),

                    if (_equipmentType == "reefer") ...[
                      TextFormField(
                        controller: _reeferTempShipperController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        decoration: _inputDecoration(
                            "Reefer Temp (Set by Shipper)", isDark),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reeferTempBolController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        decoration:
                            _inputDecoration("Reefer Temp on BOL", isDark),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _reeferTempUnit,
                        dropdownColor:
                            isDark ? const Color(0xFF1F2F56) : Colors.white,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        items: const [
                          DropdownMenuItem(value: "C", child: Text("°C")),
                          DropdownMenuItem(value: "F", child: Text("°F")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _reeferTempUnit = val);
                        },
                        decoration: _inputDecoration("Temperature Unit", isDark),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ----------------------------
                    // Always visible fields
                    // ----------------------------

                    TextFormField(
                      controller: _sealNumberController,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration("Seal Number", isDark),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration("Pickup Notes", isDark),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _saveStep3(continueAfterSave: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF39C12),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Save',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaved && !_loading ? _sendPickupEmail : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Send Pickup email',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
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
    ],
  ),
),

    );
  }
}
