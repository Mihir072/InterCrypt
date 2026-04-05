/// Message model for encrypted chat
import 'activity_event.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String content;
  final String contentEncrypted; // Base64 encoded encrypted content
  final MessageEncryption encryption;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final List<MessageAttachment> attachments;
  final bool isEdited;
  final bool isSelfDestructing;
  final List<ActivityEvent> activityLogs;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.contentEncrypted,
    required this.encryption,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.expiresAt,
    required this.attachments,
    this.isEdited = false,
    this.isSelfDestructing = false,
    this.activityLogs = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderUsername: json['senderUsername'] as String? ?? 'Unknown',
      content: json['content'] as String? ?? '[Encrypted]',
      contentEncrypted: json['contentEncrypted'] as String? ?? '',
      encryption: json['encryption'] != null
          ? MessageEncryption.fromJson(
              json['encryption'] as Map<String, dynamic>,
            )
          : MessageEncryption.defaultEncryption(),
      status: _parseMessageStatus(json['status'] as String?),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      attachments:
          (json['attachments'] as List?)
              ?.map(
                (a) => MessageAttachment.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isEdited: json['isEdited'] as bool? ?? false,
      isSelfDestructing: json['isSelfDestructing'] as bool? ?? false,
      activityLogs: (json['activityLogs'] as List?)
              ?.map(
                (a) => ActivityEvent.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'content': content,
      'contentEncrypted': contentEncrypted,
      'encryption': encryption.toJson(),
      'status': status.name,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'isEdited': isEdited,
      'isSelfDestructing': isSelfDestructing,
      'activityLogs': activityLogs.map((a) => a.toJson()).toList(),
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderUsername,
    String? content,
    String? contentEncrypted,
    MessageEncryption? encryption,
    MessageStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? expiresAt,
    List<MessageAttachment>? attachments,
    bool? isEdited,
    bool? isSelfDestructing,
    List<ActivityEvent>? activityLogs,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      content: content ?? this.content,
      contentEncrypted: contentEncrypted ?? this.contentEncrypted,
      encryption: encryption ?? this.encryption,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      attachments: attachments ?? this.attachments,
      isEdited: isEdited ?? this.isEdited,
      isSelfDestructing: isSelfDestructing ?? this.isSelfDestructing,
      activityLogs: activityLogs ?? this.activityLogs,
    );
  }
}

/// Encryption metadata for messages
class MessageEncryption {
  final String algorithm; // AES-256-GCM, Hybrid
  final String keyId;
  final String encryptionLevel; // LOW, MEDIUM, HIGH
  final bool isE2E;
  final DateTime encryptedAt;

  const MessageEncryption({
    required this.algorithm,
    required this.keyId,
    required this.encryptionLevel,
    required this.isE2E,
    required this.encryptedAt,
  });

  factory MessageEncryption.defaultEncryption() {
    return MessageEncryption(
      algorithm: 'AES-256-GCM',
      keyId: '',
      encryptionLevel: 'HIGH',
      isE2E: true,
      encryptedAt: DateTime.now(),
    );
  }

  factory MessageEncryption.fromJson(Map<String, dynamic> json) {
    return MessageEncryption(
      algorithm: json['algorithm'] as String? ?? 'AES-256-GCM',
      keyId: json['keyId'] as String? ?? '',
      encryptionLevel: json['encryptionLevel'] as String? ?? 'HIGH',
      isE2E: json['isE2E'] as bool? ?? true,
      encryptedAt: json['encryptedAt'] != null
          ? DateTime.parse(json['encryptedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'keyId': keyId,
      'encryptionLevel': encryptionLevel,
      'isE2E': isE2E,
      'encryptedAt': encryptedAt.toIso8601String(),
    };
  }
}

/// Message attachment model
class MessageAttachment {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;
  final String? thumbnailUrl;
  final String encryptionKeyId;
  final bool hasHiddenData;
  
  // Location-Based Access Control
  final bool locationRestrictionEnabled;
  final double? restrictedLatitude;
  final double? restrictedLongitude;
  final double? allowedRadius; // in meters
  final String? locationLabel;

  const MessageAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.encryptionKeyId,
    this.hasHiddenData = false,
    this.locationRestrictionEnabled = false,
    this.restrictedLatitude,
    this.restrictedLongitude,
    this.allowedRadius,
    this.locationLabel,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'unknown',
      fileType: json['fileType']?.toString() ?? 'unknown',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      encryptionKeyId: json['encryptionKeyId']?.toString() ?? 'default',
      hasHiddenData: json['hasHiddenData'] as bool? ?? false,
      locationRestrictionEnabled: json['locationRestrictionEnabled'] as bool? ?? false,
      restrictedLatitude: (json['restrictedLatitude'] as num?)?.toDouble(),
      restrictedLongitude: (json['restrictedLongitude'] as num?)?.toDouble(),
      allowedRadius: (json['allowedRadius'] as num?)?.toDouble(),
      locationLabel: json['locationLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'encryptionKeyId': encryptionKeyId,
      'hasHiddenData': hasHiddenData,
      'locationRestrictionEnabled': locationRestrictionEnabled,
      'restrictedLatitude': restrictedLatitude,
      'restrictedLongitude': restrictedLongitude,
      'allowedRadius': allowedRadius,
      'locationLabel': locationLabel,
    };
  }
}

/// Message delivery status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
  archived;

  bool get isFinal =>
      this == sent ||
      this == delivered ||
      this == read ||
      this == failed ||
      this == archived;
  bool get isDelivered => this == delivered || this == read;
  bool get isRead => this == read;
}

MessageStatus _parseMessageStatus(String? status) {
  return MessageStatus.values.firstWhere(
    (e) => e.name == status,
    orElse: () => MessageStatus.sent,
  );
}
