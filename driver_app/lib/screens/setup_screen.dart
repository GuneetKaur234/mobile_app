import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ✅ Import homepage instead of pickup_info
import 'load_detail_steps/homepage.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _scacController = TextEditingController(); // ✅ SCAC controller

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String _selectedLanguage = 'en'; // default language

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadSavedDriverInfo(); // ✅ Prefill saved info if available
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  // ✅ Load previously saved driver info
  Future<void> _loadSavedDriverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('driver_name') ?? '';
      _licenseController.text = prefs.getString('license_number') ?? '';
      _companyController.text = prefs.getString('company') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _scacController.text = prefs.getString('scac_code') ?? '';
    });
  }

  Future<void> _saveDriverInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final body = jsonEncode({
        "name": _nameController.text.trim(),
        "license_number": _licenseController.text.trim(),
        "company": _companyController.text.trim(),
        "phone": _phoneController.text.trim(),
        "scac_code": _scacController.text.trim().toUpperCase(), // ✅ include SCAC
        "language": _selectedLanguage,
      });

      final response = await http
          .post(
            Uri.parse("http://10.0.2.2:8000/api/driver/driver/validate/"),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['access_granted'] == true) {
        // Save info locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_name', _nameController.text.trim());
        await prefs.setString('license_number', _licenseController.text.trim());
        await prefs.setString('company', _companyController.text.trim());
        await prefs.setString('phone', _phoneController.text.trim());
        await prefs.setString('scac_code', _scacController.text.trim().toUpperCase()); // ✅ store SCAC
        await prefs.setString('driver_id', data['driver_id'].toString());

        // ✅ Navigate to Homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LatestLoadsScreen(driverId: int.parse(data['driver_id'].toString())),
          ),
        );
      } else {
        final errorMessage =
            data['error'] ?? 'You are not approved. Please contact your company.';
        _showError(errorMessage);
      }
    } on http.ClientException catch (_) {
      _showError("Unable to connect to the server. Check your connection.");
    } on TimeoutException catch (_) {
      _showError(
          "Connection timed out. You are not approved or server is unreachable.");
    } catch (e) {
      _showError("Unexpected error: ${e.toString()}");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213D),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            color: const Color(0xFF1F2F56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(24),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Let's get you set up!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(Icons.person, 'Name', _nameController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.badge, 'License Number', _licenseController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.business, 'Company', _companyController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.confirmation_num, 'SCAC Code', _scacController, true), // ✅ SCAC
                    const SizedBox(height: 16),
                    _buildTextField(Icons.phone, 'Phone', _phoneController, false),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDriverInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF39C12),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save & Continue',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String label, TextEditingController controller, bool required) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF4BC0C0)),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? '$label cannot be empty' : null
          : null,
    );
  }
}
