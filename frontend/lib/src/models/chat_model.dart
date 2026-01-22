import 'user_model.dart';

/// Chat/Conversation model
class Chat {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final ChatType type;
  final List<User> participants;
  final User createdBy;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final String classificationLevel;
  final List<String> allowedRoles;
  final ChatEncryption encryption;

  const Chat({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.type,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    required this.classificationLevel,
    required this.allowedRoles,
    required this.encryption,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Chat',
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      type: _parseChatType(json['type'] as String?),
      participants:
          (json['participants'] as List?)
              ?.map((p) => User.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] != null
          ? User.fromJson(json['createdBy'] as Map<String, dynamic>)
          : User.empty(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : DateTime.now(),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      classificationLevel:
          json['classificationLevel'] as String? ?? 'UNCLASSIFIED',
      allowedRoles: List<String>.from(json['allowedRoles'] as List? ?? []),
      encryption: json['encryption'] != null
          ? ChatEncryption.fromJson(json['encryption'] as Map<String, dynamic>)
          : ChatEncryption.defaultEncryption(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'type': type.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'classificationLevel': classificationLevel,
      'allowedRoles': allowedRoles,
      'encryption': encryption.toJson(),
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    ChatType? type,
    List<User>? participants,
    User? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    String? classificationLevel,
    List<String>? allowedRoles,
    ChatEncryption? encryption,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      classificationLevel: classificationLevel ?? this.classificationLevel,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      encryption: encryption ?? this.encryption,
    );
  }

  bool get isGroup => type == ChatType.group;
  bool get isPrivate => type == ChatType.direct;
  String get displayName => name.isEmpty ? 'Chat' : name;
  String get maskedPreview =>
      lastMessagePreview != null ? '[Encrypted Message]' : '';

  /// Get the other participant in a direct chat
  User? getOtherParticipant(String currentUserId) {
    if (type != ChatType.direct) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : User.empty(),
    );
  }

  /// Get display name for chat (shows other participant's name in direct chats)
  String getDisplayName(String? currentUserId) {
    if (type == ChatType.direct && currentUserId != null) {
      final otherUser = getOtherParticipant(currentUserId);
      return otherUser?.username ?? name;
    }
    return displayName;
  }
}

/// Chat type enumeration
enum ChatType {
  direct, // 1-to-1 conversation
  group, // Group chat
  channel, // Broadcast channel
  admin; // Admin-only communications

  bool get canHaveMultipleUsers =>
      this == group || this == channel || this == admin;
}

ChatType _parseChatType(String? type) {
  return ChatType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => ChatType.direct,
  );
}

/// Chat encryption configuration
class ChatEncryption {
  final String algorithm; // AES-256-GCM or Hybrid
  final String keyId;
  final String encryptionLevel; // LOW, MEDIUM, HIGH
  final bool isE2E;
  final List<String> participantKeyIds;
  final DateTime rotatedAt;

  const ChatEncryption({
    required this.algorithm,
    required this.keyId,
    required this.encryptionLevel,
    required this.isE2E,
    required this.participantKeyIds,
    required this.rotatedAt,
  });

  factory ChatEncryption.fromJson(Map<String, dynamic> json) {
    return ChatEncryption(
      algorithm: json['algorithm'] as String? ?? 'AES-256-GCM',
      keyId: json['keyId'] as String? ?? '',
      encryptionLevel: json['encryptionLevel'] as String? ?? 'HIGH',
      isE2E: json['isE2E'] as bool? ?? true,
      participantKeyIds: List<String>.from(
        json['participantKeyIds'] as List? ?? [],
      ),
      rotatedAt: json['rotatedAt'] != null
          ? DateTime.parse(json['rotatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create default encryption settings
  factory ChatEncryption.defaultEncryption() {
    return ChatEncryption(
      algorithm: 'AES-256-GCM',
      keyId: '',
      encryptionLevel: 'HIGH',
      isE2E: true,
      participantKeyIds: [],
      rotatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'keyId': keyId,
      'encryptionLevel': encryptionLevel,
      'isE2E': isE2E,
      'participantKeyIds': participantKeyIds,
      'rotatedAt': rotatedAt.toIso8601String(),
    };
  }
}
