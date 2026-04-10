import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'api_service.dart';

/// Service for interacting with Activity Logs and Audit Trails.
///
/// Activity events are stored locally on the Message model (via copyWith in
/// the calling screen). They are also pushed to the backend as a best-effort
/// fire-and-forget — a 404 / network failure is silently ignored so it never
/// blocks the UI.
class ActivityLogService {
  final ApiService _apiService;

  ActivityLogService(this._apiService);

  /// Creates a local [ActivityEvent] and optionally persists it server-side.
  /// Always returns the event immediately so the caller can update local state.
  Future<ActivityEvent> logEvent({
    required String chatId,
    required String messageId,
    required ActivityEventType eventType,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    // Build the local event — source of truth for ActivityLogScreen.
    final event = ActivityEvent(
      eventType: eventType,
      timestamp: DateTime.now(),
      userId: userId,
      metadata: metadata,
    );

    // Best-effort server push (fire-and-forget, never throws).
    _pushToBackend(chatId, messageId, event);

    return event;
  }

  /// Fire-and-forget — any error is swallowed; does NOT block the caller.
  void _pushToBackend(String chatId, String messageId, ActivityEvent event) {
    _apiService
        .post('/chats/$chatId/messages/$messageId/activity', data: event.toJson())
        .then((_) => print('Activity logged to API: [${event.eventType.name}]'))
        .catchError((e) => print('Activity push skipped (backend unavailable): $e'));
  }
}

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService(ref.read(apiServiceProvider));
});

