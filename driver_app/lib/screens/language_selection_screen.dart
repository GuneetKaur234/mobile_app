import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  Future<void> _saveLanguageAndProceed() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage!);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213D),
      body: Center(
        child: Card(
          color: const Color(0xFF1F2F56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select your language",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  dropdownColor: const Color(0xFF1F2F56),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.language, color: Color(0xFF4BC0C0)),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'fr', child: Text('French', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedLanguage = val;
                    });
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select a language' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveLanguageAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4BC0C0),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}