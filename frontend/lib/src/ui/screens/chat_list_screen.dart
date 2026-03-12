// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';

/// Chat List Screen — Stitch-inspired Contacts Directory style
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with WidgetsBindingObserver {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatListProvider.notifier).fetchChats();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatListAsync = ref.watch(chatListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Stitch-style Header ──
          _buildHeader(context, isDark),

          // ── Chat List ──
          Expanded(
            child: Builder(
              builder: (context) {
                if (chatListAsync.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.electricCyan,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DECRYPTING DIRECTORY...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (chatListAsync.error != null) {
                  return _buildErrorState(context, chatListAsync);
                }

                final chats = chatListAsync.chats;
                final filteredChats = _searchController.text.isEmpty
                    ? chats
                    : chats
                        .where((chat) => chat.name
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();

                if (filteredChats.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return RefreshIndicator(
                  color: AppTheme.electricCyan,
                  backgroundColor: AppTheme.primaryBlue,
                  onRefresh: () async {
                    ref.refresh(chatListProvider);
                  },
                  child: ListView.builder(
                    itemCount: filteredChats.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final currentUserId = ref.watch(currentUserProvider)?.id;
                      return _StitchChatTile(
                        chat: chat,
                        currentUserId: currentUserId,
                        isDark: isDark,
                        onTap: () {
                          ref.read(selectedChatProvider.notifier).state = chat.id;
                          context.goNamed(
                            'chat_message',
                            pathParameters: {'chatId': chat.id},
                            queryParameters: {
                              'chatName': chat.getDisplayName(currentUserId),
                              'chatAvatar': chat.avatarUrl ?? '',
                            },
                          );
                        },
                        onArchive: () => _handleArchive(chat),
                        onDelete: () => _handleDelete(chat),
                        onMute: () => _showMuteOptions(context, chat),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // FAB — Stitch accent style
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.electricCyan,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricCyan.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNewConversationDialog(context),
            child: const Icon(
              Icons.add,
              size: 28,
              color: AppTheme.backgroundDeep,
            ),
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _StitchBottomNav(
        selectedIndex: 0,
        isDark: isDark,
        onTap: (index) {
          if (index == 3) context.goNamed('profile');
          if (index == 2) context.goNamed('security');
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryBlue.withOpacity(0.1)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.electricCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IntelCrypt',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'SECURE DIRECTORY',
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
              GestureDetector(
                onTap: () => context.goNamed('profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    color: isDark ? AppTheme.textPrimary : AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.4),
              ),
              color: isDark
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : Colors.grey[50],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search encrypted nodes...',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.electricCyan.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All Chats',
                  selected: _selectedFilter == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Encrypted',
                  selected: _selectedFilter == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Groups',
                  selected: _selectedFilter == 2,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Archived',
                  selected: _selectedFilter == 3,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFilter = 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue.withOpacity(0.2),
              border: Border.all(
                color: AppTheme.electricCyan.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 36,
              color: AppTheme.electricCyan.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'No active sessions'
                : 'No matching nodes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new encrypted conversation',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic chatListAsync) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorRed.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Lost',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            chatListAsync.error.toString(),
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(chatListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('RECONNECT'),
          ),
        ],
      ),
    );
  }

  // ── Dialog helpers (kept from original) ─────────────────────────────────

  Future<void> _handleArchive(Chat chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive conversation?'),
        content: Text('Archive "${chat.name}" conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(selectedChatProvider.notifier).state = chat.id;
      await ref.read(chatListProvider.notifier).archiveChat(chat.id);
      ref.refresh(chatListProvider);
    }
  }

  Future<void> _handleDelete(Chat chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
            'This will permanently delete the conversation and all messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.refresh(chatListProvider);
    }
  }

  void _showNewConversationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'START SECURE SESSION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _ModalOption(
              icon: Icons.person_outline,
              title: 'Direct Message',
              subtitle: 'E2E encrypted private session',
              onTap: () {
                Navigator.pop(context);
                _showUserSearchDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _ModalOption(
              icon: Icons.group_outlined,
              title: 'Group Chat',
              subtitle: 'Create encrypted group channel',
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showUserSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<User> searchResults = [];
    List<User> allUsers = [];
    bool isSearching = false;
    bool isLoading = true;

    Future<void> loadAllUsers(StateSetter setState) async {
      try {
        final results = await ref.read(apiServiceProvider).searchUsers('');
        setState(() {
          allUsers = results;
          searchResults = results;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading && allUsers.isEmpty) {
            loadAllUsers(setState);
          }
          return AlertDialog(
            title: const Text('Find User'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by username...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) async {
                      if (value.isEmpty) {
                        setState(() => searchResults = allUsers);
                      } else if (value.length >= 2) {
                        setState(() => isSearching = true);
                        try {
                          final results = await ref
                              .read(apiServiceProvider)
                              .searchUsers(value);
                          setState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } catch (e) {
                          setState(() => isSearching = false);
                        }
                      } else {
                        setState(() {
                          searchResults = allUsers
                              .where((u) => u.username
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  allUsers.isEmpty
                                      ? 'No users found'
                                      : 'No matching users',
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = searchResults[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryBlue,
                                      child: Text(
                                        user.username[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppTheme.electricCyan,
                                        ),
                                      ),
                                    ),
                                    title: Text(user.username),
                                    subtitle: Text(user.email),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _createDirectChat(user.id);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createDirectChat(String userId) async {
    try {
      final chat = await ref.read(apiServiceProvider).createDirectChat(userId);
      ref.refresh(chatListProvider);
      if (mounted) {
        context.goNamed(
          'chat_message',
          pathParameters: {'chatId': chat.id},
          queryParameters: {'chatName': chat.name},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can add members after creating the group.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _createGroupChat(nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroupChat(String name) async {
    try {
      final chat = await ref
          .read(apiServiceProvider)
          .createGroupChat(name: name, participantIds: []);
      ref.refresh(chatListProvider);
      if (mounted) {
        context.goNamed(
          'chat_message',
          pathParameters: {'chatId': chat.id},
          queryParameters: {'chatName': chat.name},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }

  void _showMuteOptions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mute Notifications',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...[
              '1 Hour',
              '8 Hours',
              '24 Hours',
              'Until I turn it back on'
            ].map((label) => ListTile(
                  title: Text(label),
                  onTap: () => Navigator.pop(context),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Chat Tile ─────────────────────────────────────────────────────────────────

class _StitchChatTile extends StatelessWidget {
  final Chat chat;
  final String? currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onMute;

  const _StitchChatTile({
    required this.chat,
    this.currentUserId,
    required this.isDark,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = chat.getDisplayName(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                        color: AppTheme.primaryBlue.withOpacity(0.5),
                      ),
                      child: chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                chat.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildInitials(displayName),
                              ),
                            )
                          : _buildInitials(displayName),
                    ),
                    // Online indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successGreen,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.backgroundDark
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.electricCyan.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: AppTheme.electricCyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.lastMessagePreview ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.electricCyan.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.electricCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                onArchive();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('Mute'),
              onTap: () {
                Navigator.pop(context);
                onMute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.errorRed)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: selected
              ? AppTheme.electricCyan
              : AppTheme.primaryBlue.withOpacity(0.4),
          border: Border.all(
            color: selected
                ? AppTheme.electricCyan
                : AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppTheme.backgroundDeep
                : (isDark ? AppTheme.textSecondary : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

// ── Modal Option ─────────────────────────────────────────────────────────────

class _ModalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModalOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            color: AppTheme.primaryBlue.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                ),
                child: Icon(icon, color: AppTheme.electricCyan),
              ),
              const SizedBox(width: 16),
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
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.electricCyan.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation ────────────────────────────────────────────────────────

class _StitchBottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final Function(int) onTap;

  const _StitchBottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryBlue.withOpacity(0.4)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.4),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.chat_bubble,
            label: 'Chats',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.lock_outline,
            label: 'Vault',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.key_outlined,
            label: 'Security',
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: selectedIndex == 3,
            onTap: () => onTap(3),
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
            color: selected ? AppTheme.electricCyan : AppTheme.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.electricCyan : AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
