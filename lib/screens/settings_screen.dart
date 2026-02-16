import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();

  // Settings toggles
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _muteChatSounds = true;
  bool _darkMode = true;
  bool _autoDownloadMedia = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                children: [
                  const SizedBox(height: 24),

                  // Account Settings
                  _buildSection(
                    '👤 ACCOUNT SETTINGS',
                    [
                      _buildMenuItem(
                        icon: '✏️',
                        title: 'Edit Profile',
                        subtitle: 'Update your information',
                        onTap: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                      ),
                      _buildMenuItem(
                        icon: '🔑',
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '📧',
                        title: 'Email Address',
                        subtitle: 'Manage your email',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '📱',
                        title: 'Phone Number',
                        subtitle: 'Verify your phone',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),

                  // Privacy & Security
                  _buildSection(
                    '🔒 PRIVACY & SECURITY',
                    [
                      _buildMenuItem(
                        icon: '🛡️',
                        title: 'Privacy Settings',
                        subtitle: 'Control who sees your info',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '🚫',
                        title: 'Blocked Users',
                        subtitle: 'Manage blocked accounts',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '🔐',
                        title: 'Two-Factor Authentication',
                        subtitle: 'Add extra security',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),

                  // Notifications
                  _buildSection(
                    '🔔 NOTIFICATIONS',
                    [
                      _buildToggleItem(
                        title: 'Push Notifications',
                        subtitle: 'Get notified about new answers',
                        value: _pushNotifications,
                        onChanged: (val) =>
                            setState(() => _pushNotifications = val),
                      ),
                      _buildToggleItem(
                        title: 'Email Notifications',
                        subtitle: 'Receive email updates',
                        value: _emailNotifications,
                        onChanged: (val) =>
                            setState(() => _emailNotifications = val),
                      ),
                      _buildToggleItem(
                        title: 'Mute Chat Sounds',
                        subtitle: 'Turn off chat notification sounds',
                        value: _muteChatSounds,
                        onChanged: (val) =>
                            setState(() => _muteChatSounds = val),
                      ),
                      _buildMenuItem(
                        icon: '⏰',
                        title: 'Quiet Hours',
                        subtitle: 'Mute notifications at night',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),

                  // Appearance
                  _buildSection(
                    '🎨 APPEARANCE',
                    [
                      _buildToggleItem(
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme everywhere',
                        value: _darkMode,
                        onChanged: (val) => setState(() => _darkMode = val),
                      ),
                      _buildMenuItem(
                        icon: '🌈',
                        title: 'Theme Color',
                        subtitle: 'Customize app colors',
                        badge: 'PRO',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '📏',
                        title: 'Text Size',
                        subtitle: 'Adjust font size',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),

                  // Data & Storage
                  _buildSection(
                    '💾 DATA & STORAGE',
                    [
                      _buildMenuItem(
                        icon: '📥',
                        title: 'Download My Data',
                        subtitle: 'Export your information',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '🗑️',
                        title: 'Clear Cache',
                        subtitle: 'Free up storage',
                        onTap: () => _clearCache(),
                      ),
                      _buildToggleItem(
                        title: 'Auto-download Media',
                        subtitle: 'Download images on WiFi only',
                        value: _autoDownloadMedia,
                        onChanged: (val) =>
                            setState(() => _autoDownloadMedia = val),
                      ),
                    ],
                  ),

                  // Help & Support
                  _buildSection(
                    '💬 HELP & SUPPORT',
                    [
                      _buildMenuItem(
                        icon: '📧',
                        title: 'Contact Support',
                        subtitle: 'Get help from our team',
                        onTap: () => _contactSupport(),
                      ),
                      _buildMenuItem(
                        icon: '📚',
                        title: 'Help Center',
                        subtitle: 'FAQs and guides',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '🐛',
                        title: 'Report a Bug',
                        subtitle: 'Help us improve',
                        onTap: () => _reportBug(),
                      ),
                      _buildMenuItem(
                        icon: '📜',
                        title: 'Privacy Policy',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: '📄',
                        title: 'Terms of Service',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),

                  // About
                  _buildSection(
                    '🌟 ABOUT',
                    [
                      _buildMenuItem(
                        icon: '⭐',
                        title: 'Rate Us',
                        subtitle: 'Share your feedback',
                        onTap: () => _rateApp(),
                      ),
                      _buildMenuItem(
                        icon: '📱',
                        title: 'Share AskSr',
                        subtitle: 'Invite your friends',
                        onTap: () => _shareApp(),
                      ),
                      _buildMenuItem(
                        icon: '🎓',
                        title: 'About AskSr',
                        subtitle: 'Learn more about us',
                        onTap: () => _showAbout(),
                      ),
                      _buildMenuItem(
                        icon: 'ℹ️',
                        title: 'App Version',
                        subtitle: '1.0.0 (Build 1)',
                      ),
                    ],
                  ),

                  // Account Actions (Danger Zone)
                  _buildSection(
                    '⚠️ ACCOUNT ACTIONS',
                    [
                      _buildMenuItem(
                        icon: '🚪',
                        title: 'Logout',
                        onTap: () => _logout(),
                      ),
                      _buildMenuItem(
                        icon: '🗑️',
                        title: 'Delete Account',
                        subtitle: 'Permanently remove your account',
                        isDanger: true,
                        onTap: () => _deleteAccount(),
                      ),
                    ],
                  ),

                  // Footer
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'AskSr © 2026',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF60a5fa),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    String? subtitle,
    String? badge,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDanger
                ? const Color(0xFFef4444).withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDanger
                    ? const Color(0xFFef4444).withOpacity(0.15)
                    : const Color(0xFF3b82f6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? const Color(0xFFef4444) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge or Arrow
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfbbf24), Color(0xFFf59e0b)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF3b82f6),
            inactiveThumbColor: Colors.white.withOpacity(0.5),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  // Action Methods

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming Soon! 🚀'),
        backgroundColor: const Color(0xFF3b82f6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will free up storage space. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email app...')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bug report form...')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening App Store...')),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied!')),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'About AskSr',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'AskSr connects juniors with verified seniors at their university for academic guidance, placement advice, and peer support.\n\nVersion 1.0.0',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Color(0xFFef4444)),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.\n\nAre you absolutely sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requires email verification'),
                  backgroundColor: Color(0xFFef4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
