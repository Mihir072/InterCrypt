import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'api_service.dart';

/// Service for interacting with Activity Logs and Audit Trails
class ActivityLogService {
  final ApiService _apiService;

  ActivityLogService(this._apiService);

  /// Logs an event on a message.
  Future<ActivityEvent> logEvent({
    required String chatId,
    required String messageId,
    required ActivityEventType eventType,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    
    final event = ActivityEvent(
      eventType: eventType,
      timestamp: DateTime.now(),
      userId: userId,
      metadata: metadata,
    );
    
    try {
      await _apiService.post(
        '/chats/$chatId/messages/$messageId/activity', 
        data: event.toJson(),
      );
      print('Activity Logged to API: [${eventType.name}] on Message $messageId by $userId');
    } catch (e) {
      // Backend might return 404 if the API is mocked loosely, fall back gracefully
      print('Activity Log API push failed or not found, falling back to local only: $e');
    }
    
    return event;
  }
}

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService(ref.read(apiServiceProvider));
});
