import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

/// Message Bubble Widget - Display individual message
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(isSent ? 60 : 8, 8, isSent ? 8 : 60, 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: isSent
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              decoration: BoxDecoration(
                color: isSent
                    ? colorScheme.primary
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSent ? Colors.white : Colors.black87,
                    ),
                  ),

                  // Attachments (if any)
                  if (message.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          message.attachments.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: isSent
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    message.attachments[index].fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isSent
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Self-destructing timer (if applicable)
                  if (message.isSelfDestructing &&
                      message.expiresAt != null &&
                      message.expiresAt!.isAfter(DateTime.now()))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 12,
                            color: isSent ? Colors.white70 : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDestructTime(message.expiresAt!),
                            style: textTheme.labelSmall?.copyWith(
                              color: isSent ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Timestamp and delivery status
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isSent
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(message.sentAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isSent)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _buildDeliveryStatus(message.status),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.schedule, size: 14, color: Colors.orange);
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 14, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
      case MessageStatus.archived:
        return const Icon(Icons.archive, size: 14, color: Colors.grey);
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();

    if (now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (now.subtract(const Duration(days: 1)).day == dateTime.day) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  String _formatDestructTime(DateTime destructTime) {
    final now = DateTime.now();
    final difference = destructTime.difference(now);

    if (difference.inSeconds < 0) {
      return 'Destroyed';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }
}
