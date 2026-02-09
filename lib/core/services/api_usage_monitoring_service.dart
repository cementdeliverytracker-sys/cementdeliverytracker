/// API Usage Monitoring Service
/// Tracks Firestore reads/writes, geocoding calls, and cache performance
/// Provides insights for cost optimization and performance tuning

/// Singleton service for tracking API usage and cache performance
class APIUsageMonitoringService {
  static final APIUsageMonitoringService _instance =
      APIUsageMonitoringService._internal();

  // Firestore operation counters
  int _firestoreReads = 0;
  int _firestoreWrites = 0;
  int _firestoreDeletes = 0;
  int _firestoreTransactions = 0;
  int _firestoreBatchWrites = 0;

  // Geocoding API counters
  int _geocodingCalls = 0;

  // Location API counters
  int _locationUpdates = 0;

  // Session start time for rate calculations
  final DateTime _sessionStart = DateTime.now();

  // Detailed operation logs (limited to last N operations)
  static const int _maxLogEntries = 100;
  final List<_APIOperation> _operationLog = [];

  factory APIUsageMonitoringService() => _instance;

  APIUsageMonitoringService._internal();

  /// Record a Firestore read operation
  void recordFirestoreRead({String? collection, String? operation}) {
    _firestoreReads++;
    _logOperation(
      'firestore_read',
      collection: collection,
      operation: operation,
    );
  }

  /// Record a Firestore write operation
  void recordFirestoreWrite({String? collection, String? operation}) {
    _firestoreWrites++;
    _logOperation(
      'firestore_write',
      collection: collection,
      operation: operation,
    );
  }

  /// Record a Firestore delete operation
  void recordFirestoreDelete({String? collection, String? operation}) {
    _firestoreDeletes++;
    _logOperation(
      'firestore_delete',
      collection: collection,
      operation: operation,
    );
  }

  /// Record a Firestore transaction
  void recordFirestoreTransaction({String? operation}) {
    _firestoreTransactions++;
    _logOperation('firestore_transaction', operation: operation);
  }

  /// Record a Firestore batch write
  void recordFirestoreBatchWrite({int? operations}) {
    _firestoreBatchWrites++;
    _logOperation(
      'firestore_batch',
      operation: operations != null ? '$operations operations' : null,
    );
  }

  /// Record a geocoding API call
  void recordGeocodingCall({String? coordinates}) {
    _geocodingCalls++;
    _logOperation('geocoding_api', operation: coordinates);
  }

  /// Record a location update
  void recordLocationUpdate({String? source}) {
    _locationUpdates++;
    _logOperation('location_update', operation: source);
  }

  /// Log an operation with details
  void _logOperation(String type, {String? collection, String? operation}) {
    _operationLog.add(
      _APIOperation(
        type: type,
        timestamp: DateTime.now(),
        collection: collection,
        operation: operation,
      ),
    );

    // Keep log size limited
    if (_operationLog.length > _maxLogEntries) {
      _operationLog.removeAt(0);
    }
  }

  /// Get comprehensive API usage statistics
  Map<String, dynamic> getUsageStats() {
    final sessionDuration = DateTime.now().difference(_sessionStart);
    final sessionMinutes = sessionDuration.inMinutes;
    final sessionHours = sessionDuration.inHours;

    // Calculate rates
    final readsPerMinute = sessionMinutes > 0
        ? _firestoreReads / sessionMinutes
        : 0;
    final writesPerMinute = sessionMinutes > 0
        ? _firestoreWrites / sessionMinutes
        : 0.0;

    // Estimate monthly costs (rough estimates based on Firebase pricing)
    final estimatedMonthlyCost = _estimateMonthlyCost(
      readsPerMinute.toDouble(),
      writesPerMinute.toDouble(),
    );

    return {
      'firestore': {
        'reads': _firestoreReads,
        'writes': _firestoreWrites,
        'deletes': _firestoreDeletes,
        'transactions': _firestoreTransactions,
        'batchWrites': _firestoreBatchWrites,
        'totalOperations':
            _firestoreReads + _firestoreWrites + _firestoreDeletes,
        'readsPerMinute': readsPerMinute.toStringAsFixed(2),
        'writesPerMinute': writesPerMinute.toStringAsFixed(2),
      },
      'geocoding': {'calls': _geocodingCalls},
      'location': {'updates': _locationUpdates},
      'session': {
        'startTime': _sessionStart.toIso8601String(),
        'durationMinutes': sessionMinutes,
        'durationHours': sessionHours,
      },
      'costEstimate': estimatedMonthlyCost,
      'recentOperations': _getRecentOperations(20),
    };
  }

  /// Estimate monthly costs based on current usage
  Map<String, dynamic> _estimateMonthlyCost(
    double readsPerMinute,
    double writesPerMinute,
  ) {
    // Firebase pricing (as of 2024, subject to change):
    // Reads: $0.06 per 100,000 reads
    // Writes: $0.18 per 100,000 writes
    // Delete: $0.02 per 100,000 deletes

    final monthlyReads = readsPerMinute * 60 * 24 * 30;
    final monthlyWrites = writesPerMinute * 60 * 24 * 30;

    final readCost = (monthlyReads / 100000) * 0.06;
    final writeCost = (monthlyWrites / 100000) * 0.18;
    final totalCost = readCost + writeCost;

    return {
      'estimated': true,
      'monthlyReads': monthlyReads.toInt(),
      'monthlyWrites': monthlyWrites.toInt(),
      'readCost': '\$${readCost.toStringAsFixed(2)}',
      'writeCost': '\$${writeCost.toStringAsFixed(2)}',
      'totalMonthlyCost': '\$${totalCost.toStringAsFixed(2)}',
      'note': 'Based on current usage rate - may vary significantly',
    };
  }

  /// Get recent operations for debugging
  List<Map<String, dynamic>> _getRecentOperations(int count) {
    final recent = _operationLog.reversed.take(count).toList();
    return recent
        .map(
          (op) => {
            'type': op.type,
            'timestamp': op.timestamp.toIso8601String(),
            if (op.collection != null) 'collection': op.collection,
            if (op.operation != null) 'operation': op.operation,
          },
        )
        .toList();
  }

  /// Get operations grouped by type
  Map<String, int> getOperationsByType() {
    final counts = <String, int>{};

    for (final op in _operationLog) {
      counts[op.type] = (counts[op.type] ?? 0) + 1;
    }

    return counts;
  }

  /// Reset all counters (useful for interval monitoring)
  void resetCounters() {
    _firestoreReads = 0;
    _firestoreWrites = 0;
    _firestoreDeletes = 0;
    _firestoreTransactions = 0;
    _firestoreBatchWrites = 0;
    _geocodingCalls = 0;
    _locationUpdates = 0;
    _operationLog.clear();
  }

  /// Print usage summary to console (useful for debugging)
  void printUsageSummary() {
    final stats = getUsageStats();
    print('═══════════════════════════════════════════════════════════');
    print('API Usage Summary');
    print('═══════════════════════════════════════════════════════════');
    print('Firestore Operations:');
    print('  Reads: ${stats['firestore']['reads']}');
    print('  Writes: ${stats['firestore']['writes']}');
    print('  Deletes: ${stats['firestore']['deletes']}');
    print('  Transactions: ${stats['firestore']['transactions']}');
    print('  Batch Writes: ${stats['firestore']['batchWrites']}');
    print('');
    print('Geocoding API Calls: ${stats['geocoding']['calls']}');
    print('Location Updates: ${stats['location']['updates']}');
    print('');
    print('Session Duration: ${stats['session']['durationMinutes']} minutes');
    print('');
    print(
      'Estimated Monthly Cost: ${stats['costEstimate']['totalMonthlyCost']}',
    );
    print('═══════════════════════════════════════════════════════════');
  }
}

/// Internal class for logging API operations
class _APIOperation {
  final String type;
  final DateTime timestamp;
  final String? collection;
  final String? operation;

  _APIOperation({
    required this.type,
    required this.timestamp,
    this.collection,
    this.operation,
  });
}
