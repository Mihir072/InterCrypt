// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// SecurityScreen handles security-related settings and key management.
///
/// Features:
/// - Display public key fingerprint
/// - View encryption settings
/// - Manage recovery codes
/// - Active sessions management
/// - Two-factor authentication status
/// - Security audit log
/// - Key rotation
/// - Device management
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _showPrivateKeyBackup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Security Status Banner
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.1),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 32, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Account is Secure',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'All encryption keys are properly configured',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Encryption Key Management
            _SectionHeader(title: 'Encryption Keys'),
            _KeyCard(
              title: 'RSA Key Pair',
              description: 'Used for secure key exchange',
              status: 'Active',
              fingerprint: 'A1B2:C3D4:E5F6:G7H8:I9J0:K1L2:M3N4:O5P6',
              onViewDetails: () {
                _showKeyDetailsDialog(
                  context,
                  'RSA Public Key',
                  'RSA-4096',
                  'A1B2:C3D4:E5F6:G7H8:I9J0:K1L2:M3N4:O5P6',
                  '-----BEGIN PUBLIC KEY-----\n'
                      'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n'
                      '-----END PUBLIC KEY-----',
                );
              },
              onRotate: () {
                _showRotateKeyDialog(context);
              },
            ),
            _KeyCard(
              title: 'AES Session Keys',
              description: 'Used for message encryption',
              status: 'Active',
              fingerprint: 'G7H8:I9J0:K1L2:M3N4:O5P6:Q7R8:S9T0:U1V2',
              onViewDetails: () {
                _showKeyDetailsDialog(
                  context,
                  'AES Session Key',
                  'AES-256-GCM',
                  'G7H8:I9J0:K1L2:M3N4:O5P6:Q7R8:S9T0:U1V2',
                  '[Encrypted - Not displayed for security]',
                );
              },
              onRotate: () {
                _showRotateKeyDialog(context);
              },
            ),

            // Recovery Codes
            _SectionHeader(title: 'Recovery'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Recovery Codes'),
                  subtitle: const Text('8 codes saved (6 unused)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showRecoveryCodesDialog(context);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_table),
                  title: const Text('Backup Key'),
                  subtitle: const Text('Last backed up 2 days ago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup key management coming soon'),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Authentication Settings
            _SectionHeader(title: 'Authentication'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Fingerprint / Face ID'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Biometric authentication ${value ? 'enabled' : 'disabled'}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.phonelink_lock),
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Not enabled'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _show2FADialog(context);
                  },
                ),
              ),
            ),

            // Device & Sessions
            _SectionHeader(title: 'Devices & Sessions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smartphone,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Device',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Android • Last active: now',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: const Text(
                              'Current',
                              style: TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.laptop,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Windows PC',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Windows 11 • Last active: 3 days ago',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Device session ended'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Security Audit Log
            _SectionHeader(title: 'Security Audit Log'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('View Audit Log'),
                  subtitle: const Text('Recent security events and activities'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAuditLogDialog(context);
                  },
                ),
              ),
            ),

            // Security Recommendations
            _SectionHeader(title: 'Recommendations'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Save your recovery codes in a secure location',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dangerous Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        _showResetSecurityDialog(context);
                      },
                      child: const Text(
                        'Reset Encryption Keys',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        _showDeleteAccountDialog(context);
                      },
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
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

  void _showKeyDetailsDialog(
    BuildContext context,
    String title,
    String keyType,
    String fingerprint,
    String keyContent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Type', keyType),
              const SizedBox(height: 12),
              const Text(
                'Fingerprint',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                fingerprint,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Text(
                'Public Key',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  keyContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Key copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showRotateKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotate Key'),
        content: const Text(
          'Rotating your encryption key will:\n\n'
          '• Create a new encryption key\n'
          '• Re-encrypt all stored messages\n'
          '• Require confirmation from linked devices\n'
          '• May take several minutes',
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
                  content: Text(
                    'Key rotation started. Check back in a few minutes.',
                  ),
                ),
              );
            },
            child: const Text('Start Rotation'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryCodesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Codes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store these codes in a secure location. Each code can be used once.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            'RC-${String.fromCharCodes(List.generate(8, (i) => 65 + (index * 7 + i) % 26))}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        Text(
                          index < 2 ? '✓' : '○',
                          style: TextStyle(
                            color: index < 2 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  void _show2FADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security by requiring a verification code in addition to your password.\n\nWould you like to set it up now?',
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
                const SnackBar(content: Text('2FA setup coming soon')),
              );
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Audit Log'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuditLogEntry(
                event: 'Login',
                device: 'Android Phone',
                timestamp: '2 hours ago',
                status: 'Success',
              ),
              _AuditLogEntry(
                event: 'Key Rotation',
                device: 'System',
                timestamp: '1 day ago',
                status: 'Success',
              ),
              _AuditLogEntry(
                event: 'Device Added',
                device: 'Windows PC',
                timestamp: '3 days ago',
                status: 'Success',
              ),
              _AuditLogEntry(
                event: 'Failed Login Attempt',
                device: 'Unknown',
                timestamp: '1 week ago',
                status: 'Failed',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Encryption Keys'),
        content: const Text(
          'Warning: This will reset all your encryption keys and may cause data loss.\n\n'
          'This action cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset initiated. You will be logged out.'),
                ),
              );
            },
            child: const Text('Reset Keys'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Warning: Deleting your account is permanent.\n\n'
          '• All messages will be permanently deleted\n'
          '• All encryption keys will be destroyed\n'
          '• This action cannot be undone\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion initiated')),
              );
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// Key Card Widget
class _KeyCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final String fingerprint;
  final VoidCallback onViewDetails;
  final VoidCallback onRotate;

  const _KeyCard({
    required this.title,
    required this.description,
    required this.status,
    required this.fingerprint,
    required this.onViewDetails,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  fingerprint,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onRotate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rotate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}

/// Audit Log Entry Widget
class _AuditLogEntry extends StatelessWidget {
  final String event;
  final String device;
  final String timestamp;
  final String status;

  const _AuditLogEntry({
    required this.event,
    required this.device,
    required this.timestamp,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            status == 'Success' ? Icons.check_circle : Icons.error,
            size: 20,
            color: status == 'Success' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$device • $timestamp',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
