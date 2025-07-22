// File: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Import Providers
import '../providers/theme_provider.dart';

// Import Screens it navigates to (ensure these files exist)
import 'screens/more/notification_settings_screen.dart'; // You created this
import 'screens/more/help_support_screen.dart';       // You created this

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...'; // State variable for app version

  @override
  void initState() {
    super.initState();
    _loadAppVersion(); // Load the version when the screen is initialized
  }

  // Function to asynchronously load the app version
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _appVersion = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Error loading version';
        });
      }
      debugPrint("Error getting package info: $e");
    }
  }

  // Helper function to launch URLs safely
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString'))
        );
      }
    }
  }

  // Navigation function for Notification Settings
  void _navigateToNotificationSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen(),),);
  }

  // Navigation function for Help & Support
  void _navigateToHelpAndSupport() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen(),),);
  }

  // Function to show the About Dialog
  void _showAppAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Occazio', // <-- Replace with your actual app name
      applicationVersion: _appVersion, // Use the loaded version
      // Replace with your actual app icon widget if you have one
      applicationIcon: const Icon(Icons.event, size: 50, color: Colors.blue),
      applicationLegalese: '© ${DateTime.now().year} Occazio Team', // Optional legal text
      children: [ // Optional additional info
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Your comprehensive event management solution.'),
        )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get/set theme mode
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context); // Get current theme data for styling

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'), // Title for the settings screen
      ),
      body: ListView( // Use ListView for scrollability
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Add some padding
        children: [
          // --- Appearance Section ---
          _buildSectionHeader(context, 'Appearance'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Theme'),
              subtitle: Text(themeProvider.currentThemeModeName), // Show current theme name
              trailing: PopupMenuButton<ThemeMode>(
                tooltip: "Select Theme", // Accessibility
                onSelected: (ThemeMode result) {
                  // Update theme using the provider (don't listen during call)
                  Provider.of<ThemeProvider>(context, listen: false).setThemeMode(result);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
                  const PopupMenuItem<ThemeMode>(value: ThemeMode.light, child: Text('Light')),
                  const PopupMenuItem<ThemeMode>(value: ThemeMode.dark, child: Text('Dark')),
                  const PopupMenuItem<ThemeMode>(value: ThemeMode.system, child: Text('System Default')),
                ],
                icon: const Icon(Icons.arrow_drop_down), // Dropdown indicator
              ),
            ),
          ),

          const SizedBox(height: 20), // Spacing between sections

          // --- Notifications Section (Moved from Profile) ---
          _buildSectionHeader(context, 'Notifications'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notification Settings'),
              subtitle: const Text('Manage push and email notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToNotificationSettings, // Navigate on tap
            ),
          ),

          const SizedBox(height: 20),

          // --- Language Section (Placeholder - Can be implemented later) ---
          _buildSectionHeader(context, 'Language & Region'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English (Placeholder)'), // Shows current language selection
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language settings coming soon!'))
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // --- Support & About Section (Moved from Profile) ---
          _buildSectionHeader(context, 'Support & About'),
          Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column( // Use Column as there are multiple items
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _navigateToHelpAndSupport, // Navigate on tap
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16), // Visual separator
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: Text('Version $_appVersion'), // Show loaded version
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAppAboutDialog, // Show the about dialog
                  ),
                ],
              )
          ),

          const SizedBox(height: 20),

          // --- Legal Section ---
          _buildSectionHeader(context, 'Legal'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column( // Use Column for multiple items
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.launch, size: 18, color: Colors.grey),
                  // Remember to replace with your actual URL
                  onTap: () => _launchUrl('https://www.example.com/privacy'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.launch, size: 18, color: Colors.grey),
                  // Remember to replace with your actual URL
                  onTap: () => _launchUrl('https://www.example.com/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Padding at the bottom
        ],
      ),
    );
  }

  // Helper widget for section headers for consistency
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary, // Use theme color for header
        ),
      ),
    );
  }
}