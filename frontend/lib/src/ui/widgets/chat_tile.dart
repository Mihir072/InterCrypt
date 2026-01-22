import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

/// Chat Tile Widget - Display individual chat in list
class ChatTile extends StatefulWidget {
  final Chat chat;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onMute;
  final VoidCallback onDelete;

  const ChatTile({
    super.key,
    required this.chat,
    this.currentUserId,
    required this.onTap,
    required this.onArchive,
    required this.onMute,
    required this.onDelete,
  });

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onLongPress: () {
        _showContextMenu(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
          margin: EdgeInsets.zero,
          child: Dismissible(
            key: ValueKey(widget.chat.id),
            background: Container(
              color: Colors.orange[400],
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.volume_off, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.startToEnd) {
                widget.onMute();
              } else {
                widget.onDelete();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: widget.chat.avatarUrl != null
                            ? NetworkImage(widget.chat.avatarUrl!)
                            : null,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(50),
                        child: widget.chat.avatarUrl == null
                            ? Icon(
                                widget.chat.type == ChatType.group
                                    ? Icons.group
                                    : Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      // Unread badge
                      if (widget.chat.unreadCount > 0)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: Text(
                              widget.chat.unreadCount > 99
                                  ? '99+'
                                  : '${widget.chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Chat info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.chat.getDisplayName(
                                  widget.currentUserId,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: widget.chat.unreadCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(widget.chat.lastMessageAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Last message preview
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.chat.lastMessagePreview ??
                                    'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Encryption indicator
                            Tooltip(
                              message:
                                  'Encryption: ${widget.chat.encryption.algorithm}',
                              child: Icon(
                                Icons.lock,
                                size: 14,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),

                        // Mute indicator
                        if (widget.chat.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.volume_off,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Muted',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chat.getDisplayName(widget.currentUserId),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                widget.onArchive();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute'),
              onTap: () {
                Navigator.pop(context);
                widget.onMute();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
