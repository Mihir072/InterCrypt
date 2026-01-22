// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../widgets/chat_tile.dart';

/// Chat List Screen - Display all conversations
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatListAsync = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IntelCrypt'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.goNamed('profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => context.goNamed('security'),
            tooltip: 'Security',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Chat List
          Expanded(
            child: Builder(
              builder: (context) {
                if (chatListAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatListAsync.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load chats',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          chatListAsync.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref.refresh(chatListProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final chats = chatListAsync.chats;

                // Filter chats based on search
                final filteredChats = _searchController.text.isEmpty
                    ? chats
                    : chats
                          .where(
                            (chat) => chat.name.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchController.text.isEmpty)
                          const SizedBox(height: 8),
                        if (_searchController.text.isEmpty)
                          Text(
                            'Start a new conversation to begin',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(chatListProvider);
                    return Future.value();
                  },
                  child: ListView.builder(
                    itemCount: filteredChats.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final currentUserId = ref.watch(currentUserProvider)?.id;
                      return ChatTile(
                        chat: chat,
                        currentUserId: currentUserId,
                        onTap: () {
                          ref.read(selectedChatProvider.notifier).state =
                              chat.id;
                          context.goNamed(
                            'chat_message',
                            pathParameters: {'chatId': chat.id},
                            queryParameters: {
                              'chatName': chat.getDisplayName(currentUserId),
                              'chatAvatar': chat.avatarUrl ?? '',
                            },
                          );
                        },
                        onArchive: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Archive conversation?'),
                              content: Text(
                                'Archive "${chat.name}" conversation. It will not be deleted.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            ref.read(selectedChatProvider.notifier).state =
                                chat.id;
                            await ref
                                .read(chatListProvider.notifier)
                                .archiveChat(chat.id);
                            ref.refresh(chatListProvider);
                          }
                        },
                        onMute: () {
                          _showMuteOptions(context, chat);
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete conversation?'),
                              content: const Text(
                                'This will permanently delete the conversation and all messages.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            ref.refresh(chatListProvider);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewConversationDialog(context);
        },
        tooltip: 'New Conversation',
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start a Conversation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Direct Message'),
              subtitle: const Text('Send a private message'),
              onTap: () {
                Navigator.pop(context);
                _showUserSearchDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Group Chat'),
              subtitle: const Text('Create a group conversation'),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context);
              },
            ),
            const SizedBox(height: 16),
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

    // Load all users initially
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
          // Load users on first build
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) async {
                      if (value.isEmpty) {
                        // Show all users when search is cleared
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
                        // Filter locally for single character
                        setState(() {
                          searchResults = allUsers
                              .where(
                                (u) => u.username.toLowerCase().contains(
                                  value.toLowerCase(),
                                ),
                              )
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
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(user.username[0].toUpperCase()),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create chat: $e')));
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
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
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
            Text(
              'Mute Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('1 Hour'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('8 Hours'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('24 Hours'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Until I turn it back on'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Chat List Tile Widget
class ChatListTile extends StatelessWidget {
  final dynamic chat;
  final VoidCallback onTap;
  final VoidCallback onSwipeDelete;
  final VoidCallback onSwipeArchive;

  const ChatListTile({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onSwipeDelete,
    required this.onSwipeArchive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.id),
      background: Container(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          Icons.archive_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          Icons.delete_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onSwipeArchive();
        } else {
          onSwipeDelete();
        }
      },
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.2),
          backgroundImage: chat.avatarUrl != null
              ? NetworkImage(chat.avatarUrl!)
              : null,
          child: chat.avatarUrl == null
              ? Icon(
                  chat.isGroup ? Icons.people_rounded : Icons.person_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        title: Text(
          chat.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                chat.maskedPreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
            if (chat.classificationLevel != 'UNCLASSIFIED')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getClassificationColor(chat.classificationLevel),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    chat.classificationLevel.substring(0, 1),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chat.lastMessageAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (chat.unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getClassificationColor(String level) {
    switch (level) {
      case 'TOP_SECRET':
        return const Color(0xFFD32F2F);
      case 'SECRET':
        return const Color(0xFFF57C00);
      case 'CONFIDENTIAL':
        return const Color(0xFFFBC02D);
      case 'UNCLASSIFIED':
      default:
        return const Color(0xFF388E3C);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
