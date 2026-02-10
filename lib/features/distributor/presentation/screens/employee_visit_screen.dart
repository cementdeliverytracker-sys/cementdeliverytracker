import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/distributor_model.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/distributor_repository.dart';
import '../widgets/distributor_selector_widget.dart';
import '../widgets/visit_status_widget.dart';
import '../widgets/task_logging_widget.dart';
import '../widgets/visit_history_widget.dart';
import '../../../dashboard/presentation/screens/employee_add_distributor_dialog.dart';

/// Main screen for employee distributor visit tracking
class EmployeeVisitScreen extends StatefulWidget {
  final String employeeId;
  final String? employeeName;
  final String? adminId;

  const EmployeeVisitScreen({
    Key? key,
    required this.employeeId,
    this.employeeName,
    this.adminId,
  }) : super(key: key);

  @override
  State<EmployeeVisitScreen> createState() => _EmployeeVisitScreenState();
}

class _EmployeeVisitScreenState extends State<EmployeeVisitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Visit? _activeVisit;
  List<Visit> _todayVisits = [];
  bool _isLoadingActiveVisit = false;
  String? _locationError;
  DateTime _lastLoadDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActiveVisit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load active visit and today's visits on screen load
  Future<void> _loadActiveVisit() async {
    setState(() {
      _isLoadingActiveVisit = true;
    });

    try {
      final now = DateTime.now();
      // Check if it's a new day and reset if needed
      final isNewDay =
          _lastLoadDate.day != now.day ||
          _lastLoadDate.month != now.month ||
          _lastLoadDate.year != now.year;

      if (isNewDay) {
        _activeVisit = null;
        _todayVisits = [];
      }

      _lastLoadDate = now;

      final repository = context.read<DistributorRepository>();

      // First try to get active visit
      var activeVisit = await repository.getActiveVisit(widget.employeeId);

      // If no active visit, get today's visits and use the most recent one
      if (activeVisit == null) {
        final todayVisits = await repository.getTodayVisits(widget.employeeId);
        _todayVisits = todayVisits;

        // Show the most recent completed visit if any
        if (todayVisits.isNotEmpty) {
          activeVisit =
              todayVisits.first; // Already sorted by createdAt descending
        }
      } else {
        // If there's an active visit, still load today's visits
        _todayVisits = await repository.getTodayVisits(widget.employeeId);
      }

      setState(() {
        _activeVisit = activeVisit;
        _isLoadingActiveVisit = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load visits: $e';
        _isLoadingActiveVisit = false;
      });
    }
  }

  /// Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// Handle check-in - Show confirmation dialog
  Future<void> _handleCheckIn(Distributor selectedDistributor) async {
    if (_activeVisit != null && _activeVisit!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an active visit. Check out first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Check-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to check in at:'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDistributor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedDistributor.contact,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDistributor.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processCheckIn(selectedDistributor);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Confirm Check-in',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Process the actual check-in after confirmation
  Future<void> _processCheckIn(Distributor selectedDistributor) async {
    try {
      setState(() {
        _isLoadingActiveVisit = true;
      });

      final position = await _getCurrentLocation();

      // Validate location - Check if employee is within 50 meters of distributor
      final distanceInMeters = await Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        selectedDistributor.latitude,
        selectedDistributor.longitude,
      );

      if (distanceInMeters > 100) {
        if (mounted) {
          setState(() {
            _isLoadingActiveVisit = false;
          });

          // Show error dialog if outside range
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Outside Service Area'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are not within the service range of this distributor.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Required distance: Within 100 meters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your distance: ${distanceInMeters.toStringAsFixed(1)} meters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      final repository = context.read<DistributorRepository>();

      // Create the visit and get the visit ID
      final visitId = await repository.checkIn(
        employeeId: widget.employeeId,
        adminId: widget.adminId,
        distributorId: selectedDistributor.id,
        distributorName: selectedDistributor.name,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      // Immediately create the visit object locally to avoid Firestore delay
      final newVisit = Visit(
        id: visitId,
        employeeId: widget.employeeId,
        adminId: widget.adminId,
        distributorId: selectedDistributor.id,
        distributorName: selectedDistributor.name,
        checkInTime: DateTime.now(),
        checkOutTime: null,
        checkInLat: position.latitude,
        checkInLng: position.longitude,
        checkOutLat: null,
        checkOutLng: null,
        checkInAccuracy: position.accuracy,
        checkOutAccuracy: null,
        tasks: [],
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _activeVisit = newVisit;
          _isLoadingActiveVisit = false;
          _locationError = null;
        });

        // Also refresh to get the latest from Firestore in background
        _refreshActiveVisit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Check-in failed: $e';
          _isLoadingActiveVisit = false;
        });
      }
    }
  }

  /// Refresh active visit with force refresh
  Future<void> _refreshActiveVisit() async {
    try {
      final repository = context.read<DistributorRepository>();

      // First try to get active visit
      var activeVisit = await repository.getActiveVisit(widget.employeeId);

      // If no active visit, get today's visits and use the most recent one
      final todayVisits = await repository.getTodayVisits(widget.employeeId);

      if (activeVisit == null && todayVisits.isNotEmpty) {
        activeVisit = todayVisits.first; // Most recent visit
      }

      if (mounted) {
        setState(() {
          _activeVisit = activeVisit;
          _todayVisits = todayVisits;
          _isLoadingActiveVisit = false;
          _locationError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to load visits: $e';
          _isLoadingActiveVisit = false;
        });
      }
    }
  }

  /// Handle add distributor
  Future<void> _handleAddDistributor() async {
    if (widget.adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin ID not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) =>
          EmployeeAddDistributorDialog(adminId: widget.adminId!),
    );

    // Refresh the distributor list after adding
    // The DistributorSelectorWidget will automatically refresh
    // Force a rebuild to ensure the selector updates
    setState(() {});
  }

  /// Handle check-out
  Future<void> _handleCheckOut() async {
    if (_activeVisit == null || !_activeVisit!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active visit to check out from.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoadingActiveVisit = true;
      });

      final position = await _getCurrentLocation();
      final repository = context.read<DistributorRepository>();

      await repository.checkOut(
        visitId: _activeVisit!.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      // Create the completed visit object locally to show immediately
      final completedVisit = _activeVisit!.copyWith(
        checkOutTime: DateTime.now(),
        checkOutLat: position.latitude,
        checkOutLng: position.longitude,
        checkOutAccuracy: position.accuracy,
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _activeVisit = completedVisit;
          _isLoadingActiveVisit = false;
          _locationError = null;
        });

        // Refresh in background
        _refreshActiveVisit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Check-out failed: $e';
          _isLoadingActiveVisit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Distributor Visits${widget.employeeName != null ? ' - ${widget.employeeName}' : ''}',
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Current Visit'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error banner
          if (_locationError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () {
                      setState(() {
                        _locationError = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Current Visit Tab
                RefreshIndicator(
                  onRefresh: () async {
                    await _refreshActiveVisit();
                  },
                  child: _isLoadingActiveVisit
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          children: [
                            // Status Widget
                            VisitStatusWidget(visit: _activeVisit),
                            const SizedBox(height: 16),

                            // Today's Visit Summary
                            if (_activeVisit == null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.today,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Today's Activities",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _todayVisits.isEmpty
                                                ? 'No visits completed yet'
                                                : 'Completed ${_todayVisits.length} visit${_todayVisits.length > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Distributor Selector
                            if (_activeVisit == null ||
                                !_activeVisit!.isActive) ...[
                              const Text(
                                'Select Distributor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DistributorSelectorWidget(
                                onSelected: _handleCheckIn,
                                onAddNew: _handleAddDistributor,
                                adminId: widget.adminId,
                              ),
                            ],

                            // Active Visit Actions
                            if (_activeVisit != null &&
                                _activeVisit!.isActive) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Visit Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Task Logging
                              TaskLoggingWidget(
                                visitId: _activeVisit!.id,
                                onTaskAdded: _loadActiveVisit,
                              ),

                              const SizedBox(height: 24),

                              // Check-out Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleCheckOut,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Check Out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),

                // History Tab
                VisitHistoryWidget(employeeId: widget.employeeId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
