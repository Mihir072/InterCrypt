/// Types of tracked activity on a message/file
enum ActivityEventType {
  sent,
  delivered,
  opened,
  downloaded,
  screenshot,
  denied;

  /// Get a user-friendly display name
  String get displayName {
    switch (this) {
      case ActivityEventType.sent:
        return 'Sent';
      case ActivityEventType.delivered:
        return 'Delivered';
      case ActivityEventType.opened:
        return 'Opened';
      case ActivityEventType.downloaded:
        return 'Downloaded';
      case ActivityEventType.screenshot:
        return 'Screenshot Detected';
      case ActivityEventType.denied:
        return 'Access Denied';
    }
  }
}

ActivityEventType _parseEventType(String? type) {
  return ActivityEventType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => ActivityEventType.sent,
  );
}

/// A log entry for an action performed on a message or its contents
class ActivityEvent {
  final ActivityEventType eventType;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic>? metadata;

  const ActivityEvent({
    required this.eventType,
    required this.timestamp,
    required this.userId,
    this.metadata,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      eventType: _parseEventType(json['eventType'] as String?),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      userId: json['userId'] as String? ?? 'Unknown',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.name,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }
  
  ActivityEvent copyWith({
    ActivityEventType? eventType,
    DateTime? timestamp,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityEvent(
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }
}
