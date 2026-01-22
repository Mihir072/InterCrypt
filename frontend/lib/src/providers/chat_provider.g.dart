// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatListStateHash() => r'197c4b87f7938e32efe96e7ade73f30348799199';

/// Get chat list state (watches the provider)
///
/// Copied from [chatListState].
@ProviderFor(chatListState)
final chatListStateProvider = AutoDisposeProvider<ChatListState>.internal(
  chatListState,
  name: r'chatListStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatListStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ChatListStateRef = AutoDisposeProviderRef<ChatListState>;
String _$filteredChatsHash() => r'015015848b4182e65e1f753a569b5bf1a4b80195';

/// Get filtered chats
///
/// Copied from [filteredChats].
@ProviderFor(filteredChats)
final filteredChatsProvider = AutoDisposeProvider<List<Chat>>.internal(
  filteredChats,
  name: r'filteredChatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredChatsRef = AutoDisposeProviderRef<List<Chat>>;
String _$totalUnreadCountHash() => r'c4a49eb94b6e0a097c37fff07655bf00ab71c25d';

/// Get total unread count
///
/// Copied from [totalUnreadCount].
@ProviderFor(totalUnreadCount)
final totalUnreadCountProvider = AutoDisposeProvider<int>.internal(
  totalUnreadCount,
  name: r'totalUnreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalUnreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalUnreadCountRef = AutoDisposeProviderRef<int>;
String _$chatByIdHash() => r'0bfa2cd69c5a0cfb120949abd65763d1541119b5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Get specific chat by ID
///
/// Copied from [chatById].
@ProviderFor(chatById)
const chatByIdProvider = ChatByIdFamily();

/// Get specific chat by ID
///
/// Copied from [chatById].
class ChatByIdFamily extends Family<Chat?> {
  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
  const ChatByIdFamily();

  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
  ChatByIdProvider call(
    String chatId,
  ) {
    return ChatByIdProvider(
      chatId,
    );
  }

  @override
  ChatByIdProvider getProviderOverride(
    covariant ChatByIdProvider provider,
  ) {
    return call(
      provider.chatId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatByIdProvider';
}

/// Get specific chat by ID
///
/// Copied from [chatById].
class ChatByIdProvider extends AutoDisposeProvider<Chat?> {
  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
  ChatByIdProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatById(
            ref as ChatByIdRef,
            chatId,
          ),
          from: chatByIdProvider,
          name: r'chatByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatByIdHash,
          dependencies: ChatByIdFamily._dependencies,
          allTransitiveDependencies: ChatByIdFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  Override overrideWith(
    Chat? Function(ChatByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatByIdProvider._internal(
        (ref) => create(ref as ChatByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Chat?> createElement() {
    return _ChatByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatByIdProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatByIdRef on AutoDisposeProviderRef<Chat?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatByIdProviderElement extends AutoDisposeProviderElement<Chat?>
    with ChatByIdRef {
  _ChatByIdProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatByIdProvider).chatId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
