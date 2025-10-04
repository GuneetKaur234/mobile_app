import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'load_detail_steps/homepage.dart';
import '../l10n/app_localizations.dart';
import 'preferences_provider.dart';

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
  final TextEditingController _scacController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDriverInfo();
  }

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
    final loc = AppLocalizations.of(context)!;
    final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
    final selectedLanguage = prefsProvider.languageCode;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final body = jsonEncode({
        "name": _nameController.text.trim(),
        "license_number": _licenseController.text.trim(),
        "company": _companyController.text.trim(),
        "phone": _phoneController.text.trim(),
        "scac_code": _scacController.text.trim().toUpperCase(),
        "language": selectedLanguage,
      });

      final response = await http
          .post(
            Uri.parse("${baseUrl}validate/"),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['access_granted'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_name', _nameController.text.trim());
        await prefs.setString('license_number', _licenseController.text.trim());
        await prefs.setString('company', _companyController.text.trim());
        await prefs.setString('phone', _phoneController.text.trim());
        await prefs.setString('scac_code', _scacController.text.trim().toUpperCase());
        await prefs.setString('driver_id', data['driver_id'].toString());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LatestLoadsScreen(driverId: int.parse(data['driver_id'].toString())),
          ),
        );
      } else {
        final errorMessage = data['error'] ?? loc.notApproved;
        _showError(errorMessage);
      }
    } on http.ClientException {
      _showError(loc.unableToConnect);
    } on TimeoutException {
      _showError(loc.connectionTimeout);
    } catch (e) {
      final errorMessage = loc.unexpectedError(e.toString());
      _showError(errorMessage);
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
    final loc = AppLocalizations.of(context)!;
    final prefsProvider = Provider.of<PreferencesProvider>(context);

    String safe(String? s, String fallback) => s ?? fallback;

    return Scaffold(
      backgroundColor: const Color(0xFF16213D),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            color: const Color(0xFF1F2F56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      safe(loc.letsGetYouSetUp, "Let's get you set up!"),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(Icons.person, safe(loc.name, "Name"), _nameController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.badge, safe(loc.licenseNumber, "License Number"), _licenseController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.business, safe(loc.company, "Company"), _companyController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.confirmation_num, safe(loc.scacCode, "SCAC Code"), _scacController, true),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.phone, safe(loc.phone, "Phone"), _phoneController, false),
                    const SizedBox(height: 20),

                    // Language Selector
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(loc.language, style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: prefsProvider.languageCode,
                      dropdownColor: const Color(0xFF1F2F56),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          prefsProvider.setLanguage(val);
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDriverInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF39C12),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                safe(loc.saveAndContinue, "Save & Continue"),
                                style: const TextStyle(fontSize: 18, color: Colors.white),
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
    final loc = AppLocalizations.of(context)!;

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
          ? (val) => val == null || val.isEmpty
              ? loc.cannotBeEmpty(label)
              : null
          : null,
    );
  }
}
