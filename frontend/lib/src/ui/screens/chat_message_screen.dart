// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/message_bubble.dart';
import '../../models/message_model.dart';
import '../../models/models.dart';
import '../../services/encryption_service.dart';
import '../../services/steganography_service.dart';
import '../widgets/location_widgets.dart';

import '../../providers/providers.dart';
import '../../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/steganography_widgets.dart';

/// ChatMessageScreen — Stitch Refined Secure Chat design
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
  final List<PlatformFile> _selectedFiles = [];
  final Map<String, String> _stegoMessages = {}; // Maps file path to secret message
  final Map<String, Map<String, dynamic>> _locationRestrictions = {}; // Maps file path/name to restriction data

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _searchController = TextEditingController();
    _messageFocusNode = FocusNode();
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedChatProvider.notifier).state = widget.chatId;
    });
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
      final messages =
          await ref.read(apiServiceProvider).getMessages(widget.chatId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoadingMessages = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        try {
          await ref
              .read(apiServiceProvider)
              .markAllMessagesAsRead(widget.chatId);
          ref.read(chatListProvider.notifier).fetchChats();
        } catch (_) {}
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
    ref.read(selectedChatProvider.notifier).state = null;
    ref.read(chatListProvider.notifier).fetchChats();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    setState(() => _isLoadingMessage = true);
    try {
      final List<MessageAttachment> uploadedAttachments = [];
      
      for (var f in _selectedFiles) {
        String uploadedUrl = f.path ?? '';
        final stegoMessage = _stegoMessages[f.path ?? f.name];
        final isStego = stegoMessage != null;
        
        // Location Restriction data
        final restriction = _locationRestrictions[f.path ?? f.name];
        final bool locationEnabled = restriction != null;

        try {
          // Upload to server
          final response = await ref.read(apiServiceProvider).uploadFile(
            f.path ?? '',
            f.name,
            bytes: f.bytes,
          );
          if (response['fileDownloadUri'] != null) {
            uploadedUrl = response['fileDownloadUri'];
          }
        } catch (e) {
          print('Failed to upload ${f.name}: $e');
        }

        uploadedAttachments.add(MessageAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString() + f.name.replaceAll(' ', '_'),
          fileName: f.name,
          fileType: f.extension ?? 'unknown',
          fileSize: f.size,
          fileUrl: uploadedUrl,
          encryptionKeyId: 'default',
          hasHiddenData: isStego,
          locationRestrictionEnabled: locationEnabled,
          restrictedLatitude: restriction?['lat'],
          restrictedLongitude: restriction?['lon'],
          allowedRadius: restriction?['radius'],
          locationLabel: restriction?['label'],
        ));
      }

      _messageController.clear();
      _selectedFiles.clear();
      _stegoMessages.clear();
      _locationRestrictions.clear();

      final sentMessage = await ref
          .read(apiServiceProvider)
          .sendMessage(
            widget.chatId, 
            content: text.isEmpty ? '[Attachment]' : text,
            attachments: uploadedAttachments,
          );
      setState(() => _messages.add(sentMessage));
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMessage = false);
    }
  }

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
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    }
  }

  Future<void> _copyMessage(Message message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _showMessageContextMenu(Message message, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + 1, offset.dy + 1),
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
            _messageController.text = '@${message.senderId} ';
            _messageFocusNode.requestFocus();
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
            ],
          ),
          onTap: () => _deleteMessage(message),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // Need data for steganography
      );
      if (result != null) {
        for (var file in result.files) {
          final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(file.extension?.toLowerCase());
          
          if (isImage) {
            // Offer steganography for each image
            final bool? useStego = await showModalBottomSheet<bool>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Send Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how to send ${file.name}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.image, color: AppTheme.electricCyan),
                      title: const Text(
                        'Send Normally',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      onTap: () => Navigator.pop(context, false),
                    ),
                    ListTile(
                      leading: const Icon(Icons.enhanced_encryption, color: AppTheme.electricCyan),
                      title: const Text(
                        'Add Hidden Message (Steganography)',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      onTap: () => Navigator.pop(context, true),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );

            if (useStego == true) {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SteganographyOptionSheet(
                  fileName: file.name,
                  onProcess: (secret) async {
                    // Process encoding
                    try {
                      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
                      final encodedBytes = await SteganographyService.encode(bytes, secret);
                      
                      if (encodedBytes != null) {
                        if (kIsWeb) {
                          final stegoPlatformFile = PlatformFile(
                            name: 'secure_${file.name.split('.').first}.png',
                            size: encodedBytes.length,
                            bytes: encodedBytes,
                          );

                          setState(() {
                            _selectedFiles.add(stegoPlatformFile);
                            _stegoMessages[stegoPlatformFile.name] = secret;
                          });
                        } else {
                          // Save to temporary PNG file
                          final tempDir = await getTemporaryDirectory();
                          final stegoPath = '${tempDir.path}/stego_${DateTime.now().millisecondsSinceEpoch}.png';
                          final stegoFile = File(stegoPath);
                          await stegoFile.writeAsBytes(encodedBytes);
                          
                          final stegoPlatformFile = PlatformFile(
                            path: stegoPath,
                            name: 'secure_${file.name.split('.').first}.png',
                            size: encodedBytes.length,
                            bytes: encodedBytes,
                          );

                          setState(() {
                            _selectedFiles.add(stegoPlatformFile);
                            _stegoMessages[stegoPath] = secret;
                          });
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Steganography failed: $e'), backgroundColor: AppTheme.errorRed),
                      );
                    }
                  },
                ),
              );
              continue; // Skip adding the original file
            }
          }

          // Offer Location Restriction for all files
          final bool? applyLocation = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Access Control',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text('Restrict access to ${file.name}?', style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.public, color: AppTheme.electricCyan),
                    title: const Text('No Restriction', style: TextStyle(color: AppTheme.textPrimary)),
                    onTap: () => Navigator.pop(context, false),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppTheme.electricCyan),
                    title: const Text('Add Location Restriction', style: TextStyle(color: AppTheme.textPrimary)),
                    onTap: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );

          if (applyLocation == true) {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => LocationPickerModal(
                onSave: (lat, lon, radius, label) {
                  setState(() {
                    _locationRestrictions[file.path ?? file.name] = {
                      'lat': lat,
                      'lon': lon,
                      'radius': radius,
                      'label': label,
                    };
                  });
                },
              ),
            );
          }
          
          setState(() {
            _selectedFiles.add(file);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Real-time WebSocket ──
    ref.listen<Map<String, dynamic>?>(incomingMessageProvider, (_, incoming) async {
      if (incoming == null) return;
      if ((incoming['chatId'] as String?) != widget.chatId) return;
      try {
        Message newMsg = Message.fromJson({
          ...incoming,
          'chatId': widget.chatId,
        });

        // Decrypt the WebSocket message
        if (newMsg.content == '[Encrypted]' && newMsg.contentEncrypted.isNotEmpty) {
          try {
            final decrypted = await EncryptionService.decryptMessage(
              newMsg.contentEncrypted,
              keyId: newMsg.encryption.keyId,
              encryptionKey: 'default_key',
            );
            newMsg = ref.read(apiServiceProvider).parseDecryptedContent(newMsg, decrypted);
          } catch (_) {}
        }

        if (mounted) {
          setState(() => _messages.add(newMsg));
          Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
        }
      } catch (_) {}
    });

    return Scaffold(
      body: Column(
        children: [
          // ── Stitch Chat Header ──
          _buildChatHeader(context, isDark),

          // ── Encryption notice ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryBlue.withOpacity(0.15)
                  : AppTheme.primaryBlue.withOpacity(0.03),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: AppTheme.electricCyan.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'AES-256 end-to-end encrypted • Messages auto-destruct',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Messages ──
          Expanded(child: _buildMessagesList(isDark)),

          // ── Input area ──
          _buildInputArea(context, isDark),
        ],
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryBlue.withOpacity(0.2),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 18,
                color: isDark ? AppTheme.textPrimary : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.electricCyan.withOpacity(0.4),
                width: 2,
              ),
              color: AppTheme.primaryBlue,
            ),
            child: Center(
              child: Text(
                widget.chatName.isNotEmpty
                    ? widget.chatName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.electricCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online • Verified',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.videocam_outlined,
              color: AppTheme.textMuted,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
            },
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: AppTheme.textMuted,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    if (_isLoadingMessages) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.electricCyan,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'DECRYPTING MESSAGES...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    final filteredMessages = _searchController.text.isEmpty
        ? _messages
        : _messages
            .where((msg) => msg.content
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();

    if (filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.lock_outline
                  : Icons.search_off,
              size: 56,
              color: AppTheme.electricCyan.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Secure channel ready'
                  : 'No messages match your search',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? AppTheme.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a message to begin encrypted exchange',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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

  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFiles.isNotEmpty) _buildAttachmentPreview(isDark),
          Row(
            children: [
              // Attachment
              GestureDetector(
                onTap: _pickFiles,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryBlue.withOpacity(0.2),
              ),
              child: Icon(
                Icons.attach_file,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Message input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
                color: isDark
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : Colors.grey[50],
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.textPrimary : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Type encrypted message...',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _isLoadingMessage ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: (_messageController.text.trim().isNotEmpty || _selectedFiles.isNotEmpty)
                    ? AppTheme.electricCyan
                    : AppTheme.primaryBlue.withOpacity(0.3),
              ),
              child: _isLoadingMessage
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      size: 20,
                      color: (_messageController.text.trim().isNotEmpty || _selectedFiles.isNotEmpty)
                          ? AppTheme.backgroundDeep
                          : AppTheme.textMuted,
                    ),
            ),
          ),
        ],
      ), // Row ends
        ], // Column children ends
      ), // Column ends
    );
  }

  Widget _buildAttachmentPreview(bool isDark) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.extension?.toLowerCase());

          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
              color: isDark ? AppTheme.backgroundDark : Colors.grey[100],
            ),
            child: Stack(
              children: [
                if (isImage && (file.bytes != null || file.path != null))
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? (file.bytes != null
                              ? Image.memory(file.bytes!, fit: BoxFit.cover)
                              : const Icon(Icons.image, color: AppTheme.electricCyan))
                          : Image.file(
                              File(file.path!),
                              fit: BoxFit.cover,
                            ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: AppTheme.electricCyan.withOpacity(0.8),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            file.extension?.toUpperCase() ?? 'FILE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    onPressed: () => _removeFile(file),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

