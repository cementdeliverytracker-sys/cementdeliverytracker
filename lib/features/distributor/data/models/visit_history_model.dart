import 'visit_model.dart';

/// Visit history summary for display purposes
class VisitHistory {
  final Visit visit;
  final int taskCount;
  final int completedTaskCount;
  final String durationDisplay;

  VisitHistory({
    required this.visit,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    required this.durationDisplay,
  });

  /// Get status string for display
  String get statusDisplay {
    if (visit.isCompleted) {
      return 'Completed - ${visit.durationMinutes} min';
    }
    if (visit.isActive) {
      return 'In Progress - ${visit.durationMinutes} min';
    }
    return 'Inactive';
  }

  /// Get tasks summary
  String get tasksSummary {
    if (visit.tasks.isEmpty) {
      return 'No tasks';
    }
    return '${visit.tasks.length} task${visit.tasks.length > 1 ? 's' : ''}';
  }

  /// Format check-in time
  String get checkInTimeDisplay {
    return _formatTime(visit.checkInTime);
  }

  /// Format check-out time
  String? get checkOutTimeDisplay {
    return visit.checkOutTime != null ? _formatTime(visit.checkOutTime!) : null;
  }

  /// Helper to format time as HH:MM AM/PM
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  String toString() =>
      'VisitHistory(distributorId: ${visit.distributorId}, status: $statusDisplay)';
}
