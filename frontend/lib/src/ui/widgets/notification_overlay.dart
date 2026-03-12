import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/notification_service.dart';
import '../../providers/providers.dart';

/// Wraps the app and shows a slide-down banner when a new message arrives.
///
/// Uses a single-slot notification model — new notifications immediately
/// replace (bump) any currently visible banner. No queue, no race conditions.
class NotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationOverlay({required this.child, super.key});

  @override
  ConsumerState<NotificationOverlay> createState() =>
      _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  InAppNotification? _current;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showBanner(InAppNotification notification) {
    // Cancel any pending auto-dismiss
    _autoDismissTimer?.cancel();

    // Stop whatever animation is running and immediately start forward
    _controller.stop();

    setState(() => _current = notification);

    // Always start from the top so bumped banners feel fresh
    _controller.forward(from: 0);

    // Capture the id now; the timer closure dismisses only THIS notification
    final id = notification.id;
    _autoDismissTimer = Timer(const Duration(seconds: 4), () => _dismiss(id));
  }

  void _dismiss(String notificationId) {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (!mounted) return;
      // Only clear _current if it still refers to the same notification
      // (it may have been replaced by a newer banner)
      if (_current?.id == notificationId) {
        setState(() => _current = null);
      }
      // Tell the provider to clear this notification
      ref.read(notificationProvider.notifier).dismiss(notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InAppNotification?>(notificationProvider, (prev, next) {
      if (next == null) return;

      // If the user is already inside this chat, silently dismiss
      final activeChatId = ref.read(selectedChatProvider);
      if (activeChatId == next.chatId) {
        ref.read(notificationProvider.notifier).dismissByChatId(next.chatId);
        return;
      }

      // Same notification already showing — nothing to do
      if (_current?.id == next.id) return;

      // Show (or bump) the banner
      _showBanner(next);
    });

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _BannerCard(
                    notification: _current!,
                    onTap: () {
                      _autoDismissTimer?.cancel();
                      final chatId = _current!.chatId;
                      final chatName = _current!.chatName;
                      final id = _current!.id;
                      _controller.reverse().then((_) {
                        if (!mounted) return;
                        setState(() => _current = null);
                        ref.read(notificationProvider.notifier).dismiss(id);
                        context.goNamed(
                          'chat_message',
                          pathParameters: {'chatId': chatId},
                          queryParameters: {'chatName': chatName},
                        );
                      });
                    },
                    onDismiss: () => _dismiss(_current!.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.chatName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.previewText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
