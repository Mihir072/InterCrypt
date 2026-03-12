import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

part 'chat_provider.g.dart';

/// Chat list state
class ChatListState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int totalUnread;
  final DateTime? lastFetch;

  const ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.totalUnread = 0,
    this.lastFetch,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? totalUnread,
    DateTime? lastFetch,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      totalUnread: totalUnread ?? this.totalUnread,
      lastFetch: lastFetch ?? this.lastFetch,
    );
  }

  List<Chat> get filteredChats {
    if (searchQuery.isEmpty) return chats;

    return chats
        .where(
          (chat) =>
              chat.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              chat.participants.any(
                (p) => p.username.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              ),
        )
        .toList();
  }
}

/// Chat List Notifier
class ChatListNotifier extends StateNotifier<ChatListState> {
  final ApiService _apiService;
  final Ref _ref;
  Timer? _pollingTimer;

  /// Previous unread counts keyed by chatId (for detecting new messages)
  final Map<String, int> _previousUnread = {};

  ChatListNotifier(this._apiService, this._ref) : super(const ChatListState()) {
    // Fetch immediately on init
    fetchChats();
    // Poll every 60 seconds as a fallback — WebSocket handles real-time delivery
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => fetchChats(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Fetch all chats and emit in-app notifications for new messages
  Future<void> fetchChats() async {
    try {
      // Only show the loading spinner on first load (when chats list is empty)
      if (state.chats.isEmpty) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final chats = await _apiService.getChats();

      final totalUnread = chats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );

      // Detect which chats have gained new unread messages since last poll
      final activeChatId = _ref.read(selectedChatProvider);
      for (final chat in chats) {
        final prev = _previousUnread[chat.id] ?? 0;
        if (chat.unreadCount > prev && chat.id != activeChatId) {
          // New messages arrived — push an in-app notification
          _ref
              .read(notificationProvider.notifier)
              .show(
                InAppNotification(
                  id: '${chat.id}_${DateTime.now().millisecondsSinceEpoch}',
                  chatId: chat.id,
                  chatName: chat.name,
                  previewText: '🔒 New encrypted message',
                  timestamp: DateTime.now(),
                ),
              );
        }
        _previousUnread[chat.id] = chat.unreadCount;
      }

      state = ChatListState(
        chats: chats,
        isLoading: false,
        totalUnread: totalUnread,
        lastFetch: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create direct chat
  Future<Chat?> createDirectChat(String userId) async {
    try {
      state = state.copyWith(isLoading: true);

      final chat = await _apiService.createDirectChat(userId);

      final updatedChats = [chat, ...state.chats];
      state = state.copyWith(chats: updatedChats, isLoading: false);

      return chat;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Create group chat
  Future<Chat?> createGroupChat({
    required String name,
    required List<String> participantIds,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final chat = await _apiService.createGroupChat(
        name: name,
        participantIds: participantIds,
        description: description,
      );

      final updatedChats = [chat, ...state.chats];
      state = state.copyWith(chats: updatedChats, isLoading: false);

      return chat;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Archive chat
  Future<bool> archiveChat(String chatId) async {
    try {
      await _apiService.archiveChat(chatId);

      final updatedChats = state.chats
          .map(
            (chat) =>
                chat.id == chatId ? chat.copyWith(isArchived: true) : chat,
          )
          .toList();

      state = state.copyWith(chats: updatedChats);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unarchive chat
  Future<bool> unarchiveChat(String chatId) async {
    try {
      await _apiService.unarchiveChat(chatId);

      final updatedChats = state.chats
          .map(
            (chat) =>
                chat.id == chatId ? chat.copyWith(isArchived: false) : chat,
          )
          .toList();

      state = state.copyWith(chats: updatedChats);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Mute chat
  Future<bool> muteChat(String chatId, {Duration? duration}) async {
    try {
      await _apiService.muteChat(chatId, duration: duration);

      final updatedChats = state.chats
          .map(
            (chat) => chat.id == chatId ? chat.copyWith(isMuted: true) : chat,
          )
          .toList();

      state = state.copyWith(chats: updatedChats);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unmute chat
  Future<bool> unmuteChat(String chatId) async {
    try {
      await _apiService.unmuteChat(chatId);

      final updatedChats = state.chats
          .map(
            (chat) => chat.id == chatId ? chat.copyWith(isMuted: false) : chat,
          )
          .toList();

      state = state.copyWith(chats: updatedChats);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete chat
  Future<bool> deleteChat(String chatId) async {
    try {
      await _apiService.deleteChat(chatId);

      final updatedChats = state.chats.where((c) => c.id != chatId).toList();
      state = state.copyWith(chats: updatedChats);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Chat list provider - use manual StateNotifierProvider for proper .notifier access
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>(
  (ref) {
    final apiService = ref.watch(apiServiceProvider);
    return ChatListNotifier(apiService, ref);
  },
);

/// Get chat list state (watches the provider)
@riverpod
ChatListState chatListState(ChatListStateRef ref) {
  return ref.watch(chatListProvider);
}

/// Get filtered chats
@riverpod
List<Chat> filteredChats(FilteredChatsRef ref) {
  return ref.watch(chatListStateProvider).filteredChats;
}

/// Get total unread count
@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  return ref.watch(chatListStateProvider).totalUnread;
}

/// Get specific chat by ID
@riverpod
Chat? chatById(ChatByIdRef ref, String chatId) {
  final chats = ref.watch(chatListStateProvider).chats;
  try {
    return chats.firstWhere((chat) => chat.id == chatId);
  } catch (e) {
    return null;
  }
}

/// Selected chat ID provider for managing current chat selection
final selectedChatProvider = StateProvider<String?>((ref) => null);
