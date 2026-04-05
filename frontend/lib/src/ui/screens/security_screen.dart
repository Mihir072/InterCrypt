// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// SecurityScreen — Stitch Key Verification + Login History design
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context, isDark),

          // ── Tab bar ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.electricCyan,
              indicatorWeight: 2,
              labelColor: AppTheme.electricCyan,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              tabs: const [
                Tab(text: 'KEYS'),
                Tab(text: 'HISTORY'),
                Tab(text: 'SETTINGS'),
              ],
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KeyVerificationTab(isDark: isDark),
                _LoginHistoryTab(isDark: isDark),
                _SecuritySettingsTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withOpacity(0.8)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('chat_list');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? AppTheme.textPrimary : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Center',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                Text(
                  'ENCRYPTION & VERIFICATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.electricCyan.withOpacity(0.8),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.successGreen.withOpacity(0.1),
              border: Border.all(
                color: AppTheme.successGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(width: 4),
                const Text(
                  'SECURE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.successGreen,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1: Key Verification (matches Stitch Key Verification screen)
// ══════════════════════════════════════════════════════════════════════════════

class _KeyVerificationTab extends StatelessWidget {
  final bool isDark;
  const _KeyVerificationTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── QR-style verification section ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              color: isDark
                  ? AppTheme.primaryBlue.withOpacity(0.08)
                  : Colors.grey[50],
            ),
            child: Column(
              children: [
                // Shield identity icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue,
                    border: Border.all(
                      color: AppTheme.electricCyan.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: AppTheme.electricCyan,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verify Identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DIGITAL KEY EXCHANGE PROTOCOL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code placeholder
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // QR grid pattern
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: 100,
                        itemBuilder: (_, i) {
                          final filled = (i % 3 == 0 || i % 7 == 0 || i < 15 || i > 85);
                          return Container(
                            decoration: BoxDecoration(
                              color: filled
                                  ? Colors.black87
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        },
                      ),
                      // Center logo
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan to exchange keys',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Fingerprint display ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              color: isDark
                  ? AppTheme.backgroundDeep.withOpacity(0.5)
                  : Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEX FINGERPRINT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'A1B2:C3D4:E5F6:7890:ABCD:EF12:3456:789A\nB1C2:D3E4:F5G6:7890:HIJK:LM12:NOP3:QRS4',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark ? AppTheme.electricCyan : AppTheme.primaryBlue,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.verified_user, size: 20),
                  label: const Text('MARK TRUSTED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.backgroundDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.compare_arrows, size: 20),
                  label: const Text('COMPARE'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Key Cards ──
          _StitchKeyCard(
            title: 'RSA Key Pair',
            type: 'RSA-4096',
            status: 'Active',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _StitchKeyCard(
            title: 'AES Session Keys',
            type: 'AES-256-GCM',
            status: 'Active',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2: Login History (matches Stitch Login History Timeline screen)
// ══════════════════════════════════════════════════════════════════════════════

class _LoginHistoryTab extends StatelessWidget {
  final bool isDark;
  const _LoginHistoryTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final events = [
      _LoginEvent(
        device: 'Android Phone',
        location: 'New York, USA',
        ip: '192.168.1.1',
        time: '2 hours ago',
        status: 'success',
      ),
      _LoginEvent(
        device: 'Windows PC',
        location: 'New York, USA',
        ip: '192.168.1.2',
        time: '1 day ago',
        status: 'success',
      ),
      _LoginEvent(
        device: 'Unknown Device',
        location: 'London, UK',
        ip: '45.33.32.156',
        time: '3 days ago',
        status: 'failed',
      ),
      _LoginEvent(
        device: 'Android Phone',
        location: 'New York, USA',
        ip: '192.168.1.1',
        time: '5 days ago',
        status: 'success',
      ),
      _LoginEvent(
        device: 'MacBook Pro',
        location: 'San Francisco, USA',
        ip: '10.0.0.45',
        time: '1 week ago',
        status: 'success',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Security score banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.backgroundDeep,
                ],
              ),
              border: Border.all(
                color: AppTheme.electricCyan.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.electricCyan.withOpacity(0.6),
                      width: 3,
                    ),
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                  ),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '92',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.electricCyan,
                            ),
                          ),
                          TextSpan(
                            text: '%',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.electricCyan.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No suspicious activity detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Timeline ──
          Text(
            'ACCESS LOG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == events.length - 1;

            return _TimelineEntry(
              event: event,
              isDark: isDark,
              isLast: isLast,
            );
          }),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.security, size: 20),
              label: const Text('SECURE ACCOUNT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.warningOrange,
                side: BorderSide(
                  color: AppTheme.warningOrange.withOpacity(0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3: Security Settings
// ══════════════════════════════════════════════════════════════════════════════

class _SecuritySettingsTab extends ConsumerWidget {
  final bool isDark;
  const _SecuritySettingsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recovery
          _SectionLabel('RECOVERY'),
          const SizedBox(height: 12),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsRow(
                icon: Icons.backup_outlined,
                title: 'Recovery Codes',
                subtitle: '8 codes saved (6 unused)',
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
              Divider(height: 1, color: AppTheme.primaryBlue.withOpacity(0.2)),
              _SettingsRow(
                icon: Icons.cloud_outlined,
                title: 'Backup Key',
                subtitle: 'Last backed up 2 days ago',
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Authentication
          _SectionLabel('AUTHENTICATION'),
          const SizedBox(height: 12),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsRow(
                icon: Icons.fingerprint,
                title: 'Biometric',
                subtitle: 'Fingerprint / Face ID',
                trailing: _StitchToggle(value: true),
              ),
              Divider(height: 1, color: AppTheme.primaryBlue.withOpacity(0.2)),
              _SettingsRow(
                icon: Icons.phonelink_lock_outlined,
                title: 'Two-Factor Auth',
                subtitle: 'Authenticator app',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.successGreen.withOpacity(0.1),
                  ),
                  child: const Text(
                    'ENABLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppTheme.primaryBlue.withOpacity(0.2)),
            ],
          ),
          const SizedBox(height: 24),

          // Danger zone
          _SectionLabel('DANGER ZONE'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorRed.withOpacity(0.3),
              ),
              color: AppTheme.errorRed.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 20, color: AppTheme.errorRed),
                    const SizedBox(width: 8),
                    const Text(
                      'Destructive Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reset All Keys'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 2,
      ),
    );
  }
}

class _StitchKeyCard extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final bool isDark;

  const _StitchKeyCard({
    required this.title,
    required this.type,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        color: isDark ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.primaryBlue.withOpacity(0.3),
            ),
            child: const Icon(Icons.key, color: AppTheme.electricCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.successGreen.withOpacity(0.1),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginEvent {
  final String device;
  final String location;
  final String ip;
  final String time;
  final String status;

  _LoginEvent({
    required this.device,
    required this.location,
    required this.ip,
    required this.time,
    required this.status,
  });
}

class _TimelineEntry extends StatelessWidget {
  final _LoginEvent event;
  final bool isDark;
  final bool isLast;

  const _TimelineEntry({
    required this.event,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = event.status == 'success';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess
                              ? AppTheme.successGreen
                              : AppTheme.errorRed)
                          .withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 80,
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Event card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              color: isDark
                  ? AppTheme.primaryBlue.withOpacity(0.08)
                  : Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.device,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isSuccess
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.errorRed.withOpacity(0.1),
                      ),
                      child: Text(
                        isSuccess ? 'SUCCESS' : 'FAILED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSuccess
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${event.location} • IP: ${event.ip}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        color: isDark ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.grey[50],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _StitchToggle extends StatelessWidget {
  final bool value;
  const _StitchToggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: value ? AppTheme.successGreen : Colors.grey[400],
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
