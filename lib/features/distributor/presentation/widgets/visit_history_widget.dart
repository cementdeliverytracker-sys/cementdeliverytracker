import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/distributor_repository.dart';

/// Widget to display visit history
class VisitHistoryWidget extends StatefulWidget {
  final String employeeId;

  const VisitHistoryWidget({Key? key, required this.employeeId})
    : super(key: key);

  @override
  State<VisitHistoryWidget> createState() => _VisitHistoryWidgetState();
}

class _VisitHistoryWidgetState extends State<VisitHistoryWidget> {
  List<Visit> _visits = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  _HistoryFilter _historyFilter = _HistoryFilter.last7Days;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<DistributorRepository>();
      final now = DateTime.now();
      final visits = await _loadByFilter(repository, now);
      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load visits: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _historyFilter = _HistoryFilter.specificDate;
      });
      await _loadVisits();
    }
  }

  Future<List<Visit>> _loadByFilter(
    DistributorRepository repository,
    DateTime now,
  ) {
    switch (_historyFilter) {
      case _HistoryFilter.last7Days:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return repository.getVisitsByDateRange(widget.employeeId, start, now);
      case _HistoryFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return repository.getVisitsByDateRange(widget.employeeId, start, now);
      case _HistoryFilter.specificDate:
        return repository.getVisitsByDate(widget.employeeId, _selectedDate);
    }
  }

  Map<DateTime, List<Visit>> _groupVisitsByDate(List<Visit> visits) {
    final grouped = <DateTime, List<Visit>>{};
    for (final visit in visits) {
      final dateKey = DateTime(
        visit.checkInTime.year,
        visit.checkInTime.month,
        visit.checkInTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(visit);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _headerLabel(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<_HistoryFilter>(
                initialValue: _historyFilter,
                onSelected: (value) {
                  setState(() {
                    _historyFilter = value;
                  });
                  _loadVisits();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HistoryFilter.last7Days,
                    child: Text('Last 7 days'),
                  ),
                  PopupMenuItem(
                    value: _HistoryFilter.thisMonth,
                    child: Text('This month'),
                  ),
                  PopupMenuItem(
                    value: _HistoryFilter.specificDate,
                    child: Text('Specific date'),
                  ),
                ],
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
              ),
              IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Select date',
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadVisits, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No visits for ${_headerLabel()}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final groupedVisits = _groupVisitsByDate(_visits);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      children: groupedVisits.entries
          .expand(
            (entry) => [
              _DateHeader(date: entry.key),
              ...entry.value
                  .map(
                    (visit) => _VisitCard(
                      visit: visit,
                      onTasksEdited: () => _loadVisits(),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 8),
            ],
          )
          .toList(),
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

  String _headerLabel() {
    switch (_historyFilter) {
      case _HistoryFilter.last7Days:
        return 'Last 7 days';
      case _HistoryFilter.thisMonth:
        return 'This month';
      case _HistoryFilter.specificDate:
        return _formatDate(_selectedDate);
    }
  }
}

enum _HistoryFilter { last7Days, thisMonth, specificDate }

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
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
    final label = '$day $month ${date.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

/// Card displaying a single visit
class _VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback? onTasksEdited;

  const _VisitCard({required this.visit, this.onTasksEdited});

  @override
  Widget build(BuildContext context) {
    final statusColor = visit.isCompleted ? Colors.orange : Colors.green;
    final statusText = visit.isCompleted ? 'Completed' : 'In Progress';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      visit.distributorName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.distributorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${visit.durationMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: statusColor.shade700),
                  tooltip: 'Edit Tasks',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditTasksDialog(context),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time details
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_formatTime(visit.checkInTime)} → ${visit.checkOutTime != null ? _formatTime(visit.checkOutTime!) : 'In progress'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // GPS accuracy
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GPS ±${visit.checkInAccuracy.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (visit.checkOutAccuracy != null)
                      Text(
                        ' → ±${visit.checkOutAccuracy!.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tasks count
                Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${visit.tasks.length} task${visit.tasks.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // Tasks list
                if (visit.tasks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: visit.tasks
                          .map(
                            (task) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _getTaskColor(task.type),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.type.displayName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        if (task.description.isNotEmpty)
                                          Text(
                                            task.description,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (task.type == TaskType.collectMoney &&
                                      task.metadata?.containsKey('amount') ==
                                          true)
                                    Text(
                                      '₹${task.metadata?['amount']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.collectMoney:
        return Colors.green;
      case TaskType.takeOrder:
        return Colors.blue;
      case TaskType.other:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showEditTasksDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EditTasksSheet(
        visit: visit,
        onSaved: () {
          Navigator.of(context).pop();
          onTasksEdited?.call();
        },
      ),
    );
  }
}

/// Bottom sheet for editing tasks
class _EditTasksSheet extends StatefulWidget {
  final Visit visit;
  final VoidCallback onSaved;

  const _EditTasksSheet({required this.visit, required this.onSaved});

  @override
  State<_EditTasksSheet> createState() => _EditTasksSheetState();
}

class _EditTasksSheetState extends State<_EditTasksSheet> {
  late List<VisitTask> _tasks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of tasks to edit
    _tasks = widget.visit.tasks
        .map(
          (t) => VisitTask(
            id: t.id,
            visitId: t.visitId,
            type: t.type,
            description: t.description,
            timestamp: t.timestamp,
            metadata: t.metadata != null
                ? Map<String, dynamic>.from(t.metadata!)
                : null,
          ),
        )
        .toList();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final repository = Provider.of<DistributorRepository>(
        context,
        listen: false,
      );
      await repository.updateVisitTasks(
        visitId: widget.visit.id,
        tasks: _tasks,
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addTask() {
    setState(() {
      _tasks.add(
        VisitTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          visitId: widget.visit.id,
          type: TaskType.other,
          description: '',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _updateTaskType(int index, TaskType type) {
    setState(() {
      _tasks[index] = VisitTask(
        id: _tasks[index].id,
        visitId: _tasks[index].visitId,
        type: type,
        description: _tasks[index].description,
        timestamp: _tasks[index].timestamp,
        metadata: _tasks[index].metadata,
      );
    });
  }

  void _updateTaskDescription(int index, String description) {
    _tasks[index] = VisitTask(
      id: _tasks[index].id,
      visitId: _tasks[index].visitId,
      type: _tasks[index].type,
      description: description,
      timestamp: _tasks[index].timestamp,
      metadata: _tasks[index].metadata,
    );
  }

  void _updateTaskAmount(int index, String amount) {
    final metadata = _tasks[index].metadata ?? {};
    if (amount.isNotEmpty) {
      metadata['amount'] = amount;
    } else {
      metadata.remove('amount');
    }
    _tasks[index] = VisitTask(
      id: _tasks[index].id,
      visitId: _tasks[index].visitId,
      type: _tasks[index].type,
      description: _tasks[index].description,
      timestamp: _tasks[index].timestamp,
      metadata: metadata.isNotEmpty ? metadata : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Edit Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Visit: ${widget.visit.distributorName}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Divider(height: 24),

          // Tasks list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TaskType>(
                                value: task.type,
                                decoration: const InputDecoration(
                                  labelText: 'Task Type',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: TaskType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.displayName),
                                  );
                                }).toList(),
                                onChanged: (type) {
                                  if (type != null) {
                                    _updateTaskType(index, type);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: task.description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) =>
                              _updateTaskDescription(index, value),
                        ),
                        if (task.type == TaskType.collectMoney) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue:
                                task.metadata?['amount']?.toString() ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                _updateTaskAmount(index, value),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add task button
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),

          // Save button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
