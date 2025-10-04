import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:driver_app/screens/load_detail_steps/load_detail.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'horizontal_stepper.dart';
import 'package:driver_app/screens/preferences_provider.dart';
import 'trailer_photos.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';



class PickupInfoScreen extends StatefulWidget {
  final int driverId;
  final int loadId;

  const PickupInfoScreen({
    Key? key,
    required this.driverId,
    required this.loadId,
  }) : super(key: key);

  @override
  _PickupInfoScreenState createState() => _PickupInfoScreenState();
}

class _PickupInfoScreenState extends State<PickupInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _truckNumberController = TextEditingController();
  final TextEditingController _trailerNumberController = TextEditingController();
  final TextEditingController _loadNumberController = TextEditingController();
  final TextEditingController _pickupNumberController = TextEditingController();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _reeferPreCoolController = TextEditingController();

  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;

  List<Map<String, dynamic>> _equipmentTypes = [];
  Map<String, dynamic>? _selectedEquipmentType;

  bool _loading = false;
  bool _customersLoading = true;
  bool _equipmentLoading = true;
  bool _isSaved = false;

  int? _savedLoadId;

  int _currentStep = 0;

  /// Steps initialized later when localization is available
  List<String> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializePickupInfo();
    _fetchEquipmentTypes();

    // Ensure localization is ready before accessing context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;
      setState(() {
        _steps = [
          loc.pickupInfo,
          loc.trailerUpload,
          loc.deliveryInfo,
        ];
      });
    });
  }

  Future<void> _initializePickupInfo() async {
    _savedLoadId = widget.loadId != 0 ? widget.loadId : null;
    await _fetchCustomers();
    if (_savedLoadId != null) {
      await _fetchLoadInfo(_savedLoadId!);
    }
    _updateStepFromBackend();
  }

  void _updateStepFromBackend() {
    setState(() {
      _currentStep = _isSaved ? 1 : 0;
    });
  }

  Future<void> _fetchCustomers() async {
    setState(() => _customersLoading = true);
    final url = Uri.parse('${baseUrl}get-customers/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"driver_id": widget.driverId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List customers = data['customers'] ?? [];
        _customers = customers.map<Map<String, dynamic>>((c) {
          if (c is String) return {"id": c, "name": c};
          return Map<String, dynamic>.from(c);
        }).toList();
      }
    } catch (e) {
      print("Error fetching customers: $e");
    } finally {
      setState(() => _customersLoading = false);
    }
  }

  Future<void> _fetchEquipmentTypes() async {
    setState(() => _equipmentLoading = true);
    final url = Uri.parse('${baseUrl}get-equipment-types/');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List types = data['equipment_types'] ?? [];
        setState(() {
          _equipmentTypes = types.map<Map<String, dynamic>>((e) {
            if (e is String) return {"id": e, "name": e};
            return Map<String, dynamic>.from(e);
          }).toList();
        });
      } else {
        print("Failed to fetch equipment types: ${response.body}");
      }
    } catch (e) {
      print("Error fetching equipment types: $e");
    } finally {
      setState(() => _equipmentLoading = false);
    }
  }

  Future<void> _fetchLoadInfo(int loadId) async {
    final url = Uri.parse('${baseUrl}get-truck-info/$loadId/');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 Backend load info: $data");
        
        setState(() {
          _truckNumberController.text = data['truck_number'] ?? '';
          _trailerNumberController.text = data['trailer_number'] ?? '';
          _loadNumberController.text = data['load_number'] ?? '';
          _pickupNumberController.text = data['pickup_number'] ?? '';
          _orderNumberController.text = data['order_number'] ?? '';
          _reeferPreCoolController.text = data['reefer_pre_cool'] ?? '';

          if (data['customer_name'] != null && _customers.isNotEmpty) {
            _selectedCustomer = _customers.firstWhere(
              (c) => (c['name'] ?? '').toLowerCase() == (data['customer_name'] ?? '').toLowerCase(),
              orElse: () => _customers[0],
            );
          }

          if (data['equipment_type'] != null && _equipmentTypes.isNotEmpty) {
            _selectedEquipmentType = _equipmentTypes.firstWhere(
              (e) => (e['id'] ?? '').toLowerCase() == (data['equipment_type'] ?? '').toLowerCase(),
              orElse: () => _equipmentTypes[0],
            );
          }

          _savedLoadId = data['load_id'];
          _isSaved = true;
        });
      } else {
        print("Failed to fetch load info: ${response.body}");
      }
    } catch (e) {
      print("Error fetching load info: $e");
    }
  }

  Future<bool> _saveTruckInfo({
    bool validateRequiredFields = false,
    String status = "pending_pickup",
    bool updateStatus = false,
  }) async {
    if (validateRequiredFields && !_formKey.currentState!.validate()) return false;

    if (_selectedCustomer == null && validateRequiredFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.customerRequired)),
      );
      return false;
    }

    if (_selectedEquipmentType == null && validateRequiredFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.equipmentTypeRequired)),
      );
      return false;
    }

    setState(() => _loading = true);

    final payload = {
      "driver_id": widget.driverId,
      if (_savedLoadId != null) "load_id": _savedLoadId,
      if (_truckNumberController.text.isNotEmpty) "truck_number": _truckNumberController.text.trim(),
      if (_trailerNumberController.text.isNotEmpty) "trailer_number": _trailerNumberController.text.trim(),
      if (_selectedCustomer != null) "customer_name": _selectedCustomer!['name'],
      if (_selectedCustomer != null) "customer_id": _selectedCustomer!['id'],
      if (_selectedEquipmentType != null) "equipment_type": _selectedEquipmentType!['id'],
      if (_loadNumberController.text.isNotEmpty) "load_number": _loadNumberController.text.trim(),
      if (_pickupNumberController.text.isNotEmpty) "pickup_number": _pickupNumberController.text.trim(),
      if (_orderNumberController.text.isNotEmpty) "order_number": _orderNumberController.text.trim(),
      if (_reeferPreCoolController.text.isNotEmpty) "reefer_pre_cool": _reeferPreCoolController.text.trim(),
      "status": status,
      "update_status": updateStatus,
      "force_new_load": false,
      "validate_required": validateRequiredFields,
    };

    final url = Uri.parse('${baseUrl}save-or-update-truck-info/');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        _savedLoadId = resData['load_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_load_id', _savedLoadId!);

        setState(() {
          _isSaved = true;
          if (validateRequiredFields) _currentStep = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validateRequiredFields
                ? AppLocalizations.of(context)!.pickupInfoSavedTransit
                : AppLocalizations.of(context)!.pickupInfoSaved),
          ),
        );
        return true;
      } else {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['error'] ?? AppLocalizations.of(context)!.failedToSave)),
        );
        return false;
      }
    }catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.networkError(e.toString())),
    ),
  );
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _truckNumberController.dispose();
    _trailerNumberController.dispose();
    _loadNumberController.dispose();
    _pickupNumberController.dispose();
    _orderNumberController.dispose();
    _reeferPreCoolController.dispose();
    super.dispose();
  }


Widget _buildTextField(TextEditingController controller, String label, {bool requiredField = true}) {
  final theme = Provider.of<PreferencesProvider>(context);
  
  return TextFormField(
    controller: controller,
    style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black),
    decoration: _inputDecoration(label, theme.isDarkMode),
    validator: requiredField
        ? (val) => val == null || val.isEmpty ? '$label is required' : null
        : null,
  );
}

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDark ? const Color(0xFF16213D).withOpacity(0.3) : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final loc = AppLocalizations.of(context)!;


    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(loc.pickupDetails),
        backgroundColor: theme.isDarkMode ? const Color(0xFF1F2F56) : const Color(0xFFF8FAFB),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HorizontalStepper(currentStep: _currentStep, steps: _steps),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Card(
                      color: theme.isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTextField(_truckNumberController, loc.truckNumber),
                              const SizedBox(height: 16),
                              _buildTextField(_trailerNumberController, loc.trailerNumber),
                              const SizedBox(height: 16),

                              _equipmentLoading
                                  ? const CircularProgressIndicator()
                                  : DropdownButtonFormField2<Map<String, dynamic>>(
                                      value: _selectedEquipmentType,
                                      isExpanded: true,
                                      decoration: _inputDecoration(loc.equipmentType, theme.isDarkMode),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 200,
                                        decoration: BoxDecoration(
                                          color: theme.isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        scrollbarTheme: ScrollbarThemeData(
                                          thumbColor: MaterialStateProperty.all(theme.isDarkMode ? Colors.white70 : Colors.black54),
                                          thickness: MaterialStateProperty.all(4),
                                          radius: const Radius.circular(4),
                                        ),
                                      ),
                                      items: _equipmentTypes.map((type) {
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: type,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              type['name'] ?? '',
                                              style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedEquipmentType = val),
                                      validator: (val) => val == null ? 'Equipment Type is required' : null,
                                      style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black),
                                    ),
                              const SizedBox(height: 16),

                              _customersLoading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: CircularProgressIndicator(
                                        color: theme.isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    )
                                  : DropdownButtonFormField2<Map<String, dynamic>>(
                                      value: _selectedCustomer,
                                      isExpanded: true,
                                      decoration: _inputDecoration(loc.customer, theme.isDarkMode).copyWith(
                                        prefixIcon: Icon(Icons.person, color: theme.isDarkMode ? Colors.white70 : Colors.black54),
                                      ),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 200,
                                        decoration: BoxDecoration(
                                          color: theme.isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        scrollbarTheme: ScrollbarThemeData(
                                          thumbColor: MaterialStateProperty.all(theme.isDarkMode ? Colors.white70 : Colors.black54),
                                          thickness: MaterialStateProperty.all(4),
                                          radius: const Radius.circular(4),
                                        ),
                                      ),
                                      items: _customers.map((customer) {
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: customer,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              customer['name'],
                                              style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedCustomer = val),
                                      validator: (val) => val == null ? 'Customer is required' : null,
                                      style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                                    ),

                              const SizedBox(height: 16),
                              _buildTextField(_loadNumberController, loc.loadNumber),
                              const SizedBox(height: 16),
                              _buildTextField(_pickupNumberController, loc.pickupNumber),
                              const SizedBox(height: 16),
                              _buildTextField(_orderNumberController, loc.orderNumber, requiredField: false),
                              const SizedBox(height: 16),

                              if (_selectedEquipmentType != null &&
                                  (_selectedEquipmentType!['name'] ?? '').toLowerCase().contains('reefer'))
                                Column(
                                  children: [
                                    _buildTextField(_reeferPreCoolController, loc.reeferPreCool),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : () async => await _saveTruckInfo(validateRequiredFields: false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF39C12),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(loc.save, style: const TextStyle(fontSize: 16, color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
Expanded(
  child: ElevatedButton(
    onPressed: _loading
        ? null
        : () async {
            final success = await _saveTruckInfo(
              validateRequiredFields: true,
              status: "in_transit",
              updateStatus: true,
            );

            if (success && _savedLoadId != null) {
              setState(() => _currentStep = 1);

              // Navigate without stopping tracking
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrailerPhotosScreen(
                    driverId: widget.driverId,
                    loadId: _savedLoadId!,
                    equipmentType: _selectedEquipmentType?['name'] ?? '',
                  ),
                ),
              );
            }
          },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
child: Text(
  loc.continueButton,
  style: const TextStyle(fontSize: 16, color: Colors.white),
),
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
            ),
          ],
        ),
      ),
    );
  }
}
