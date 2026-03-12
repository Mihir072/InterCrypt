import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../config/app_config.dart';
import '../providers/chat_provider.dart';
import 'notification_service.dart';

// ---------------------------------------------------------------------------
// Derive ws:// URL for the raw WebSocket endpoint (mobile-compatible)
//   http://192.168.0.103:8443/api  →  ws://192.168.0.103:8443/ws-native
// ---------------------------------------------------------------------------
String get _wsUrl {
  return AppConfig.apiBaseUrl
      .replaceFirst(RegExp(r'^http'), 'ws')
      .replaceFirst(RegExp(r'/api$'), '/ws-native');
}

// ---------------------------------------------------------------------------
// WebSocket connection state
// ---------------------------------------------------------------------------
class WebSocketState {
  final bool connected;
  final String? error;
  const WebSocketState({this.connected = false, this.error});
  WebSocketState copyWith({bool? connected, String? error}) =>
      WebSocketState(connected: connected ?? this.connected, error: error);
}

// ---------------------------------------------------------------------------
// Main provider
// ---------------------------------------------------------------------------
final webSocketServiceProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>(
      (ref) => WebSocketNotifier(ref),
    );

// ---------------------------------------------------------------------------
// Notifier — owns the StompClient lifecycle
// ---------------------------------------------------------------------------
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final Ref _ref;
  StompClient? _client;

  WebSocketNotifier(this._ref) : super(const WebSocketState());

  // ── Connect ──────────────────────────────────────────────

  void connect(String jwtToken, String currentUserId) {
    if (_client != null && (_client!.connected)) return; // already up
    _client?.deactivate();

    // ignore: prefer_const_constructors
    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $jwtToken'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $jwtToken'},
        onConnect: (frame) => _onConnected(frame, currentUserId),
        onDisconnect: (_) {
          if (mounted) state = state.copyWith(connected: false);
        },
        onStompError: (frame) {
          if (mounted) {
            state = state.copyWith(connected: false, error: frame.body);
          }
        },
        onWebSocketError: (error) {
          if (mounted) {
            state = state.copyWith(connected: false, error: error.toString());
          }
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    if (mounted) state = const WebSocketState();
  }

  // ── Internal callbacks ────────────────────────────────────

  void _onConnected(StompFrame frame, String currentUserId) {
    if (!mounted) return;
    state = state.copyWith(connected: true, error: null);

    // Subscribe to the user's private queue
    // Backend calls: convertAndSendToUser(recipientId, "/queue/messages", ...)
    // STOMP resolves that to:  /user/queue/messages  for this client
    _client!.subscribe(
      destination: '/user/queue/messages',
      callback: (f) => _onMessage(f, currentUserId),
    );
  }

  void _onMessage(StompFrame frame, String currentUserId) {
    if (frame.body == null || !mounted) return;
    try {
      final data = json.decode(frame.body!) as Map<String, dynamic>;
      final senderId = (data['senderId'] as String?) ?? '';
      if (senderId == currentUserId) return; // don't notify own messages

      final chatId = (data['chatId'] as String?) ?? '';
      final senderUsername = (data['senderUsername'] as String?) ?? 'Someone';

      // Forward to the open-chat live stream (ChatMessageScreen subscribes)
      _ref.read(incomingMessageNotifierProvider.notifier).emit(data);

      // Show banner if user is NOT currently in this chat
      final activeChatId = _ref.read(selectedChatProvider);
      if (activeChatId != chatId) {
        _ref
            .read(notificationProvider.notifier)
            .show(
              InAppNotification(
                id: '${chatId}_${DateTime.now().millisecondsSinceEpoch}',
                chatId: chatId,
                chatName: senderUsername,
                previewText: '🔒 New encrypted message',
                timestamp: DateTime.now(),
              ),
            );
        // Refresh chat list so unread badge updates
        _ref.read(chatListProvider.notifier).fetchChats();
      }
    } catch (_) {
      // Malformed payload — silently ignore
    }
  }

  @override
  void dispose() {
    _client?.deactivate();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Incoming-message stream — ChatMessageScreen watches this for live updates
// ---------------------------------------------------------------------------
class IncomingMessageNotifier extends StateNotifier<Map<String, dynamic>?> {
  IncomingMessageNotifier() : super(null);
  void emit(Map<String, dynamic> data) {
    if (mounted) state = data;
  }
}

final incomingMessageNotifierProvider =
    StateNotifierProvider<IncomingMessageNotifier, Map<String, dynamic>?>(
      (_) => IncomingMessageNotifier(),
    );

/// Read-only alias consumed by ChatMessageScreen.
final incomingMessageProvider = Provider<Map<String, dynamic>?>(
  (ref) => ref.watch(incomingMessageNotifierProvider),
);
