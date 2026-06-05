import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Section(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'App',
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Push Notifications'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme'),
                subtitle: const Text('Dark Mode', style: TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Social Connect'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.errorColor),
              label: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          color: AppTheme.surfaceDark,
          child: Column(children: children),
        ),
      ],
    );
  }
}
