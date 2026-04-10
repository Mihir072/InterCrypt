import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

/// Screen to display the activity log (audit trail) of a specific message
class ActivityLogScreen extends ConsumerStatefulWidget {
  final Message message;

  const ActivityLogScreen({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  late Message _message;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  Future<void> _refresh() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      // Ensure backend supports this endpoint or gracefully handle it
      final updatedMessage = await apiService.getMessage(
        _message.chatId,
        _message.id,
      );
      
      if (mounted) {
        setState(() {
          _message = updatedMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh activity: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sort logs descending (newest first)
    final logs = List<ActivityEvent>.from(_message.activityLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));


    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Activity Log'),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.electricCyan,
        child: logs.isEmpty
            ? Stack(
                children: [
                  _buildEmptyState(isDark),
                  ListView(), // Required for RefreshIndicator to work when empty
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildTimelineItem(log, isDark, isLast: index == logs.length - 1);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Activity Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity on this document will appear here.',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ActivityEvent log, bool isDark, {required bool isLast}) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorForEventType(log.eventType).withOpacity(0.15),
                    border: Border.all(
                      color: _getColorForEventType(log.eventType),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _getIconForEventType(log.eventType),
                    size: 16,
                    color: _getColorForEventType(log.eventType),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.eventType.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.textPrimary : Colors.black87,
                        ),
                      ),
                      Text(
                        timeFormat.format(log.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${log.userId}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    dateFormat.format(log.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: log.metadata!.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForEventType(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.sent:
        return AppTheme.primaryBlue;
      case ActivityEventType.delivered:
        return AppTheme.electricCyan;
      case ActivityEventType.opened:
        return AppTheme.successGreen;
      case ActivityEventType.downloaded:
        return Colors.purpleAccent;
      case ActivityEventType.screenshot:
      case ActivityEventType.denied:
        return AppTheme.errorRed;
    }
  }

  IconData _getIconForEventType(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.sent:
        return Icons.send;
      case ActivityEventType.delivered:
        return Icons.done_all;
      case ActivityEventType.opened:
        return Icons.visibility;
      case ActivityEventType.downloaded:
        return Icons.file_download;
      case ActivityEventType.screenshot:
        return Icons.screenshot;
      case ActivityEventType.denied:
        return Icons.block;
    }
  }
}
