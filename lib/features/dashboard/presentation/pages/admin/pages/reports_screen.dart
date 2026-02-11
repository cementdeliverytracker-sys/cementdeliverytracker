import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';

/// Reports Screen for Admin Dashboard
/// Displays employee visit tasks with filtering capabilities
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<VisitTask> _tasks = [];
  List<VisitTask> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  Map<String, String> _employeeNameCache = {};
  Map<String, String> _distributorNameCache = {};

  // Filter state
  DateTimeRange? _selectedDateRange;
  String? _selectedEmployeeId;
  String? _selectedDistributorId;
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          if (_isFilterActive)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Active filter indicator
          if (_isFilterActive) _buildActiveFilterBar(),
          // Tasks list
          Expanded(child: _buildTasksList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterPanel,
        icon: Icon(_isFilterActive ? Icons.filter_list_off : Icons.filter_list),
        label: Text(_isFilterActive ? 'Filtered' : 'Filter'),
        backgroundColor: _isFilterActive
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary,
        foregroundColor: _isFilterActive
            ? Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildActiveFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 18,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getFilterText(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_filteredTasks.length} results',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText() {
    final parts = <String>[];

    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      final dateFormat = '${start.day}/${start.month}/${start.year}';
      final endFormat = '${end.day}/${end.month}/${end.year}';
      parts.add('$dateFormat - $endFormat');
    }

    if (_selectedEmployeeId != null) {
      final employeeName = _employeeNameCache[_selectedEmployeeId] ?? 'Unknown';
      parts.add(employeeName);
    }

    if (_selectedDistributorId != null) {
      final distributorName =
          _distributorNameCache[_selectedDistributorId] ?? 'Unknown';
      parts.add(distributorName);
    }

    return parts.join(' | ');
  }

  Widget _buildTasksList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchTasks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No completed tasks found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tasks will appear here once employees complete their visits',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _isFilterActive ? _filteredTasks.length : _tasks.length,
        itemBuilder: (context, index) {
          final task = _isFilterActive ? _filteredTasks[index] : _tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(task: task),
          );
        },
      ),
    );
  }

  void _applyFilters(
    DateTimeRange? dateRange,
    String? employeeId,
    String? distributorId,
  ) {
    setState(() {
      _selectedDateRange = dateRange;
      _selectedEmployeeId = employeeId;
      _selectedDistributorId = distributorId;

      final hasAnyFilter =
          dateRange != null || employeeId != null || distributorId != null;

      if (hasAnyFilter) {
        _isFilterActive = true;
        _filteredTasks = _tasks.where((task) {
          // Apply date filter
          if (dateRange != null) {
            final taskDate = DateTime(
              task.date.year,
              task.date.month,
              task.date.day,
            );
            final startDate = DateTime(
              dateRange.start.year,
              dateRange.start.month,
              dateRange.start.day,
            );
            final endDate = DateTime(
              dateRange.end.year,
              dateRange.end.month,
              dateRange.end.day,
            );
            if (taskDate.isBefore(startDate) || taskDate.isAfter(endDate)) {
              return false;
            }
          }

          // Apply employee filter
          if (employeeId != null && task.employeeId != employeeId) {
            return false;
          }

          // Apply distributor filter
          if (distributorId != null && task.distributorId != distributorId) {
            return false;
          }

          return true;
        }).toList();
      } else {
        _isFilterActive = false;
        _filteredTasks = [];
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedEmployeeId = null;
      _selectedDistributorId = null;
      _isFilterActive = false;
      _filteredTasks = [];
    });
  }

  Future<void> _fetchTasks() async {
    final authNotifier = context.read<AuthNotifier>();
    final adminId = authNotifier.user?.id;

    if (adminId == null) {
      setState(() {
        _error = 'Admin user not found';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final allVisitsQuery = await _firestore
          .collection('visits')
          .where('adminId', isEqualTo: adminId)
          .limit(50)
          .get();

      QuerySnapshot<Map<String, dynamic>> finalVisitsQuery = allVisitsQuery;

      final employeesQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('adminId', isEqualTo: adminId)
          .where('userType', isEqualTo: AppConstants.userTypeEmployee)
          .get();

      final distributorsQuery = await _firestore
          .collection(AppConstants.distributorsCollection)
          .where('adminId', isEqualTo: adminId)
          .get();

      // Build name caches
      _employeeNameCache.clear();
      for (var doc in employeesQuery.docs) {
        final data = doc.data();

        // Try different possible field names for employee ID
        final empId =
            data['empId']?.toString() ??
            data['employeeId']?.toString() ??
            data['id']?.toString() ??
            doc.id; // fallback to document ID

        final username = data['username'] ?? data['name'] ?? 'Unknown Employee';
        _employeeNameCache[empId] = username;
      }

      _distributorNameCache.clear();
      for (var doc in distributorsQuery.docs) {
        final data = doc.data();
        _distributorNameCache[doc.id] = data['name'] ?? 'Unknown Distributor';
      }

      // Convert visits to tasks
      final tasks = <VisitTask>[];

      for (var doc in finalVisitsQuery.docs) {
        final data = doc.data();

        final task = await VisitTask.fromFirestore(
          doc.id,
          data,
          _employeeNameCache,
          _distributorNameCache,
        );
        if (task != null) {
          tasks.add(task);
        } else {}
      }

      // Sort by completion date (most recent first) - client-side sorting
      tasks.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tasks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTasks() async {
    await _fetchTasks();
    // Re-apply filters if active
    if (_isFilterActive) {
      _applyFilters(
        _selectedDateRange,
        _selectedEmployeeId,
        _selectedDistributorId,
      );
    }
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => FilterPanel(
        initialDateRange: _selectedDateRange,
        initialEmployeeId: _selectedEmployeeId,
        initialDistributorId: _selectedDistributorId,
        employeeNames: _employeeNameCache,
        distributorNames: _distributorNameCache,
        onApplyFilter: (dateRange, employeeId, distributorId) {
          Navigator.pop(context);
          _applyFilters(dateRange, employeeId, distributorId);
        },
        onClearFilter: () {
          Navigator.pop(context);
          _clearFilters();
        },
      ),
    );
  }
}

/// Task Card Widget to display individual visit tasks
class TaskCard extends StatelessWidget {
  final VisitTask task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTaskDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with distributor name and date
                  Row(
                    children: [
                      _buildTaskIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.distributorName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatDate(task.date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTaskTypesChips(),
                ],
              ),
              // Employee info at bottom-right corner
              Positioned(
                bottom: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      backgroundImage:
                          task.employeeImageUrl != null &&
                              task.employeeImageUrl!.isNotEmpty
                          ? NetworkImage(task.employeeImageUrl!)
                          : null,
                      child:
                          task.employeeImageUrl == null ||
                              task.employeeImageUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 65,
                      child: Text(
                        task.employeeName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskIcon() {
    IconData iconData;
    Color iconColor;

    if (task.taskTypes.length > 1) {
      // Combo task - use a combined icon
      iconData = Icons.layers;
      iconColor = Colors.purple;
    } else {
      switch (task.taskTypes.first) {
        case TaskType.moneyCollection:
          iconData = Icons.monetization_on;
          iconColor = Colors.green;
          break;
        case TaskType.orderCollection:
          iconData = Icons.inventory_2;
          iconColor = Colors.blue;
          break;
        case TaskType.otherTask:
          iconData = Icons.build;
          iconColor = Colors.orange;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildTaskTypesChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: task.taskTypes.map((taskType) {
        MaterialColor chipColor;
        String label;

        switch (taskType) {
          case TaskType.moneyCollection:
            chipColor = Colors.green;
            label = 'Money Collection';
            break;
          case TaskType.orderCollection:
            chipColor = Colors.blue;
            label = 'Order Collection';
            break;
          case TaskType.otherTask:
            chipColor = Colors.orange;
            label = 'Other Task';
            break;
        }

        return Chip(
          label: Text(
            label,
            style: TextStyle(
              color: chipColor[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: chipColor.withValues(alpha: 0.1),
          side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsModal(task: task),
    );
  }
}

/// Filter Panel Widget - Date Range, Employee, and Distributor Filter
class FilterPanel extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final String? initialEmployeeId;
  final String? initialDistributorId;
  final Map<String, String> employeeNames;
  final Map<String, String> distributorNames;
  final Function(DateTimeRange?, String?, String?) onApplyFilter;
  final VoidCallback onClearFilter;

  const FilterPanel({
    super.key,
    this.initialDateRange,
    this.initialEmployeeId,
    this.initialDistributorId,
    required this.employeeNames,
    required this.distributorNames,
    required this.onApplyFilter,
    required this.onClearFilter,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  DateTimeRange? selectedDateRange;
  String? selectedEmployeeId;
  String? selectedDistributorId;
  String _selectedQuickFilter = '';

  @override
  void initState() {
    super.initState();
    selectedDateRange = widget.initialDateRange;
    selectedEmployeeId = widget.initialEmployeeId;
    selectedDistributorId = widget.initialDistributorId;
  }

  bool get _hasAnyFilter =>
      selectedDateRange != null ||
      selectedEmployeeId != null ||
      selectedDistributorId != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Employee Filter
          Text(
            'Employee',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedEmployeeId,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'All Employees',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: selectedEmployeeId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => selectedEmployeeId = null),
                    )
                  : null,
            ),
            items: widget.employeeNames.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedEmployeeId = value);
            },
          ),
          const SizedBox(height: 16),

          // Distributor Filter
          Text(
            'Distributor',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedDistributorId,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'All Distributors',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: selectedDistributorId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => selectedDistributorId = null),
                    )
                  : null,
            ),
            items: widget.distributorNames.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedDistributorId = value);
            },
          ),
          const SizedBox(height: 20),

          // Quick date filters
          Text(
            'Date Range',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip('Today', _getTodayRange),
              _buildQuickFilterChip('Yesterday', _getYesterdayRange),
              _buildQuickFilterChip('Last 7 Days', _getLast7DaysRange),
              _buildQuickFilterChip('Last 30 Days', _getLast30DaysRange),
              _buildQuickFilterChip('This Month', _getThisMonthRange),
              _buildQuickFilterChip('Last Month', _getLastMonthRange),
            ],
          ),
          const SizedBox(height: 16),

          // Custom date range
          InkWell(
            onTap: _showDateRangePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDateRange != null
                          ? '${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}'
                          : 'Select custom date range',
                      style: TextStyle(
                        color: selectedDateRange != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        selectedDateRange = null;
                        _selectedQuickFilter = '';
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClearFilter,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasAnyFilter
                      ? () => widget.onApplyFilter(
                          selectedDateRange,
                          selectedEmployeeId,
                          selectedDistributorId,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    DateTimeRange Function() getRange,
  ) {
    final isSelected = _selectedQuickFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedQuickFilter = label;
            selectedDateRange = getRange();
          } else {
            _selectedQuickFilter = '';
            selectedDateRange = null;
          }
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange:
          selectedDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        _selectedQuickFilter = ''; // Clear quick filter selection
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Quick filter date range generators
  DateTimeRange _getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today);
  }

  DateTimeRange _getYesterdayRange() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return DateTimeRange(start: yesterday, end: yesterday);
  }

  DateTimeRange _getLast7DaysRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));
    return DateTimeRange(start: weekAgo, end: today);
  }

  DateTimeRange _getLast30DaysRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthAgo = today.subtract(const Duration(days: 29));
    return DateTimeRange(start: monthAgo, end: today);
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: firstDay, end: today);
  }

  DateTimeRange _getLastMonthRange() {
    final now = DateTime.now();
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);
    return DateTimeRange(start: firstDayLastMonth, end: lastDayLastMonth);
  }
}

/// Task Details Modal Widget
class TaskDetailsModal extends StatelessWidget {
  final VisitTask task;

  const TaskDetailsModal({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with distributor name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.distributorName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Purpose of Visit (renamed from Tasks Completed)
                  _buildInfoSection(
                    'Purpose of Visit',
                    task.taskDetails.map((taskDetail) {
                      return _buildDetailedTaskRow(taskDetail);
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Visit Time (Check-in/Check-out)
                  _buildInfoSection('Visit Time', [
                    if (task.checkInTime != null)
                      _buildInfoRow(
                        'Check-in',
                        _formatDateTime(task.checkInTime!),
                      ),
                    if (task.checkOutTime != null)
                      _buildInfoRow(
                        'Check-out',
                        _formatDateTime(task.checkOutTime!),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // 3. Employee Information
                  _buildInfoSection('Employee Information', [
                    _buildInfoRow('Name', task.employeeName),
                    _buildInfoRow('Employee ID', task.employeeId),
                    _buildInfoRow(
                      'Phone',
                      task.employeePhone ?? 'Not available',
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 4. Visit Duration
                  _buildInfoSection('Visit Duration', [
                    _buildInfoRow(
                      'Total Time',
                      '${task.durationMinutes} minutes',
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 5. Location Verification Status
                  _buildLocationVerificationSection(task),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Builds location verification status section
  /// Shows "Verified" if both check-in and check-out accuracy are within 100m
  /// Shows "Needs Review" if accuracy is poor or suspicious
  Widget _buildLocationVerificationSection(VisitTask task) {
    const double accuracyThreshold = 100.0; // meters

    final checkInAcc = task.checkInAccuracy ?? 0.0;
    final checkOutAcc = task.checkOutAccuracy ?? 0.0;

    // Determine verification status
    final bool isCheckInValid =
        checkInAcc > 0 && checkInAcc <= accuracyThreshold;
    final bool isCheckOutValid =
        checkOutAcc > 0 && checkOutAcc <= accuracyThreshold;
    final bool hasCheckOut = task.checkOutAccuracy != null;

    // Check for suspicious data (0.0 accuracy is likely fake/spoofed)
    final bool isSuspicious =
        checkInAcc == 0.0 || (hasCheckOut && checkOutAcc == 0.0);

    // Overall verification status
    final bool isVerified =
        !isSuspicious && isCheckInValid && (!hasCheckOut || isCheckOutValid);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isSuspicious) {
      statusText = 'Suspicious';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    } else if (isVerified) {
      statusText = 'Location Verified';
      statusColor = Colors.green;
      statusIcon = Icons.verified_rounded;
    } else {
      statusText = 'Needs Review';
      statusColor = Colors.amber;
      statusIcon = Icons.info_outline_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getVerificationDescription(
                        isVerified: isVerified,
                        isSuspicious: isSuspicious,
                        checkInAcc: checkInAcc,
                        checkOutAcc: checkOutAcc,
                        hasCheckOut: hasCheckOut,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getVerificationDescription({
    required bool isVerified,
    required bool isSuspicious,
    required double checkInAcc,
    required double checkOutAcc,
    required bool hasCheckOut,
  }) {
    if (isSuspicious) {
      return 'GPS data shows 0.0m accuracy which may indicate location spoofing or GPS error.';
    }
    if (isVerified) {
      return 'Employee visit location confirmed within acceptable range.';
    }

    // Build explanation for why it needs review
    final List<String> issues = [];
    if (checkInAcc > 100) {
      issues.add('Check-in accuracy was ${checkInAcc.toStringAsFixed(0)}m');
    }
    if (hasCheckOut && checkOutAcc > 100) {
      issues.add('Check-out accuracy was ${checkOutAcc.toStringAsFixed(0)}m');
    }

    if (issues.isNotEmpty) {
      return '${issues.join('. ')}. Poor GPS signal during visit.';
    }
    return 'Location data incomplete or unavailable.';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTaskRow(TaskDetail taskDetail) {
    IconData iconData;
    Color iconColor;
    String typeLabel;

    switch (taskDetail.type) {
      case TaskType.moneyCollection:
        iconData = Icons.monetization_on;
        iconColor = Colors.green;
        typeLabel = 'Money Collection';
        break;
      case TaskType.orderCollection:
        iconData = Icons.inventory_2;
        iconColor = Colors.blue;
        typeLabel = 'Order Collection';
        break;
      case TaskType.otherTask:
        iconData = Icons.build;
        iconColor = Colors.orange;
        typeLabel = 'Other Task';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taskDetail.description,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  // Show specific details based on task type
                  if (taskDetail.type == TaskType.moneyCollection &&
                      taskDetail.amount != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Amount: ₹${taskDetail.amount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (taskDetail.type == TaskType.orderCollection) ...[
                    if (taskDetail.orderItems != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Items: ${taskDetail.orderItems}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (taskDetail.orderValue != null &&
                        taskDetail.orderValue! > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Value: ₹${taskDetail.orderValue!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (taskDetail.type == TaskType.otherTask &&
                      taskDetail.notes != null &&
                      taskDetail.notes != taskDetail.description) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${taskDetail.notes}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Data Models

class VisitTask {
  final String id;
  final String employeeName;
  final String employeeId;
  final String? employeePhone;
  final String distributorName;
  final String distributorId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final List<TaskType> taskTypes;
  final List<TaskDetail> taskDetails;
  final int durationMinutes;
  final Map<String, double>? checkInLocation;
  final Map<String, double>? checkOutLocation;
  final double? checkInAccuracy;
  final double? checkOutAccuracy;
  final String? employeeImageUrl;

  VisitTask({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    this.employeePhone,
    required this.distributorName,
    required this.distributorId,
    required this.date,
    this.checkInTime,
    required this.checkOutTime,
    required this.taskTypes,
    required this.taskDetails,
    this.checkInLocation,
    this.checkOutLocation,
    required this.durationMinutes,
    this.checkInAccuracy,
    this.checkOutAccuracy,
    this.employeeImageUrl,
  });

  static Future<VisitTask?> fromFirestore(
    String docId,
    Map<String, dynamic> data,
    Map<String, String> employeeNames,
    Map<String, String> distributorNames,
  ) async {
    try {
      final employeeId = data['employeeId']
          ?.toString(); // Convert to string since it's numeric
      final distributorId = data['distributorId'] as String?;

      final checkInTime = (data['checkInTime'] as Timestamp?)?.toDate();
      final checkOutTime = (data['checkOutTime'] as Timestamp?)?.toDate();
      final tasks = data['tasks'] as List<dynamic>?;
      final checkInLocation = _parseLocation(data['checkInLocation']);
      final checkOutLocation = _parseLocation(data['checkOutLocation']);

      // Extract accuracy from inside the location objects (not top-level fields)
      final checkInLocationData =
          data['checkInLocation'] as Map<String, dynamic>?;
      final checkOutLocationData =
          data['checkOutLocation'] as Map<String, dynamic>?;
      final checkInAccuracy = (checkInLocationData?['accuracy'] as num?)
          ?.toDouble();
      final checkOutAccuracy = (checkOutLocationData?['accuracy'] as num?)
          ?.toDouble();

      // Make parsing more flexible - allow visits without checkout time
      if (employeeId == null || distributorId == null) {
        return null;
      }

      // Use checkInTime if checkOutTime is null, or current time as fallback
      final completionTime = checkOutTime ?? checkInTime ?? DateTime.now();
      final startTime =
          checkInTime ?? completionTime.subtract(const Duration(hours: 1));

      // Calculate duration (ceiling to round up partial minutes)
      final durationSeconds = completionTime.difference(startTime).inSeconds;
      final duration = (durationSeconds / 60).ceil();

      // Parse task types and descriptions
      final taskTypes = <TaskType>[];
      final taskDescriptions = <String>[];
      final taskDetails = <TaskDetail>[];

      if (tasks != null) {
        for (var task in tasks) {
          if (task is Map<String, dynamic>) {
            final typeStr = task['type'] as String?;
            final description =
                task['description'] as String? ?? 'No description';
            final metadata = task['metadata'] as Map<String, dynamic>? ?? {};

            taskDescriptions.add(description);

            if (typeStr != null) {
              switch (typeStr) {
                case 'collect_money': // Match the actual field value
                case 'collectMoney': // Legacy support
                  taskTypes.add(TaskType.moneyCollection);
                  final amount = metadata['amount']?.toDouble() ?? 0.0;
                  taskDetails.add(
                    TaskDetail(
                      type: TaskType.moneyCollection,
                      description: description,
                      amount: amount,
                    ),
                  );
                  break;
                case 'take_order': // Match the actual field value
                case 'takeOrder': // Legacy support
                  taskTypes.add(TaskType.orderCollection);
                  final orderItems =
                      metadata['items'] as String? ?? 'No items specified';
                  final orderValue = metadata['value']?.toDouble() ?? 0.0;
                  taskDetails.add(
                    TaskDetail(
                      type: TaskType.orderCollection,
                      description: description,
                      orderItems: orderItems,
                      orderValue: orderValue,
                    ),
                  );
                  break;
                case 'other':
                  taskTypes.add(TaskType.otherTask);
                  final notes = metadata['notes'] as String? ?? description;
                  taskDetails.add(
                    TaskDetail(
                      type: TaskType.otherTask,
                      description: description,
                      notes: notes,
                    ),
                  );
                  break;
              }
            }
          }
        }
      }

      // If no tasks found, add a default 'other' task
      if (taskTypes.isEmpty) {
        taskTypes.add(TaskType.otherTask);
        taskDescriptions.add('General visit');
        taskDetails.add(
          TaskDetail(
            type: TaskType.otherTask,
            description: 'General visit',
            notes: 'No specific tasks recorded',
          ),
        );
      }

      // Fetch employee image URL and phone from Firestore
      String? employeeImageUrl;
      String? employeePhone;
      try {
        // First check if employee data is embedded in the visit itself
        if (data.containsKey('employeeImage')) {
          employeeImageUrl = data['employeeImage'] as String?;
        } else if (data.containsKey('employeePhotoUrl')) {
          employeeImageUrl = data['employeePhotoUrl'] as String?;
        }

        // If no image in visit, query users collection by empId/employeeId field
        if (employeeImageUrl == null || employeeImageUrl.isEmpty) {
          // Query for user document where empId or employeeId field matches
          final querySnapshot = await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .where('empId', isEqualTo: employeeId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isEmpty) {
            // Try alternate field name
            final altQuerySnapshot = await FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .where('employeeId', isEqualTo: employeeId)
                .limit(1)
                .get();

            if (altQuerySnapshot.docs.isNotEmpty) {
              final employeeData = altQuerySnapshot.docs.first.data();
              final actualDocId = altQuerySnapshot.docs.first.id;

              // Get phone number
              employeePhone =
                  employeeData['phone'] ??
                  employeeData['phoneNumber'] ??
                  employeeData['mobile'] ??
                  employeeData['mobileNumber'];

              // Try to get image URL from various possible field names
              employeeImageUrl =
                  employeeData['profileImage'] ??
                  employeeData['imageUrl'] ??
                  employeeData['photoUrl'] ??
                  employeeData['profile_image'] ??
                  employeeData['profileImageUrl'];

              // If no image in Firestore, try Storage with actual doc ID
              if ((employeeImageUrl == null || employeeImageUrl.isEmpty) &&
                  actualDocId.isNotEmpty) {
                try {
                  // Images are stored at user_images/{docId}.jpg
                  final storageRefObj = FirebaseStorage.instance
                      .ref()
                      .child('user_images')
                      .child('$actualDocId.jpg');

                  final downloadUrl = await storageRefObj.getDownloadURL();
                  employeeImageUrl = downloadUrl;
                } catch (_) {
                  // No image in Storage
                }
              }
            }
          } else {
            final employeeData = querySnapshot.docs.first.data();
            final actualDocId = querySnapshot.docs.first.id;

            // Get phone number
            employeePhone =
                employeeData['phone'] ??
                employeeData['phoneNumber'] ??
                employeeData['mobile'] ??
                employeeData['mobileNumber'];

            // Try to get image URL from various possible field names
            employeeImageUrl =
                employeeData['profileImage'] ??
                employeeData['imageUrl'] ??
                employeeData['photoUrl'] ??
                employeeData['profile_image'] ??
                employeeData['profileImageUrl'];

            // If no image in Firestore, try Storage with actual doc ID
            if ((employeeImageUrl == null || employeeImageUrl.isEmpty) &&
                actualDocId.isNotEmpty) {
              try {
                // Images are stored at user_images/{docId}.jpg
                final storageRefObj = FirebaseStorage.instance
                    .ref()
                    .child('user_images')
                    .child('$actualDocId.jpg');

                final downloadUrl = await storageRefObj.getDownloadURL();
                employeeImageUrl = downloadUrl;
              } catch (_) {
                // No image in Storage
              }
            }
          }
        }
      } catch (_) {
        // If image fetch fails, continue without image
        employeeImageUrl = null;
      }

      final result = VisitTask(
        id: docId,
        employeeName: employeeNames[employeeId] ?? 'Unknown Employee',
        employeeId: employeeId,
        employeePhone: employeePhone,
        distributorName:
            distributorNames[distributorId] ?? 'Unknown Distributor',
        distributorId: distributorId,
        date: completionTime, // Use flexible completion time
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        taskTypes: taskTypes,
        taskDetails: taskDetails,
        checkInLocation: checkInLocation,
        checkOutLocation: checkOutLocation,
        durationMinutes: duration,
        checkInAccuracy: checkInAccuracy,
        checkOutAccuracy: checkOutAccuracy,
        employeeImageUrl: employeeImageUrl,
      );

      return result;
    } catch (e) {
      return null;
    }
  }

  // Helper method to parse location data
  static Map<String, double>? _parseLocation(dynamic locationData) {
    if (locationData is Map<String, dynamic>) {
      final lat = locationData['latitude']?.toDouble();
      final lng = locationData['longitude']?.toDouble();
      if (lat != null && lng != null) {
        return {'latitude': lat, 'longitude': lng};
      }
    }
    return null;
  }
}

enum TaskType { moneyCollection, orderCollection, otherTask }

class TaskDetail {
  final TaskType type;
  final String description;
  final double? amount; // For money collection
  final String? orderItems; // For order collection
  final double? orderValue; // For order collection
  final String? notes; // For other tasks

  TaskDetail({
    required this.type,
    required this.description,
    this.amount,
    this.orderItems,
    this.orderValue,
    this.notes,
  });
}
