import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

import '../theme/app_theme.dart';

/// Profile & Settings Screen — Stitch Refined Profile design
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!authState.isAuthenticated || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text('Not Logged In',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.goNamed('login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    final daysActive =
        DateTime.now().difference(user.createdAt).inDays.clamp(1, 99999);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final memberSince =
        '${months[user.createdAt.month - 1]} ${user.createdAt.year}';

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.backgroundDark.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(Icons.arrow_back,
                      color: isDark ? AppTheme.textPrimary : Colors.black87),
                ),
                const SizedBox(width: 12),
                Text(
                  'Security Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                ),
                IconButton(
                  onPressed: () => _showLogoutConfirmation(context, ref),
                  icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                ),
              ],
            ),
          ),

          // ── Main Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Profile Section ──
                  Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.5),
                                width: 4,
                              ),
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                            ),
                            child: ClipOval(
                              child: user.profileImageUrl != null
                                  ? Image.network(
                                      user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildInitialAvatar(user.username),
                                    )
                                  : _buildInitialAvatar(user.username),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.backgroundDark
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontFamily: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontFamily,
                          ),
                          children: [
                            const TextSpan(text: 'Security Level: '),
                            TextSpan(
                              text: user.clearanceLevel,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since $memberSince • ID: ${user.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buttons row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Sync Vault',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showEditProfileDialog(context, ref),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      AppTheme.primaryBlue.withOpacity(0.2),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Edit Details',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Stats Grid ──
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '2FA',
                          label: 'SECURITY',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: 'AES',
                          label: 'ENCRYPTION',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '${((daysActive / (daysActive + 5)) * 100).round()}%',
                          label: 'HEALTH',
                          isDark: isDark,
                          valueColor: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Security Settings ──
                  _SectionHeader(
                    icon: Icons.shield_outlined,
                    title: 'Security Settings',
                  ),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.fingerprint,
                        title: 'Biometric Unlock',
                        trailing: _ToggleSwitch(value: true),
                      ),
                      _SettingsItem(
                        icon: Icons.key_outlined,
                        title: 'Master Password',
                        trailing: Icon(Icons.chevron_right,
                            color: AppTheme.textMuted),
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.security_outlined,
                        title: 'Authenticator App',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ),
                      if (user.roles.contains('ADMIN') || user.roles.contains('ROLE_ADMIN'))
                        _SettingsItem(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Dashboard',
                          subtitle: 'Manage identities and system logs',
                          trailing: Icon(Icons.shield, color: AppTheme.warningOrange),
                          onTap: () => context.pushNamed('admin'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Privacy Controls ──
                  _SectionHeader(
                    icon: Icons.visibility_off_outlined,
                    title: 'Privacy Controls',
                  ),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.public_off_outlined,
                        title: 'Stealth Mode',
                        trailing: _ToggleSwitch(value: false),
                      ),
                      _SettingsItem(
                        icon: Icons.history,
                        title: 'Activity Logging',
                        trailing: Icon(Icons.chevron_right,
                            color: AppTheme.textMuted),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Device Management ──
                  _SectionHeader(
                    icon: Icons.devices_outlined,
                    title: 'Device Management',
                  ),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.smartphone,
                        title: 'Current Device',
                        subtitle: 'Active now',
                        trailing: const Text(
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80), // space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom nav
      bottomNavigationBar: _ProfileBottomNav(isDark: isDark),
    );
  }

  Widget _buildInitialAvatar(String username) {
    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          color: AppTheme.electricCyan,
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).currentUser;
    final nameController = TextEditingController(text: user?.username ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing coming soon')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
            "Are you sure you want to log out? You'll need to log in again to access your messages."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed('login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final Color? valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryBlue.withOpacity(isDark ? 0.1 : 0.05),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(isDark ? 0.3 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isDark ? AppTheme.textPrimary : AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Settings Group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0)
                Divider(
                  height: 1,
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                ),
              item,
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Settings Item ────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Toggle Switch ────────────────────────────────────────────────────────────

class _ToggleSwitch extends StatelessWidget {
  final bool value;

  const _ToggleSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: value ? AppTheme.successGreen : Colors.grey[350],
      ),
      child: AnimatedAlign(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────

class _ProfileBottomNav extends StatelessWidget {
  final bool isDark;

  const _ProfileBottomNav({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.lock_outline,
            label: 'Vault',
            selected: false,
            onTap: () => context.goNamed('chat_list'),
          ),
          _NavItem(
            icon: Icons.analytics_outlined,
            label: 'Activity',
            selected: false,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.health_and_safety_outlined,
            label: 'Health',
            selected: false,
            onTap: () => context.goNamed('security'),
          ),
          _NavItem(
            icon: Icons.settings,
            label: 'Settings',
            selected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
