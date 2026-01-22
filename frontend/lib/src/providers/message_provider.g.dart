// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageListStateHash() => r'1670374f42bc30b0ee91266e01db982364065e62';

/// Get message list state
///
/// Copied from [messageListState].
@ProviderFor(messageListState)
final messageListStateProvider = AutoDisposeProvider<MessageListState>.internal(
  messageListState,
  name: r'messageListStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageListStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MessageListStateRef = AutoDisposeProviderRef<MessageListState>;
String _$activeMessagesHash() => r'451febc5ecb8a4e007103f82e6f900543caaa9cf';

/// Get active chat messages
///
/// Copied from [activeMessages].
@ProviderFor(activeMessages)
final activeMessagesProvider = AutoDisposeProvider<List<Message>>.internal(
  activeMessages,
  name: r'activeMessagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveMessagesRef = AutoDisposeProviderRef<List<Message>>;
String _$messageByIdHash() => r'2000755145d5015cedc48a1369088d1d34b1db55';

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

/// Get message by ID
///
/// Copied from [messageById].
@ProviderFor(messageById)
const messageByIdProvider = MessageByIdFamily();

/// Get message by ID
///
/// Copied from [messageById].
class MessageByIdFamily extends Family<Message?> {
  /// Get message by ID
  ///
  /// Copied from [messageById].
  const MessageByIdFamily();

  /// Get message by ID
  ///
  /// Copied from [messageById].
  MessageByIdProvider call(
    String chatId,
    String messageId,
  ) {
    return MessageByIdProvider(
      chatId,
      messageId,
    );
  }

  @override
  MessageByIdProvider getProviderOverride(
    covariant MessageByIdProvider provider,
  ) {
    return call(
      provider.chatId,
      provider.messageId,
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
  String? get name => r'messageByIdProvider';
}

/// Get message by ID
///
/// Copied from [messageById].
class MessageByIdProvider extends AutoDisposeProvider<Message?> {
  /// Get message by ID
  ///
  /// Copied from [messageById].
  MessageByIdProvider(
    String chatId,
    String messageId,
  ) : this._internal(
          (ref) => messageById(
            ref as MessageByIdRef,
            chatId,
            messageId,
          ),
          from: messageByIdProvider,
          name: r'messageByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messageByIdHash,
          dependencies: MessageByIdFamily._dependencies,
          allTransitiveDependencies:
              MessageByIdFamily._allTransitiveDependencies,
          chatId: chatId,
          messageId: messageId,
        );

  MessageByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
    required this.messageId,
  }) : super.internal();

  final String chatId;
  final String messageId;

  @override
  Override overrideWith(
    Message? Function(MessageByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessageByIdProvider._internal(
        (ref) => create(ref as MessageByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
        messageId: messageId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Message?> createElement() {
    return _MessageByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageByIdProvider &&
        other.chatId == chatId &&
        other.messageId == messageId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);
    hash = _SystemHash.combine(hash, messageId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MessageByIdRef on AutoDisposeProviderRef<Message?> {
  /// The parameter `chatId` of this provider.
  String get chatId;

  /// The parameter `messageId` of this provider.
  String get messageId;
}

class _MessageByIdProviderElement extends AutoDisposeProviderElement<Message?>
    with MessageByIdRef {
  _MessageByIdProviderElement(super.provider);

  @override
  String get chatId => (origin as MessageByIdProvider).chatId;
  @override
  String get messageId => (origin as MessageByIdProvider).messageId;
}

String _$isOwnMessageHash() => r'ca979a6ce340abd606763c54b36c6f7bb8e8d1f5';

/// Check if message is from current user
///
/// Copied from [isOwnMessage].
@ProviderFor(isOwnMessage)
const isOwnMessageProvider = IsOwnMessageFamily();

/// Check if message is from current user
///
/// Copied from [isOwnMessage].
class IsOwnMessageFamily extends Family<bool> {
  /// Check if message is from current user
  ///
  /// Copied from [isOwnMessage].
  const IsOwnMessageFamily();

  /// Check if message is from current user
  ///
  /// Copied from [isOwnMessage].
  IsOwnMessageProvider call(
    String senderId,
  ) {
    return IsOwnMessageProvider(
      senderId,
    );
  }

  @override
  IsOwnMessageProvider getProviderOverride(
    covariant IsOwnMessageProvider provider,
  ) {
    return call(
      provider.senderId,
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
  String? get name => r'isOwnMessageProvider';
}

/// Check if message is from current user
///
/// Copied from [isOwnMessage].
class IsOwnMessageProvider extends AutoDisposeProvider<bool> {
  /// Check if message is from current user
  ///
  /// Copied from [isOwnMessage].
  IsOwnMessageProvider(
    String senderId,
  ) : this._internal(
          (ref) => isOwnMessage(
            ref as IsOwnMessageRef,
            senderId,
          ),
          from: isOwnMessageProvider,
          name: r'isOwnMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isOwnMessageHash,
          dependencies: IsOwnMessageFamily._dependencies,
          allTransitiveDependencies:
              IsOwnMessageFamily._allTransitiveDependencies,
          senderId: senderId,
        );

  IsOwnMessageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.senderId,
  }) : super.internal();

  final String senderId;

  @override
  Override overrideWith(
    bool Function(IsOwnMessageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsOwnMessageProvider._internal(
        (ref) => create(ref as IsOwnMessageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        senderId: senderId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsOwnMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsOwnMessageProvider && other.senderId == senderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, senderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IsOwnMessageRef on AutoDisposeProviderRef<bool> {
  /// The parameter `senderId` of this provider.
  String get senderId;
}

class _IsOwnMessageProviderElement extends AutoDisposeProviderElement<bool>
    with IsOwnMessageRef {
  _IsOwnMessageProviderElement(super.provider);

  @override
  String get senderId => (origin as IsOwnMessageProvider).senderId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
