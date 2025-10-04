import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../preferences_provider.dart';
import 'my_profile.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final int driverId;

  const SettingsScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDarkMode = theme.isDarkMode;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(loc.settings),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(loc.account, isDarkMode),
          _buildSettingsTile(
            icon: Icons.person,
            title: loc.myProfile,
            subtitle: loc.viewUpdateDriverDetails,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyProfileScreen(driverId: driverId),
                ),
              );
            },
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle(loc.preferences, isDarkMode),
          _buildSettingsTile(
            icon: Icons.tune,
            title: loc.appPreferences,
            subtitle: loc.darkModeFontSize,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreferencesScreen(),
                ),
              );
            },
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle(loc.support, isDarkMode),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: loc.helpSupport,
            subtitle: loc.contactDispatcherHotlineFaq,
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle(loc.security, isDarkMode),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: loc.privacySecurity,
            subtitle: loc.managePermissions,
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle(loc.appInfo, isDarkMode),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: loc.aboutApp,
            subtitle: loc.versionCompanyContact,
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(loc.logout, style: const TextStyle(color: Colors.redAccent)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black54),
      title: Text(title,
          style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: isDarkMode ? Colors.white70 : Colors.black38),
      onTap: onTap,
    );
  }
}

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesProvider>(context);
    final isDarkMode = prefs.isDarkMode;
    final loc = AppLocalizations.of(context)!;

    // Supported languages
    final languages = {
      'en': 'English',
      'fr': 'Français',
    };

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(loc.appPreferences),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle
            SwitchListTile(
              title: Text(loc.darkMode,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
              value: prefs.isDarkMode,
              onChanged: (val) => prefs.toggleTheme(),
            ),
            const SizedBox(height: 20),

            // Font Size Slider
            Text("${loc.fontSize}: ${prefs.fontSize.toStringAsFixed(0)}",
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
            Slider(
              min: 12,
              max: 24,
              divisions: 6,
              value: prefs.fontSize,
              label: prefs.fontSize.toStringAsFixed(0),
              activeColor: isDarkMode ? Colors.blue[300] : Colors.blue,
              inactiveColor: isDarkMode ? Colors.white24 : Colors.black26,
              onChanged: (val) => prefs.setFontSize(val),
            ),
            const SizedBox(height: 20),

            // Language Dropdown
            Text(loc.selectLanguage,
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: prefs.languageCode,
              dropdownColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
              isExpanded: true,
              items: languages.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  prefs.setLanguage(val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
