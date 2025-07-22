import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  // Define the structure and default values for notification settings
  Map<String, bool> _notificationSettings = {
    'app_updates': true,      // e.g., Push notification for new app versions
    'security_alerts': true,  // e.g., Push notification for important security events
    'new_features': true,     // e.g., Email about new app features
    'marketing': false,       // e.g., Email for promotions
    'account_activity': true, // e.g., Push notification for logins, etc.
    'event_reminders': true,  // e.g., Push notification for upcoming events
    // Add more keys as needed
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings(); // Load settings when the screen loads
  }

  // Get the reference to the user's notification settings document
  DocumentReference<Map<String, dynamic>>? _getSettingsDocRef() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')          // Collection of users
          .doc(user.uid)                // Document for the current user
          .collection('settings')       // Subcollection for user settings
          .doc('notifications');      // Specific document for notification settings
    }
    return null;
  }


  // Load settings from Firestore
  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    final docRef = _getSettingsDocRef();

    if (docRef == null) {
      // Handle case where user is somehow null (shouldn't happen if screen is protected)
      setState(() => _isLoading = false);
      _showErrorSnackBar("User not found. Cannot load settings.");
      return;
    }

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          // Important: Merge Firestore data with defaults to handle new settings
          final Map<String, bool> fetchedSettings = {};
          _notificationSettings.forEach((key, defaultValue) {
            // Use value from Firestore if it exists and is a bool, otherwise use default
            fetchedSettings[key] = (data.containsKey(key) && data[key] is bool)
                ? data[key]
                : defaultValue;
          });
          setState(() {
            _notificationSettings = fetchedSettings;
          });
        }
        // If data is null or empty, defaults are already set
      } else {
        // Document doesn't exist, create it with default values
        await docRef.set(_notificationSettings);
        // Keep the default values already set in the state map
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load notification settings: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Update a specific setting in Firestore and local state
  Future<void> _updateNotificationSetting(String key, bool value) async {
    final docRef = _getSettingsDocRef();
    if (docRef == null) {
      _showErrorSnackBar("User not found. Cannot update settings.");
      return;
    }

    // Update local state immediately for responsive UI
    final previousValue = _notificationSettings[key];
    setState(() {
      _notificationSettings[key] = value;
    });

    // Attempt to update in Firestore
    try {
      await docRef.set({key: value}, SetOptions(merge: true)); // Use set with merge to create/update
    } catch (e) {
      debugPrint('Error updating notification setting ($key): $e');
      // Revert local state if Firestore update fails
      setState(() {
        _notificationSettings[key] = previousValue ?? !_notificationSettings[key]!; // Revert to previous or opposite
      });
      if (mounted) {
        _showErrorSnackBar('Failed to update setting "$key": ${e.toString()}');
      }
    }
  }

  // Helper to show error messages
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [ // Optional: Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadNotificationSettings,
            tooltip: 'Refresh Settings',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching
          : ListView( // Use ListView for multiple settings
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        children: [
          // --- Example Section: General App Notifications ---
          _buildSectionHeader(context, 'App & Account'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSwitchTile(
                    key: 'app_updates',
                    title: 'App Updates',
                    subtitle: 'Get notified when app updates are available'
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSwitchTile(
                    key: 'security_alerts',
                    title: 'Security Alerts',
                    subtitle: 'Important security notifications for your account'
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSwitchTile(
                    key: 'account_activity',
                    title: 'Account Activity',
                    subtitle: 'Notifications about logins or important changes'
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Example Section: Content & Events ---
          _buildSectionHeader(context, 'Content & Events'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSwitchTile(
                    key: 'event_reminders',
                    title: 'Event Reminders',
                    subtitle: 'Reminders for events you are attending or managing'
                ),
                // Add more event-related toggles if needed
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Example Section: Promotions & Features ---
          _buildSectionHeader(context, 'Promotions & Features'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSwitchTile(
                    key: 'new_features',
                    title: 'New Features & Tips',
                    subtitle: 'Receive emails/notifications about new features'
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSwitchTile(
                    key: 'marketing',
                    title: 'Promotions & Offers',
                    subtitle: 'Receive promotional emails and special offers'
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper Widget for Section Headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0, top: 8.0, right: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Helper Widget to build consistent SwitchListTiles
  Widget _buildSwitchTile({
    required String key,
    required String title,
    required String subtitle,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: _notificationSettings[key] ?? false, // Provide default if key somehow missing
      onChanged: (value) {
        _updateNotificationSetting(key, value); // Call update function on change
      },
      activeColor: Theme.of(context).colorScheme.primary, // Use theme color
    );
  }
}