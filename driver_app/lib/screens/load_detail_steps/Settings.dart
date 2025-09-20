import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../preferences_provider.dart'; // ✅ import provider
import 'my_profile.dart'; // your profile screen

class SettingsScreen extends StatelessWidget {
  final int driverId;

  const SettingsScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context);
    final isDarkMode = theme.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Account", isDarkMode),
          _buildSettingsTile(
            icon: Icons.person,
            title: "My Profile",
            subtitle: "View/update driver details",
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

          _buildSectionTitle("Preferences", isDarkMode),
          _buildSettingsTile(
            icon: Icons.tune,
            title: "App Preferences",
            subtitle: "Dark mode, font size",
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

          _buildSectionTitle("Support", isDarkMode),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "Contact dispatcher, hotline, FAQ",
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle("Security", isDarkMode),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: "Privacy & Security",
            subtitle: "Manage permissions",
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          _buildSectionTitle("App Info", isDarkMode),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: "About App",
            subtitle: "Version info, company contact",
            onTap: () {},
            isDarkMode: isDarkMode,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
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

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF16213D) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("App Preferences"),
        backgroundColor: isDarkMode ? const Color(0xFF1F2F56) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Dark Mode",
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
              value: prefs.isDarkMode,
              onChanged: (val) => prefs.toggleTheme(),
            ),
            const SizedBox(height: 20),
            Text("Font Size: ${prefs.fontSize.toStringAsFixed(0)}",
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
          ],
        ),
      ),
    );
  }
}
