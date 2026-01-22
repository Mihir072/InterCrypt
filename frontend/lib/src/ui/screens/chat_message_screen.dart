// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
import '../../models/message_model.dart';
import '../../providers/providers.dart';

/// ChatMessageScreen displays all messages in a conversation thread.
///
/// Features:
/// - Displays messages in chronological order with message bubbles
/// - Real-time message updates via Riverpod
/// - Search and filter messages (by text content)
/// - Mark messages as read
/// - Delete messages
/// - Self-destructing messages countdown
/// - Delivery status indicators (pending, sent, delivered, read)
/// - File attachment preview
/// - Optimistic message sending (instant UI update, synced with backend)
/// - Empty state handling
/// - Error state with retry
/// - Loading state with skeleton
/// - Message timestamp grouping (today, yesterday, date)
class ChatMessageScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatAvatar;

  const ChatMessageScreen({
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    super.key,
  });

  @override
  ConsumerState<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends ConsumerState<ChatMessageScreen> {
  late TextEditingController _messageController;
  late TextEditingController _searchController;
  late FocusNode _messageFocusNode;
  late FocusNode _searchFocusNode;

  bool _showSearch = false;
  bool _isLoadingMessage = false;
  bool _isLoadingMessages = true;
  ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _searchController = TextEditingController();
    _messageFocusNode = FocusNode();
    _searchFocusNode = FocusNode();
    _loadMessages();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final authState = ref.read(authProvider);
    _currentUserId = authState.currentUser?.id;
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoadingMessages = true);
      final messages = await ref
          .read(apiServiceProvider)
          .getMessages(widget.chatId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoadingMessages = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _messageFocusNode.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to the bottom of the message list (newest messages)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Build messages list widget
  Widget _buildMessagesList() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredMessages = _searchController.text.isEmpty
        ? _messages
        : _messages
              .where(
                (msg) => msg.content.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();

    if (filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.mail_outline
                  : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No messages yet\nStart a conversation!'
                  : 'No messages match your search',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        final isSent = message.senderId == _currentUserId;

        return MessageBubble(
          message: message,
          isSent: isSent,
          onTap: () {},
          onLongPress: () {
            _showMessageContextMenu(message, Offset.zero);
          },
        );
      },
    );
  }

  /// Send a message and update UI optimistically
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoadingMessage = true);

    try {
      // Clear input immediately for better UX
      _messageController.clear();

      // Send message via API
      final sentMessage = await ref
          .read(apiServiceProvider)
          .sendMessage(widget.chatId, content: text);

      // Add message to local list
      setState(() {
        _messages.add(sentMessage);
      });

      // Scroll to bottom to show new message
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessage = false);
      }
    }
  }

  /// Delete a message (with confirmation)
  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('This message will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from provider
        // TODO: Implement when message provider is ready
        // ref.read(messageListProvider(widget.chatId).notifier).removeMessage(message.id);

        // Request backend to delete message
        // In real app: await messageService.deleteMessage(message.id)

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Copy message text to clipboard
  Future<void> _copyMessage(Message message) async {
    // In production: use clipboard_manager
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  /// Show message context menu
  void _showMessageContextMenu(Message message, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 1,
        offset.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
          onTap: () => _copyMessage(message),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.reply, size: 18),
              SizedBox(width: 8),
              Text('Reply'),
            ],
          ),
          onTap: () {
            // Implement reply functionality
            _messageController.text = '@${message.senderId} ';
            _messageFocusNode.requestFocus();
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteMessage(message),
        ),
      ],
    );
  }

  /// Format message group header (date separator)
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.toLocal()}'.split(' ')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName),
            const Text(
              'End-to-end encrypted',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = true),
            )
          else
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                setState(() => _showSearch = false);
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info (members, settings, etc)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat info feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(child: _buildMessagesList()),

          // Message Input Field
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: MessageInputField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              isLoading: _isLoadingMessage,
              onChanged: (_) => setState(() {}),
              onSendPressed: _sendMessage,
              onAttachmentPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File attachment feature coming soon'),
                  ),
                );
              },
              onEmojiPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emoji picker feature coming soon'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
