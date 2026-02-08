/// Task types performed during a visit
enum TaskType {
  collectMoney('collect_money', 'Collect Money'),
  takeOrder('take_order', 'Take Order'),
  other('other', 'Other Task');

  final String code;
  final String displayName;

  const TaskType(this.code, this.displayName);

  factory TaskType.fromCode(String code) {
    return TaskType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TaskType.other,
    );
  }
}

/// Task logged during a visit
class VisitTask {
  final String id;
  final String visitId;
  final TaskType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>?
  metadata; // Amount for collectMoney, order details, etc.

  VisitTask({
    required this.id,
    required this.visitId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  /// Convert VisitTask to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'visitId': visitId,
      'type': type.code,
      'description': description,
      'timestamp': timestamp,
      'metadata': metadata ?? {},
    };
  }

  /// Create VisitTask from Firestore JSON
  factory VisitTask.fromFirestore(Map<String, dynamic> data) {
    return VisitTask(
      id: data['id'] as String,
      visitId: data['visitId'] as String,
      type: TaskType.fromCode(data['type'] as String? ?? 'other'),
      description: data['description'] as String,
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'VisitTask(id: $id, type: $type, timestamp: $timestamp)';
}

/// Visit model representing an employee's visit to a distributor
class Visit {
  final String id;
  final String employeeId;
  final String distributorId;
  final String distributorName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLat;
  final double checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final double checkInAccuracy;
  final double? checkOutAccuracy;
  final List<VisitTask> tasks;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    required this.id,
    required this.employeeId,
    required this.distributorId,
    required this.distributorName,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLat,
    required this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    required this.checkInAccuracy,
    this.checkOutAccuracy,
    this.tasks = const [],
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get duration of visit
  Duration get duration {
    if (checkOutTime == null) {
      return DateTime.now().difference(checkInTime);
    }
    return checkOutTime!.difference(checkInTime);
  }

  /// Get duration in minutes
  int get durationMinutes => duration.inMinutes;

  /// Check if visit is active
  bool get isActive => !isCompleted && checkOutTime == null;

  /// Convert Visit to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'employeeId': employeeId,
      'distributorId': distributorId,
      'distributorName': distributorName,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'checkInLocation': {
        'latitude': checkInLat,
        'longitude': checkInLng,
        'accuracy': checkInAccuracy,
      },
      'checkOutLocation': checkOutLat != null
          ? {
              'latitude': checkOutLat,
              'longitude': checkOutLng,
              'accuracy': checkOutAccuracy,
            }
          : null,
      'tasks': tasks.map((t) => t.toFirestore()).toList(),
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create Visit from Firestore JSON
  factory Visit.fromFirestore(Map<String, dynamic> data) {
    final checkInLoc = (data['checkInLocation'] as Map<String, dynamic>?) ?? {};
    final checkOutLoc = (data['checkOutLocation'] as Map<String, dynamic>?);
    final tasksList =
        (data['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Visit(
      id: data['id'] as String,
      employeeId: data['employeeId'] as String,
      distributorId: data['distributorId'] as String,
      distributorName: data['distributorName'] as String,
      checkInTime: (data['checkInTime'] as dynamic)?.toDate() ?? DateTime.now(),
      checkOutTime: data['checkOutTime'] != null
          ? (data['checkOutTime'] as dynamic).toDate()
          : null,
      checkInLat: (checkInLoc['latitude'] as num?)?.toDouble() ?? 0.0,
      checkInLng: (checkInLoc['longitude'] as num?)?.toDouble() ?? 0.0,
      checkOutLat: (checkOutLoc?['latitude'] as num?)?.toDouble(),
      checkOutLng: (checkOutLoc?['longitude'] as num?)?.toDouble(),
      checkInAccuracy: (checkInLoc['accuracy'] as num?)?.toDouble() ?? 0.0,
      checkOutAccuracy: (checkOutLoc?['accuracy'] as num?)?.toDouble(),
      tasks: tasksList.map((t) => VisitTask.fromFirestore(t)).toList(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy with optional fields updated
  Visit copyWith({
    String? id,
    String? employeeId,
    String? distributorId,
    String? distributorName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
    double? checkInAccuracy,
    double? checkOutAccuracy,
    List<VisitTask>? tasks,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      distributorId: distributorId ?? this.distributorId,
      distributorName: distributorName ?? this.distributorName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      checkInAccuracy: checkInAccuracy ?? this.checkInAccuracy,
      checkOutAccuracy: checkOutAccuracy ?? this.checkOutAccuracy,
      tasks: tasks ?? this.tasks,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Visit(id: $id, distributorId: $distributorId, isActive: $isActive)';
}
