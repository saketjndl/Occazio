import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching email/URLs

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Helper function to launch URLs (e.g., for email)
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
      if(context.mounted) { // Check mount status before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString'))
        );
      }
    }
  }

  // Helper for mailto links
  void _launchEmail(BuildContext context, String email) {
    _launchUrl(context, 'mailto:$email?subject=App Support Request');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView( // Use ListView for easy scrolling of sections
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        children: [
          // --- FAQs Section ---
          _buildSectionHeader(context, 'Frequently Asked Questions'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.lock_reset_outlined), // Icon for relevance
                  title: const Text('How do I reset my password?'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You can reset your password from the Security Settings screen, accessible via your profile. You will need access to your registered email address.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ExpansionTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('How do I update my profile?'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap the "Edit Profile" option on your Profile screen to update your display name, phone number, or bio.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ExpansionTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('How do I change notification preferences?'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Go to App Settings (usually accessible via the profile or a dedicated settings icon) and select "Notification Settings" to manage your preferences.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                // Add more relevant FAQs here
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Contact Support Section ---
          _buildSectionHeader(context, 'Contact Us'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Support'),
                  subtitle: const Text('Get help via email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchEmail(context, 'hypssprojectexhibition@gmail.com'), // <-- REPLACE with your support email
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Live Chat (Coming Soon)'),
                  subtitle: const Text('Chat directly with our support team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Live Chat feature is coming soon!'))
                    );
                  }, // Disabled for now
                ),
                // Add phone support if applicable
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Optional: Send Feedback Section ---
          _buildSectionHeader(context, 'Send Feedback'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Help us improve! Share your thoughts or report an issue.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Enter your feedback here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    // Add a controller if you need to process the text
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Submit Feedback'),
                      onPressed: () {
                        // TODO: Implement feedback submission logic (e.g., send to Firestore, email, etc.)
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you for your feedback! (Submission not implemented yet)'))
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }

  // Helper widget for section headers
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
}