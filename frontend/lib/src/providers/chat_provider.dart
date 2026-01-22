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

  ChatListNotifier(this._apiService) : super(const ChatListState()) {
    // Automatically fetch chats on initialization
    fetchChats();
  }

  /// Fetch all chats
  Future<void> fetchChats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final chats = await _apiService.getChats();

      final totalUnread = chats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );

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
    return ChatListNotifier(apiService);
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
