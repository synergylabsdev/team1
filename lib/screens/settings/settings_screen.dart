import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Manage your profile information',
            onTap: () {
              // Already on profile tab, no action needed
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              // Navigate to change password
            },
          ),
          
          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            context,
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive event reminders and updates',
            value: true, // TODO: Get from preferences
            onChanged: (value) {
              // TODO: Save notification preference
            },
          ),
          _buildSwitchTile(
            context,
            icon: Icons.location_on,
            title: 'Location Services',
            subtitle: 'Allow location access for event discovery',
            value: true, // TODO: Get from preferences
            onChanged: (value) {
              // TODO: Request location permission
            },
          ),
          
          // Legal Section
          _buildSectionHeader('Legal'),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: 'Terms & Conditions',
            onTap: () {
              _showTermsAndConditions(context);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              // Show privacy policy
            },
          ),
          
          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              // Navigate to support
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'About',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          
          // Logout
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.errorColor),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'Terms and Conditions content goes here...\n\n'
            'By using SampleFinder, you agree to our terms and conditions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SampleFinder',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.explore, size: 48),
    );
  }
}

