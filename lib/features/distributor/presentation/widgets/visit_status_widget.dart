import 'package:flutter/material.dart';
import '../../data/models/visit_model.dart';

/// Widget to display current visit status
class VisitStatusWidget extends StatelessWidget {
  final Visit? visit;

  const VisitStatusWidget({Key? key, required this.visit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (visit == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'No Active Visit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a distributor to start a visit',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final isActive = visit!.isActive;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusIcon = isActive ? Icons.location_on : Icons.check_circle;
    final statusText = isActive ? 'Active' : 'Completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${visit!.durationMinutes} min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Distributor name
          Text(
            visit!.distributorName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Check-in time
          Row(
            children: [
              Icon(Icons.arrow_downward, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Checked in: ${_formatTime(visit!.checkInTime)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '±${visit!.checkInAccuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Check-out time (if completed)
          if (visit!.checkOutTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Checked out: ${_formatTime(visit!.checkOutTime!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (visit!.checkOutAccuracy != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '±${visit!.checkOutAccuracy!.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Tasks count
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.purple, size: 16),
              const SizedBox(width: 6),
              Text(
                '${visit!.tasks.length} task${visit!.tasks.length != 1 ? 's' : ''} logged',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
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
