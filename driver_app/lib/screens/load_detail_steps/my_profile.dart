import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../preferences_provider.dart'; // ✅ import provider
import '../../main.dart';
import '../../l10n/app_localizations.dart'; // <-- import localization

class MyProfileScreen extends StatefulWidget {
  final int driverId;

  const MyProfileScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  bool _loading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverProfile();
  }

  Future<void> _fetchDriverProfile() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final url = Uri.parse("${baseUrl}get-profile/${widget.driverId}/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _licenseController.text = data['license_number'] ?? '';
          _companyController.text = data['company'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedFetchProfile)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.networkError(e.toString()))),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final payload = {
      "driver_id": widget.driverId,
      "name": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "license_number": _licenseController.text.trim(),
      "company": _companyController.text.trim(),
    };

    final url = Uri.parse("${baseUrl}update-profile/");
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.profileUpdated)),
        );
      } else {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['error'] ?? loc.failedFetchProfile)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.networkError(e.toString()))),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String label, bool isDarkMode) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDarkMode
          ? const Color(0xFF16213D).withOpacity(0.3)
          : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isDarkMode,
      {TextInputType keyboardType = TextInputType.text}) {
    final loc = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, isDarkMode),
      validator: (val) =>
          val == null || val.isEmpty ? loc.cannotBeEmpty(label) : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDarkMode = theme.isDarkMode;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(loc.myProfile),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Card(
                      color: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTextField(_nameController, loc.fullName, isDarkMode),
                              const SizedBox(height: 16),
                              _buildTextField(_phoneController, loc.phone, isDarkMode,
                                  keyboardType: TextInputType.phone),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _licenseController, loc.licenseNumber, isDarkMode),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _companyController, loc.company, isDarkMode),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        loc.saveProfile,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.white),
                                      ),
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
    );
  }
}
