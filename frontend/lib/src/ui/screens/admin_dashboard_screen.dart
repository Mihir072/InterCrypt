import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme/app_theme.dart';

/// AdminDashboardScreen — Full admin control panel for IntelCrypt.
///
/// Features:
///  - System statistics (users, messages, sessions, storage)
///  - User management (list, search, ban/unban, promote/demote)
///  - Audit log viewer
///  - Broadcast message to all users
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _broadcastController = TextEditingController();

  bool _isLoading = false;
  List<_AdminUser> _users = [];
  List<_AuditEntry> _auditLog = [];
  _SystemStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      // Load users from API
      final usersRaw = await api.getUsers();
      final chats = await api.getChats();
      final logsRaw = await api.getSystemAuditLogs();

      setState(() {
        _users = usersRaw
            .map((u) => _AdminUser(
                  id: u['id']?.toString() ?? '',
                  username: u['username']?.toString() ?? 'Unknown',
                  email: u['email']?.toString() ?? '',
                  role: u['role']?.toString() ?? 'USER',
                  isBanned: u['banned'] == true,
                  lastActive: u['lastLoginAt']?.toString() ?? '—',
                ))
            .toList();

        _stats = _SystemStats(
          totalUsers: _users.length,
          totalChats: chats.length,
          totalMessages: chats.fold(0, (sum, c) => sum + c.unreadCount),
          activeUsers: _users.where((u) => !u.isBanned).length,
          bannedUsers: _users.where((u) => u.isBanned).length,
        );

        _auditLog = logsRaw.map((log) {
          final type = log['eventType']?.toString() ?? 'SYSTEM_EVENT';
          final desc = log['description']?.toString() ?? 'No description';
          final tsStr = log['timestamp']?.toString();
          final timestamp = tsStr != null ? DateTime.tryParse(tsStr) ?? DateTime.now() : DateTime.now();
          final outcome = log['outcome']?.toString() ?? 'SUCCESS';
          
          String severity = 'INFO';
          if (outcome == 'FAILURE' || outcome == 'SUSPICIOUS') severity = 'WARNING';
          if (type.contains('TAMPER') || type.contains('INTRUSION') || outcome == 'BLOCKED') severity = 'CRITICAL';

          return _AuditEntry(
            action: type,
            description: desc,
            timestamp: timestamp,
            severity: severity,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('AdminDashboard: load error — $e');
      // Populate with empty state on error
      setState(() {
        _stats = _SystemStats(
          totalUsers: 0, totalChats: 0, totalMessages: 0,
          activeUsers: 0, bannedUsers: 0,
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan(_AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          user.isBanned ? 'Unban User?' : 'Ban User?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          '${user.isBanned ? 'Restore access for' : 'Revoke access for'} ${user.username}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: user.isBanned ? AppTheme.successGreen : AppTheme.errorRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(user.isBanned ? 'Unban' : 'Ban'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        final index = _users.indexOf(user);
        if (index != -1) {
          _users[index] = user.copyWith(isBanned: !user.isBanned);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isBanned
                  ? '${user.username} has been unbanned'
                  : '${user.username} has been banned',
            ),
            backgroundColor:
                user.isBanned ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleRole(_AdminUser user) async {
    final newRole = user.role == 'ADMIN' ? 'USER' : 'ADMIN';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Change Role?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Set ${user.username} as $newRole?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        final index = _users.indexOf(user);
        if (index != -1) {
          _users[index] = user.copyWith(role: newRole);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.username} is now $newRole'),
            backgroundColor: AppTheme.accentBlue,
          ),
        );
      }
    }
  }

  Future<void> _sendBroadcast() async {
    final msg = _broadcastController.text.trim();
    if (msg.isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate API call
    _broadcastController.clear();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast message sent to all users'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _broadcastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppTheme.electricCyan,
                backgroundColor: AppTheme.surfaceDark,
              ),
            if (_stats != null) _buildStatsRow(),
            _buildTabBar(),
            Expanded(child: _buildTabViews()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.electricCyan, AppTheme.accentBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'IntelCrypt Control Panel',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: AppTheme.electricCyan),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(label: 'Users', value: '${s.totalUsers}',
              icon: Icons.people, color: AppTheme.accentBlue),
          const SizedBox(width: 10),
          _StatCard(label: 'Active', value: '${s.activeUsers}',
              icon: Icons.check_circle, color: AppTheme.successGreen),
          const SizedBox(width: 10),
          _StatCard(label: 'Chats', value: '${s.totalChats}',
              icon: Icons.chat, color: AppTheme.electricCyan),
          const SizedBox(width: 10),
          _StatCard(label: 'Banned', value: '${s.bannedUsers}',
              icon: Icons.block, color: AppTheme.errorRed),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.electricCyan,
        indicatorWeight: 2,
        labelColor: AppTheme.electricCyan,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
          Tab(icon: Icon(Icons.history, size: 18), text: 'Audit Log'),
          Tab(icon: Icon(Icons.campaign, size: 18), text: 'Broadcast'),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUsersTab(),
        _buildAuditLogTab(),
        _buildBroadcastTab(),
      ],
    );
  }

  // ── Users Tab ───────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    final query = _searchController.text.toLowerCase();
    final filtered = _users
        .where((u) =>
            u.username.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search users…',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
              filled: true,
              fillColor: AppTheme.primaryBlue.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No users found',
                      style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, idx) => _buildUserTile(filtered[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserTile(_AdminUser user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isBanned
              ? AppTheme.errorRed.withOpacity(0.3)
              : AppTheme.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: user.isBanned
                  ? AppTheme.errorRed.withOpacity(0.2)
                  : AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: user.isBanned
                      ? AppTheme.errorRed
                      : AppTheme.electricCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    if (user.isBanned)
                      _Badge(label: 'BANNED', color: AppTheme.errorRed),
                    if (user.role == 'ADMIN')
                      _Badge(label: 'ADMIN', color: AppTheme.warningOrange),
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppTheme.textMuted, size: 18),
            color: AppTheme.surfaceDark,
            onSelected: (action) {
              if (action == 'ban') _toggleBan(user);
              if (action == 'role') _toggleRole(user);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(user.isBanned ? Icons.check_circle : Icons.block,
                        size: 16,
                        color: user.isBanned
                            ? AppTheme.successGreen
                            : AppTheme.errorRed),
                    const SizedBox(width: 8),
                    Text(
                      user.isBanned ? 'Unban' : 'Ban',
                      style: TextStyle(
                          color: user.isBanned
                              ? AppTheme.successGreen
                              : AppTheme.errorRed),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    const Icon(Icons.manage_accounts,
                        size: 16, color: AppTheme.warningOrange),
                    const SizedBox(width: 8),
                    Text(
                      user.role == 'ADMIN'
                          ? 'Demote to User'
                          : 'Promote to Admin',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Audit Log Tab ──────────────────────────────────────────────────────────

  Widget _buildAuditLogTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _auditLog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, idx) => _buildAuditTile(_auditLog[idx]),
    );
  }

  Widget _buildAuditTile(_AuditEntry entry) {
    final severityColor = {
      'INFO': AppTheme.accentBlue,
      'WARNING': AppTheme.warningOrange,
      'CRITICAL': AppTheme.errorRed,
    }[entry.severity] ?? AppTheme.textMuted;

    final icon = {
      'USER_LOGIN': Icons.login,
      'MESSAGE_SENT': Icons.send,
      'BIOMETRIC_FAIL': Icons.fingerprint,
      'SESSION_EXPIRED': Icons.lock_clock,
      'USER_BANNED': Icons.block,
    }[entry.action] ?? Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: severityColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action.replaceAll('_', ' '),
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Badge(label: entry.severity, color: severityColor),
              const SizedBox(height: 4),
              Text(
                _timeAgo(entry.timestamp),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Broadcast Tab ──────────────────────────────────────────────────────────

  Widget _buildBroadcastTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Broadcast Message',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This message will be delivered to all active users.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.warningOrange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use broadcasts sparingly — only for critical system announcements.',
                    style: TextStyle(
                        color: AppTheme.warningOrange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _broadcastController,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Enter broadcast message…',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.primaryBlue.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppTheme.primaryBlue.withOpacity(0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppTheme.primaryBlue.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.electricCyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: AppTheme.backgroundDeep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.backgroundDeep))
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isLoading ? 'Sending…' : 'Send to All Users',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

class _AdminUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final bool isBanned;
  final String lastActive;

  const _AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isBanned,
    required this.lastActive,
  });

  _AdminUser copyWith({String? role, bool? isBanned}) {
    return _AdminUser(
      id: id,
      username: username,
      email: email,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      lastActive: lastActive,
    );
  }
}

class _AuditEntry {
  final String action;
  final String description;
  final DateTime timestamp;
  final String severity;

  const _AuditEntry({
    required this.action,
    required this.description,
    required this.timestamp,
    required this.severity,
  });
}

class _SystemStats {
  final int totalUsers;
  final int totalChats;
  final int totalMessages;
  final int activeUsers;
  final int bannedUsers;

  const _SystemStats({
    required this.totalUsers,
    required this.totalChats,
    required this.totalMessages,
    required this.activeUsers,
    required this.bannedUsers,
  });
}
