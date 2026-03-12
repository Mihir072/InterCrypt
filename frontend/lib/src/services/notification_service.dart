import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an in-app notification for a new message
class InAppNotification {
  final String id;
  final String chatId;
  final String chatName;
  final String previewText;
  final DateTime timestamp;

  const InAppNotification({
    required this.id,
    required this.chatId,
    required this.chatName,
    required this.previewText,
    required this.timestamp,
  });
}

/// Single-slot notification state — only one notification at a time.
/// New notifications always replace (bump) the current one.
/// This avoids all queue/animation race conditions.
class NotificationNotifier extends StateNotifier<InAppNotification?> {
  NotificationNotifier() : super(null);

  /// Show a notification, replacing any currently visible one.
  void show(InAppNotification notification) {
    state = notification;
  }

  /// Dismiss a notification (only if it matches the current one).
  void dismiss(String id) {
    if (state?.id == id) state = null;
  }

  /// Dismiss whatever is currently showing.
  void dismissCurrent() => state = null;

  /// Dismiss by chat ID (used when user navigates into the chat).
  void dismissByChatId(String chatId) {
    if (state?.chatId == chatId) state = null;
  }
}

/// Global notification provider — holds at most one InAppNotification.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, InAppNotification?>(
      (ref) => NotificationNotifier(),
    );
