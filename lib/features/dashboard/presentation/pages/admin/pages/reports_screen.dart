import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/distributor/data/models/visit_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const int _pageSize = 20;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<_FilterOption> _employees = [];
  final List<_FilterOption> _distributors = [];

  String? _adminId;
  String? _selectedEmployeeId;
  String? _selectedDistributorId;
  DateTimeRange? _selectedDateRange;
  final Set<TaskType> _selectedTaskTypes = {};

  bool _loadingFilters = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final List<Visit> _fetchedVisits = [];

  final Map<String, String> _employeeNameById = {};
  final Map<String, String> _distributorNameById = {};

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _applyFilters();
  }

  Future<void> _loadFilterOptions() async {
    final userId = context.read<AuthNotifier>().user?.id;
    if (userId == null) {
      setState(() {
        _loadingFilters = false;
        _error = 'Admin user not found.';
      });
      return;
    }

    _adminId = userId;

    try {
      final employeesSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('userType', isEqualTo: AppConstants.userTypeEmployee)
          .where('adminId', isEqualTo: userId)
          .get();

      final distributorsSnapshot = await _firestore
          .collection(AppConstants.distributorsCollection)
          .where('adminId', isEqualTo: userId)
          .get();

      _employees
        ..clear()
        ..addAll(
          employeesSnapshot.docs.map((doc) {
            final data = doc.data();
            final name = (data['username'] as String?)?.trim();
            final email = (data['email'] as String?)?.trim();
            final label = (name != null && name.isNotEmpty)
                ? name
                : (email?.isNotEmpty == true ? email! : doc.id);
            _employeeNameById[doc.id] = label;
            return _FilterOption(id: doc.id, label: label);
          }),
        );

      _distributors
        ..clear()
        ..addAll(
          distributorsSnapshot.docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] as String?)?.trim();
            final label = (name != null && name.isNotEmpty) ? name : doc.id;
            _distributorNameById[doc.id] = label;
            return _FilterOption(id: doc.id, label: label);
          }),
        );

      _employees.sort((a, b) => a.label.compareTo(b.label));
      _distributors.sort((a, b) => a.label.compareTo(b.label));

      if (mounted) {
        setState(() => _loadingFilters = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFilters = false;
          _error = 'Failed to load filters: $e';
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastDoc = null;
      _hasMore = true;
      _fetchedVisits.clear();
    });

    await _fetchVisits(reset: true);
  }

  Future<void> _fetchVisits({required bool reset}) async {
    if (!_hasMore && !reset) return;
    if (_isLoadingMore) return;

    if (_adminId == null) {
      setState(() {
        _error = 'Admin user not found.';
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('visits')
          .where('adminId', isEqualTo: _adminId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_selectedEmployeeId != null) {
        query = query.where('employeeId', isEqualTo: _selectedEmployeeId);
      }

      if (_selectedDistributorId != null) {
        query = query.where('distributorId', isEqualTo: _selectedDistributorId);
      }

      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        ).add(const Duration(days: 1));

        query = query
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThan: end);
      }

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      if (docs.isNotEmpty) {
        _lastDoc = docs.last;
      }

      if (docs.length < _pageSize) {
        _hasMore = false;
      }

      final fetched = docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();

      _fetchedVisits.addAll(fetched);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load visits: $e';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedEmployeeId = null;
      _selectedDistributorId = null;
      _selectedDateRange = null;
      _selectedTaskTypes.clear();
    });
    _applyFilters();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  List<Visit> get _displayVisits {
    if (_selectedTaskTypes.isEmpty) return _fetchedVisits;
    return _fetchedVisits.where(_matchesTaskTypes).toList();
  }

  bool _matchesTaskTypes(Visit visit) {
    final visitTypes = visit.tasks.map((task) => task.type).toSet();
    return visitTypes.any(_selectedTaskTypes.contains);
  }

  String _rangeLabel() {
    if (_selectedDateRange == null) return 'Select date range';
    return '${_formatDate(_selectedDateRange!.start)} - '
        '${_formatDate(_selectedDateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: _buildFiltersCard(context),
        ),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildFiltersCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final fieldWidth = isWide
                ? (constraints.maxWidth - 24) / 2
                : constraints.maxWidth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_loadingFilters)
                  const LinearProgressIndicator(minHeight: 2),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _buildEmployeeDropdown(),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _buildDistributorDropdown(),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_rangeLabel()),
                      ),
                    ),
                    SizedBox(width: fieldWidth, child: _buildVisitTypeFilter()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.filter_alt),
                      label: const Text('Apply Filters'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedEmployeeId,
      items: [
        const DropdownMenuItem(value: null, child: Text('All employees')),
        ..._employees.map(
          (employee) =>
              DropdownMenuItem(value: employee.id, child: Text(employee.label)),
        ),
      ],
      onChanged: (value) => setState(() => _selectedEmployeeId = value),
      decoration: const InputDecoration(
        labelText: 'Employee',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDistributorDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedDistributorId,
      items: [
        const DropdownMenuItem(value: null, child: Text('All distributors')),
        ..._distributors.map(
          (distributor) => DropdownMenuItem(
            value: distributor.id,
            child: Text(distributor.label),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _selectedDistributorId = value),
      decoration: const InputDecoration(
        labelText: 'Distributor',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildVisitTypeFilter() {
    final items = <_VisitTypeOption>[
      _VisitTypeOption(label: 'Order', type: TaskType.takeOrder),
      _VisitTypeOption(label: 'Payment', type: TaskType.collectMoney),
      _VisitTypeOption(label: 'Other', type: TaskType.other),
    ];

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Visit type',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: items
            .map(
              (item) => FilterChip(
                label: Text(item.label),
                selected: _selectedTaskTypes.contains(item.type),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTaskTypes.add(item.type);
                    } else {
                      _selectedTaskTypes.remove(item.type);
                    }
                  });
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading && _fetchedVisits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final visits = _displayVisits;

    if (visits.isEmpty) {
      return const Center(child: Text('No visits found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: visits.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == visits.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: () => _fetchVisits(reset: false),
              icon: _isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Load more'),
            ),
          );
        }

        final visit = visits[index];
        return _VisitReportCard(
          visit: visit,
          employeeName: _employeeNameById[visit.employeeId],
          distributorName: _distributorNameById[visit.distributorId],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }
}

class _VisitReportCard extends StatelessWidget {
  final Visit visit;
  final String? employeeName;
  final String? distributorName;

  const _VisitReportCard({
    required this.visit,
    required this.employeeName,
    required this.distributorName,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = visit.isActive ? Colors.green : Colors.orange;
    final visitTypes = visit.tasks.map((task) => task.type).toSet().toList();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    visit.isActive ? 'Active' : 'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${visit.durationMinutes} min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              distributorName ?? visit.distributorName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Employee: ${employeeName ?? visit.employeeId}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Check-in: ${_formatTime(visit.checkInTime)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (visit.checkOutTime != null)
              Text(
                'Check-out: ${_formatTime(visit.checkOutTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: visitTypes.isEmpty
                  ? [const Chip(label: Text('No tasks'))]
                  : visitTypes
                        .map(
                          (type) => Chip(
                            label: Text(type.displayName),
                            backgroundColor: Colors.grey.shade100,
                          ),
                        )
                        .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _FilterOption {
  final String id;
  final String label;

  _FilterOption({required this.id, required this.label});
}

class _VisitTypeOption {
  final String label;
  final TaskType type;

  _VisitTypeOption({required this.label, required this.type});
}
