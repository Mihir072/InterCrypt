import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

part 'message_provider.g.dart';

/// Message list state
class MessageListState {
  final Map<String, List<Message>> messagesByChat;
  final bool isLoading;
  final String? error;
  final String? activeChat;
  final int pageSize;

  const MessageListState({
    this.messagesByChat = const {},
    this.isLoading = false,
    this.error,
    this.activeChat,
    this.pageSize = 50,
  });

  MessageListState copyWith({
    Map<String, List<Message>>? messagesByChat,
    bool? isLoading,
    String? error,
    String? activeChat,
    int? pageSize,
  }) {
    return MessageListState(
      messagesByChat: messagesByChat ?? this.messagesByChat,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      activeChat: activeChat ?? this.activeChat,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  List<Message> get activeMessages => messagesByChat[activeChat] ?? [];
  bool get canLoadMore => activeMessages.length >= pageSize;
}

/// Message List Notifier
class MessageListNotifier extends StateNotifier<MessageListState> {
  final ApiService _apiService;

  MessageListNotifier(this._apiService) : super(const MessageListState());

  /// Set active chat
  void setActiveChat(String chatId) {
    state = state.copyWith(activeChat: chatId);
  }

  /// Fetch messages for a chat
  Future<void> fetchMessages(String chatId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final messages = await _apiService.getMessages(
        chatId,
        limit: state.pageSize,
      );

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      updatedMessages[chatId] = messages;

      state = state.copyWith(
        messagesByChat: updatedMessages,
        isLoading: false,
        activeChat: chatId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages(String chatId) async {
    try {
      final currentMessages = state.messagesByChat[chatId] ?? [];
      if (currentMessages.isEmpty) return;

      final beforeMessageId = currentMessages.last.id;
      final moreMessages = await _apiService.getMessages(
        chatId,
        limit: state.pageSize,
        beforeMessageId: beforeMessageId,
      );

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      updatedMessages[chatId] = [...currentMessages, ...moreMessages];

      state = state.copyWith(messagesByChat: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send message
  Future<Message?> sendMessage(
    String chatId, {
    required String content,
    required String encryptedContent,
    required MessageEncryption encryption,
    List<MessageAttachment> attachments = const [],
    bool isSelfDestructing = false,
    int? expiresInSeconds,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final message = await _apiService.sendMessage(
        chatId,
        content: content,
        contentEncrypted: encryptedContent,
        encryption: encryption,
        attachments: attachments,
        isSelfDestructing: isSelfDestructing,
        expiresInSeconds: expiresInSeconds,
      );

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      final chatMessages = updatedMessages[chatId] ?? [];
      updatedMessages[chatId] = [message, ...chatMessages];

      state = state.copyWith(messagesByChat: updatedMessages, isLoading: false);

      return message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Mark message as read
  Future<bool> markAsRead(String chatId, String messageId) async {
    try {
      await _apiService.markMessageAsRead(chatId, messageId);

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      final chatMessages = updatedMessages[chatId] ?? [];
      updatedMessages[chatId] = chatMessages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(status: MessageStatus.read, readAt: DateTime.now())
                : m,
          )
          .toList();

      state = state.copyWith(messagesByChat: updatedMessages);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Mark all messages as read
  Future<bool> markAllAsRead(String chatId) async {
    try {
      await _apiService.markAllMessagesAsRead(chatId);

      final now = DateTime.now();
      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      final chatMessages = updatedMessages[chatId] ?? [];
      updatedMessages[chatId] = chatMessages
          .map((m) => m.copyWith(status: MessageStatus.read, readAt: now))
          .toList();

      state = state.copyWith(messagesByChat: updatedMessages);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _apiService.deleteMessage(chatId, messageId);

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByChat,
      );
      final chatMessages = updatedMessages[chatId] ?? [];
      updatedMessages[chatId] = chatMessages
          .where((m) => m.id != messageId)
          .toList();

      state = state.copyWith(messagesByChat: updatedMessages);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Search messages
  Future<List<Message>> searchMessages(String chatId, String query) async {
    try {
      return await _apiService.searchMessages(chatId, query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear cache for chat
  void clearChatCache(String chatId) {
    final updatedMessages = Map<String, List<Message>>.from(
      state.messagesByChat,
    );
    updatedMessages.remove(chatId);
    state = state.copyWith(messagesByChat: updatedMessages);
  }
}

/// Message list provider
final messageListProvider =
    StateNotifierProvider.autoDispose<MessageListNotifier, MessageListState>((
      ref,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      return MessageListNotifier(apiService);
    });

/// Get message list state
@riverpod
MessageListState messageListState(MessageListStateRef ref) {
  return ref.watch(messageListProvider);
}

/// Get active chat messages
@riverpod
List<Message> activeMessages(ActiveMessagesRef ref) {
  return ref.watch(messageListStateProvider).activeMessages;
}

/// Get message by ID
@riverpod
Message? messageById(MessageByIdRef ref, String chatId, String messageId) {
  final messages =
      ref.watch(messageListStateProvider).messagesByChat[chatId] ?? [];
  try {
    return messages.firstWhere((m) => m.id == messageId);
  } catch (e) {
    return null;
  }
}

/// Check if message is from current user
@riverpod
bool isOwnMessage(IsOwnMessageRef ref, String senderId) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.id == senderId;
}
