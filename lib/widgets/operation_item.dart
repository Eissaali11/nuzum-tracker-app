import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/operation_model.dart';
import 'beautiful_card.dart';

/// ============================================
/// 📦 عنصر العملية - Operation Item
/// ============================================
class OperationItem extends StatelessWidget {
  final Operation operation;

  const OperationItem({
    super.key,
    required this.operation,
  });

  Color _getTypeColor() {
    switch (operation.type) {
      case OperationType.delivery:
        return Colors.blue;
      case OperationType.pickup:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (operation.type) {
      case OperationType.delivery:
        return Icons.local_shipping;
      case OperationType.pickup:
        return Icons.inventory;
    }
  }

  Color _getStatusColor() {
    switch (operation.status) {
      case OperationStatus.completed:
        return Colors.green;
      case OperationStatus.pending:
        return Colors.orange;
      case OperationStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (operation.status) {
      case OperationStatus.completed:
        return Icons.check_circle;
      case OperationStatus.pending:
        return Icons.access_time;
      case OperationStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
    final typeColor = _getTypeColor();
    final typeIcon = _getTypeIcon();
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return BeautifulCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      border: Border.all(
        color: typeColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operation.type.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(operation.date)} - ${operation.time}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      operation.status.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        operation.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        operation.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Text(
                      '${operation.itemsCount} عنصر',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      typeColor.withValues(alpha: 0.2),
                      typeColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${operation.totalAmount.toStringAsFixed(2)} ${operation.currency}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
