/// Debouncer utility class for throttling rapid function calls
/// Useful for reducing API calls during user interactions like:
/// - Map location selection
/// - Search input
/// - Location tracking updates

import 'dart:async';
import 'dart:ui';

/// Debouncer delays function execution until after wait time has elapsed
/// since the last time it was invoked
class Debouncer {
  final Duration delay;
  Timer? _timer;
  VoidCallback? _action;

  Debouncer({required this.delay});

  /// Call this method to debounce the action
  void call(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, _executeAction);
  }

  void _executeAction() {
    _action?.call();
    _action = null;
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _action = null;
  }
}

/// Throttler ensures function is called at most once per specified duration
/// Useful for rate-limiting frequent events like location updates
class Throttler {
  final Duration duration;
  DateTime? _lastExecutionTime;
  Timer? _timer;

  Throttler({required this.duration});

  /// Call this method to throttle the action
  /// Returns true if action was executed, false if throttled
  bool call(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
      return true;
    }

    return false;
  }

  /// Execute action with trailing call support
  /// If throttled, schedules execution after duration
  void callWithTrailing(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
      _timer?.cancel();
    } else {
      // Schedule trailing call
      _timer?.cancel();
      final remaining = duration - now.difference(_lastExecutionTime!);
      _timer = Timer(remaining, () {
        _lastExecutionTime = DateTime.now();
        action();
      });
    }
  }

  /// Reset throttler state
  void reset() {
    _lastExecutionTime = null;
    _timer?.cancel();
  }

  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
