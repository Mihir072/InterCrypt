import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../../services/steganography_service.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'steganography_widgets.dart';
import '../../services/location_verification_service.dart';
import 'location_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Message Bubble — Stitch Secure Chat design
class MessageBubble extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(isSent ? 60 : 8, 4, isSent ? 8 : 60, 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              decoration: BoxDecoration(
                color: isSent
                    ? AppTheme.primaryBlue
                    : (isDark
                        ? AppTheme.primaryBlue.withOpacity(0.2)
                        : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 16),
                ),
                border: Border.all(
                  color: isSent
                      ? AppTheme.electricCyan.withOpacity(0.2)
                      : AppTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSent
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimary : Colors.black87),
                      height: 1.4,
                    ),
                  ),

                  // Attachments
                  if (message.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: message.attachments.map((att) {
                          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(att.fileType.toLowerCase());
                          
                          if (isImage && att.fileUrl.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GestureDetector(
                                      onTap: () => _handleAttachmentTap(context, ref, att),
                                      onLongPress: att.hasHiddenData ? () => _showStegoMenu(context, att) : null,
                                      child: Container(
                                        constraints: const BoxConstraints(maxHeight: 200),
                                        child: kIsWeb || att.fileUrl.startsWith('http') || att.fileUrl.startsWith('blob:')
                                            ? Image.network(att.fileUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                                            : Image.file(File(att.fileUrl), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                      ),
                                    ),
                                  ),
                                  if (att.hasHiddenData)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: HiddenDataIndicator(),
                                    ),
                                  if (att.locationRestrictionEnabled)
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on, size: 10, color: AppTheme.electricCyan),
                                            SizedBox(width: 4),
                                            Text(
                                              'GEOFENCED',
                                              style: TextStyle(color: AppTheme.electricCyan, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () => _handleAttachmentTap(context, ref, att),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        size: 13,
                                        color: isSent
                                            ? AppTheme.electricCyan.withOpacity(0.7)
                                            : AppTheme.textMuted,
                                      ),
                                      if (att.locationRestrictionEnabled)
                                        const Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Icon(Icons.location_on, size: 8, color: AppTheme.electricCyan),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      att.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSent
                                            ? AppTheme.electricCyan.withOpacity(0.7)
                                            : AppTheme.textMuted,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Self-destructing timer
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
                            size: 11,
                            color: isSent
                                ? AppTheme.warningOrange.withOpacity(0.8)
                                : AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDestructTime(message.expiresAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSent
                                  ? AppTheme.warningOrange.withOpacity(0.8)
                                  : AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Timestamp and status
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted.withOpacity(0.7),
                    ),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    _buildDeliveryStatus(message.status),
                  ],
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
        return Icon(Icons.schedule, size: 13,
            color: AppTheme.electricCyan.withOpacity(0.5));
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 13, color: AppTheme.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 13, color: AppTheme.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 13,
            color: AppTheme.electricCyan);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 13,
            color: AppTheme.errorRed);
      case MessageStatus.archived:
        return const Icon(Icons.archive, size: 13, color: AppTheme.textMuted);
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
    final difference = destructTime.difference(DateTime.now());
    if (difference.inSeconds < 0) return 'Destroyed';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    return '${difference.inHours}h';
  }

  void _showStegoMenu(BuildContext context, MessageAttachment att) {
    showModalBottomSheet(
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
            const Icon(Icons.lock_rounded, color: AppTheme.electricCyan, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Hidden Data Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: AppTheme.electricCyan),
              title: const Text(
                'Extract Hidden Message',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _extractHiddenData(context, att);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAttachmentTap(BuildContext context, WidgetRef ref, MessageAttachment att) async {
    if (att.locationRestrictionEnabled) {
      // Show verification loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.electricCyan),
        ),
      );

      final result = await ref.read(locationVerificationServiceProvider).isUserWithinAllowedLocation(
        targetLat: att.restrictedLatitude!,
        targetLon: att.restrictedLongitude!,
        allowedRadius: att.allowedRadius!,
      );

      if (context.mounted) Navigator.pop(context); // Close loader

      if (result.isAllowed) {
        _launchAttachment(att);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => RestrictedContentWarning(
              locationName: att.locationLabel,
              radius: att.allowedRadius!,
              currentDistance: result.distance,
              onRefresh: () {
                Navigator.pop(context);
                _handleAttachmentTap(context, ref, att);
              },
            ),
          );
        }
      }
    } else {
      _launchAttachment(att);
    }
  }

  Future<void> _launchAttachment(MessageAttachment att) async {
    if (att.fileUrl.isNotEmpty) {
      final uri = Uri.parse(att.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _extractHiddenData(BuildContext context, MessageAttachment att) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.electricCyan)),
    );

    try {
      Uint8List bytes;
      if (att.fileUrl.startsWith('http')) {
        final response = await http.get(Uri.parse(att.fileUrl));
        bytes = response.bodyBytes;
      } else {
        bytes = await File(att.fileUrl).readAsBytes();
      }

      final secret = await SteganographyService.decode(bytes);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (secret != null) {
          showDialog(
            context: context,
            builder: (context) => ExtractMessageDialog(secretMessage: secret),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to extract hidden data')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
