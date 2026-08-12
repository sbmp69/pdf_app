import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _appLockEnabled = false;
  bool _autoSaveGallery = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _autoSaveGallery = prefs.getBool('auto_save_gallery') ?? true;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    setState(() {
      _appLockEnabled = value;
    });
  }

  Future<void> _toggleAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_save_gallery', value);
    setState(() {
      _autoSaveGallery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'PREMIUM'),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Upgrade to ScanPro Premium'),
            subtitle: const Text('Unlock all features & remove ads'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('In-app purchases are coming in v2.0!')),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'GENERAL'),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Cloud Backup'),
            subtitle: const Text('Not connected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cloud Backup is a Premium feature coming in v2.0')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('App Lock'),
            trailing: Switch(
              value: _appLockEnabled,
              onChanged: _toggleAppLock,
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'SCANNER'),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Default Scan Quality'),
            subtitle: const Text('High'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quality is automatically optimized in this version.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Auto-save to Gallery'),
            trailing: Switch(
              value: _autoSaveGallery,
              onChanged: (value) {
                _toggleAutoSave(value);
                if (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auto-save to Gallery is a Premium feature coming in v2.0')),
                  );
                  Future.delayed(const Duration(milliseconds: 300), () => _toggleAutoSave(false));
                }
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'ABOUT'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support center is coming in v2.0!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
