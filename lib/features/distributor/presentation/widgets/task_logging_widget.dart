import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/distributor_repository.dart';

/// Widget for logging tasks during a visit
class TaskLoggingWidget extends StatefulWidget {
  final String visitId;
  final VoidCallback onTaskAdded;

  const TaskLoggingWidget({
    Key? key,
    required this.visitId,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  State<TaskLoggingWidget> createState() => _TaskLoggingWidgetState();
}

class _TaskLoggingWidgetState extends State<TaskLoggingWidget> {
  TaskType _selectedTaskType = TaskType.collectMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Log Task',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _TaskTypeButton(
              type: TaskType.collectMoney,
              isSelected: _selectedTaskType == TaskType.collectMoney,
              onTap: () {
                setState(() {
                  _selectedTaskType = TaskType.collectMoney;
                });
                _showTaskDialog(TaskType.collectMoney);
              },
            ),
            _TaskTypeButton(
              type: TaskType.takeOrder,
              isSelected: _selectedTaskType == TaskType.takeOrder,
              onTap: () {
                setState(() {
                  _selectedTaskType = TaskType.takeOrder;
                });
                _showTaskDialog(TaskType.takeOrder);
              },
            ),
            _TaskTypeButton(
              type: TaskType.other,
              isSelected: _selectedTaskType == TaskType.other,
              onTap: () {
                setState(() {
                  _selectedTaskType = TaskType.other;
                });
                _showTaskDialog(TaskType.other);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showTaskDialog(TaskType taskType) {
    showDialog(
      context: context,
      builder: (context) => _TaskDialogContent(
        taskType: taskType,
        visitId: widget.visitId,
        onTaskAdded: widget.onTaskAdded,
      ),
    );
  }
}

/// Individual task type button
class _TaskTypeButton extends StatelessWidget {
  final TaskType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case TaskType.collectMoney:
        return Icons.payments;
      case TaskType.takeOrder:
        return Icons.assignment;
      case TaskType.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for task details
class _TaskDialogContent extends StatefulWidget {
  final TaskType taskType;
  final String visitId;
  final VoidCallback onTaskAdded;

  const _TaskDialogContent({
    required this.taskType,
    required this.visitId,
    required this.onTaskAdded,
  });

  @override
  State<_TaskDialogContent> createState() => _TaskDialogContentState();
}

class _TaskDialogContentState extends State<_TaskDialogContent> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_descriptionController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a description';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<DistributorRepository>();

      Map<String, dynamic>? metadata;
      if (widget.taskType == TaskType.collectMoney &&
          _amountController.text.isNotEmpty) {
        metadata = {'amount': double.tryParse(_amountController.text) ?? 0};
      }

      await repository.addTask(
        visitId: widget.visitId,
        taskType: widget.taskType,
        description: _descriptionController.text,
        metadata: metadata,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task logged successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to add task: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.taskType.displayName} Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task details',
              ),
              maxLines: 2,
            ),
            if (widget.taskType == TaskType.collectMoney) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (Optional)',
                  hintText: 'Enter amount collected',
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addTask,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Task'),
        ),
      ],
    );
  }
}
