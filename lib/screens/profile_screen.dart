import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check if we have additional user data in Firestore
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data() ?? {};
          });
        } else {
          // Create default user data if it doesn't exist
          final defaultData = {
            'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
            'email': user.email ?? 'No Email Provided',
            'phoneNumber': user.phoneNumber ?? '',
            'createdAt': DateTime.now().toIso8601String(),
            'lastLogin': DateTime.now().toIso8601String(),
          };

          await _firestore.collection('users').doc(user.uid).set(defaultData);
          setState(() {
            _userData = defaultData;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getUserDisplayName() {
    return _userData['displayName'] ??
           _auth.currentUser?.displayName ??
           _auth.currentUser?.email?.split('@')[0] ??
           'User';
  }

  String _getUserEmail() {
    return _auth.currentUser?.email ?? 'No Email Provided';
  }

  String _getUserPhotoUrl() {
    return _auth.currentUser?.photoURL ?? '';
  }

  String _getUserPhone() {
    return _userData['phoneNumber'] ?? _auth.currentUser?.phoneNumber ?? 'No Phone Number';
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showConfirmationDialog(context);
    if (confirm != true) return;

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _navigateToEditProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: _userData,
          onProfileUpdated: _loadUserData,
        ),
      ),
    );
  }

  void _navigateToSecurityScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecuritySettingsScreen(),
      ),
    );
  }

  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToHelpAndSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpSupportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String photoUrl = _getUserPhotoUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                          ? Text(
                              _getUserDisplayName().isNotEmpty
                                ? _getUserDisplayName()[0].toUpperCase()
                                : '?',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                            )
                          : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getUserDisplayName(),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserEmail(),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      if (_getUserPhone() != 'No Phone Number') ...[
                        const SizedBox(height: 4),
                        Text(
                          _getUserPhone(),
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // General Settings Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'General',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Edit Profile'),
                            subtitle: const Text('Change your name, phone number and other details'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToEditProfileScreen,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications),
                            title: const Text('Notification Settings'),
                            subtitle: const Text('Manage your notification preferences'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToNotificationSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Security Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Security',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.security),
                            title: const Text('Security Settings'),
                            subtitle: const Text('Change password, enable two-factor authentication'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToSecurityScreen,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy'),
                            subtitle: const Text('Manage data sharing and privacy settings'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to privacy settings
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Support Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            subtitle: const Text('Get help or contact support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToHelpAndSupport,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: const Text('About'),
                            subtitle: const Text('App version and information'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Your App Name',
                                applicationVersion: '1.0.0',
                                applicationIcon: const FlutterLogo(size: 50),
                                children: [
                                  const Text('A comprehensive profile management app'),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Logout Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  onPressed: () => _logout(context),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Future<bool?> showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phoneNumber'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update Firestore user document
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Update Firebase Auth display name (if using email/password auth)
        if (user.providerData.any((provider) =>
            provider.providerId == 'password')) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display profile picture (read-only since you don't have storage)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _auth.currentUser?.photoURL != null
                    ? NetworkImage(_auth.currentUser!.photoURL!)
                    : null,
                  child: _auth.currentUser?.photoURL == null
                    ? Text(
                        _nameController.text.isNotEmpty
                          ? _nameController.text[0].toUpperCase()
                          : '?',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Profile picture can\'t be changed',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+1 (123) 456-7890',
                ),
                keyboardType: TextInputType.phone,
                // Phone validation could be more complex in a real app
                validator: (value) {
                  // Basic validation, in a real app you'd want more robust validation
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.article),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Security Settings Screen
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPasswordProvider = false;

  @override
  void initState() {
    super.initState();
    _checkAuthProvider();
  }

  void _checkAuthProvider() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isPasswordProvider = user.providerData.any((provider) =>
            provider.providerId == 'password');
      });
    }
  }

  void _changePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (_isPasswordProvider) ...[
                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Login History'),
                    subtitle: const Text('View recent login activity'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // In a real app this would show login history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login history feature coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices),
                    title: const Text('Manage Devices'),
                    subtitle: const Text('View and manage logged in devices'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // In a real app this would manage devices
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Device management feature coming soon!')),
                      );
                    },
                  ),
                  if (_isPasswordProvider) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.security),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Require verification code when logging in'),
                      value: false, // This would be fetched from user settings
                      onChanged: (value) {
                        // In a real app this would enable/disable 2FA
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('2FA feature coming soon!')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account'),
                    subtitle: const Text('Permanently delete your account and all data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text(
                            'This action cannot be undone. All your data will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // In a real app this would delete the account
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account deletion feature coming soon')),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Change Password Bottom Sheet
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        // Re-authenticate user with current password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (mounted) {
        String errorMessage = 'Failed to update password';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              errorMessage = 'Current password is incorrect';
              break;
            case 'requires-recent-login':
              errorMessage = 'Please log out and log back in to change your password';
              break;
            default:
              errorMessage = 'Error: ${e.message}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords don\'t match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChangingPassword ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isChangingPassword
                    ? const CircularProgressIndicator()
                    : const Text('Update Password'),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, bool> _notificationSettings = {
    'app_updates': true,
    'security_alerts': true,
    'new_features': true,
    'marketing': false,
    'account_activity': true,
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            setState(() {
              // Update only keys that exist in the document
              data.forEach((key, value) {
                if (_notificationSettings.containsKey(key) && value is bool) {
                  _notificationSettings[key] = value;
                }
              });
            });
          }
        } else {
          // Create default notification settings
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('notifications')
              .set(_notificationSettings);
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notification settings: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update local state immediately for responsive UI
        setState(() {
          _notificationSettings[key] = value;
        });

        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .update({key: value});
      }
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
      // Revert local state if update fails
      setState(() {
        _notificationSettings[key] = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification setting: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Push Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Security Alerts'),
                          subtitle: const Text('Important security notifications about your account'),
                          value: _notificationSettings['security_alerts'] ?? true,
                          onChanged: (value) => _updateNotificationSetting('security_alerts', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Account Activity'),
                          subtitle: const Text('Get notified about important account activities'),
                          value: _notificationSettings['account_activity'] ?? true,
                          onChanged: (value) => _updateNotificationSetting('account_activity', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('App Updates'),
                          subtitle: const Text('Get notified when app updates are available'),
                          value: _notificationSettings['app_updates'] ?? true,
                          onChanged: (value) => _updateNotificationSetting('app_updates', value),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Email Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('New Features'),
                          subtitle: const Text('Receive emails about new features and improvements'),
                          value: _notificationSettings['new_features'] ?? true,
                          onChanged: (value) => _updateNotificationSetting('new_features', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Marketing'),
                          subtitle: const Text('Receive promotional emails and special offers'),
                          value: _notificationSettings['marketing'] ?? false,
                          onChanged: (value) => _updateNotificationSetting('marketing', value),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Notification Settings'),
                            content: const Text('This will reset all notification settings to default. Continue?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);

                                  final defaultSettings = {
                                    'app_updates': true,
                                    'security_alerts': true,
                                    'new_features': true,
                                    'marketing': false,
                                    'account_activity': true,
                                  };

                                  try {
                                    final user = _auth.currentUser;
                                    if (user != null) {
                                      await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('settings')
                                          .doc('notifications')
                                          .set(defaultSettings);

                                      setState(() {
                                        _notificationSettings = Map.from(defaultSettings);
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Notification settings reset to default')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to reset settings: ${e.toString()}')),
                                    );
                                  }
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Reset to Default'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // FAQs Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.question_answer),
                    title: Text('Frequently Asked Questions'),
                    subtitle: Text('Find answers to common questions'),
                  ),
                  const Divider(height: 1),

                  ExpansionTile(
                    title: const Text('How do I reset my password?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'To reset your password, go to the Security Settings screen and tap on "Change Password". You\'ll need to enter your current password for verification.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),

                  ExpansionTile(
                    title: const Text('How do I update my profile information?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'To update your profile information, go to the Profile screen and tap on "Edit Profile". From there, you can update your display name, phone number, and bio.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),

                  ExpansionTile(
                    title: const Text('Can I delete my account?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Yes, you can delete your account by going to Security Settings and tapping on "Delete Account". Please note that this action is permanent and all your data will be deleted.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Support Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.support_agent),
                    title: Text('Contact Support'),
                    subtitle: Text('Get help from our support team'),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email Support'),
                    subtitle: const Text('hypssprojectexhibition@gmail.com'),
                    onTap: () {
                      // In a real app, this would launch an email app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email feature coming soon!')),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Live Chat'),
                    subtitle: const Text('Chat with a support agent'),
                    onTap: () {
                      // In a real app, this would launch a chat feature
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Live chat feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Feedback Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.feedback),
                    title: Text('Send Feedback'),
                    subtitle: Text('Help us improve our app'),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Feedback',
                            hintText: 'Tell us what you think about our app...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thank you for your feedback!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Submit Feedback'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}