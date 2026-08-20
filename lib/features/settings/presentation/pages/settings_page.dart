import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _appLockEnabled = false;
  bool _autoSaveGallery = true;
  String _scanQuality = 'High';

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
      _scanQuality = prefs.getString('scan_quality') ?? 'High';
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
  
  Future<void> _setScanQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scan_quality', quality);
    setState(() {
      _scanQuality = quality;
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@scanpro.com',
      query: 'subject=ScanPro App Support Request',
    );
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client')));
      }
    }
  }

  Future<void> _launchStore() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.scanpro.app');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open app store')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildPremiumCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('GENERAL'),
          _buildCard([
            _buildListTile(
              icon: Icons.cloud_sync,
              iconColor: Colors.blue,
              title: 'Cloud Backup',
              subtitle: 'Not connected',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud Sync requires Pro account')),
                );
              },
            ),
            const Divider(height: 1, indent: 56),
            _buildSwitchTile(
              icon: Icons.security,
              iconColor: Colors.green,
              title: 'App Lock (Biometric)',
              subtitle: 'Require auth on open',
              value: _appLockEnabled,
              onChanged: _toggleAppLock,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('SCANNER'),
          _buildCard([
            _buildListTile(
              icon: Icons.document_scanner,
              iconColor: Colors.purple,
              title: 'Default Scan Quality',
              subtitle: _scanQuality,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Scan Quality'),
                    children: ['Low', 'Medium', 'High', 'Maximum'].map((e) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, e),
                      child: Text(e, style: const TextStyle(fontSize: 16)),
                    )).toList(),
                  )
                );
                if (result != null) _setScanQuality(result);
              },
            ),
            const Divider(height: 1, indent: 56),
            _buildSwitchTile(
              icon: Icons.image,
              iconColor: Colors.orange,
              title: 'Auto-save to Gallery',
              subtitle: 'Save scans as images',
              value: _autoSaveGallery,
              onChanged: _toggleAutoSave,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('ABOUT & SUPPORT'),
          _buildCard([
            _buildListTile(
              icon: Icons.mail_outline,
              iconColor: Colors.redAccent,
              title: 'Contact Support',
              subtitle: 'support@scanpro.com',
              trailing: const Icon(Icons.chevron_right),
              onTap: _launchEmail,
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.star_border,
              iconColor: Colors.amber,
              title: 'Rate Us',
              subtitle: 'Love the app? Let us know!',
              trailing: const Icon(Icons.chevron_right),
              onTap: _launchStore,
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: 'Version',
              trailing: const Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('In-app purchases are coming in v2.0!')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.diamond, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ScanPro Premium',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unlock all features & remove ads',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
      ),
    );
  }
}
