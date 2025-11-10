import 'package:flutter/material.dart';
import '../models/operation_model.dart';
import '../widgets/operation_item.dart';

/// ============================================
/// 📦 صفحة قائمة العمليات - Operations List Screen
/// ============================================
class OperationsListScreen extends StatefulWidget {
  final List<Operation> operationsList;

  const OperationsListScreen({
    super.key,
    required this.operationsList,
  });

  @override
  State<OperationsListScreen> createState() => _OperationsListScreenState();
}

class _OperationsListScreenState extends State<OperationsListScreen> {
  String _filterType = 'all'; // all, delivery, pickup
  String _filterStatus = 'all'; // all, completed, pending, cancelled

  List<Operation> get _filteredOperations {
    var filtered = widget.operationsList;

    if (_filterType != 'all') {
      filtered = filtered.where((op) {
        return op.type.toString().split('.').last == _filterType;
      }).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((op) {
        return op.status.toString().split('.').last == _filterStatus;
      }).toList();
    }

    return filtered;
  }

  Map<String, dynamic> get _statistics {
    final total = widget.operationsList.length;
    final delivery = widget.operationsList
        .where((op) => op.type == OperationType.delivery)
        .length;
    final pickup = widget.operationsList
        .where((op) => op.type == OperationType.pickup)
        .length;
    final completed = widget.operationsList
        .where((op) => op.status == OperationStatus.completed)
        .length;
    final pending = widget.operationsList
        .where((op) => op.status == OperationStatus.pending)
        .length;
    final totalAmount = widget.operationsList.fold<double>(
      0.0,
      (sum, op) => sum + op.totalAmount,
    );

    return {
      'total': total,
      'delivery': delivery,
      'pickup': pickup,
      'completed': completed,
      'pending': pending,
      'totalAmount': totalAmount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('عمليات التسليم والاستلام'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: widget.operationsList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد عمليات'),
                ],
              ),
            )
          : Column(
              children: [
                // بطاقة الإحصائيات
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFF1A237E),
                        Color(0xFF0D47A1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'إحصائيات العمليات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'إجمالي',
                            stats['total'].toString(),
                            Colors.blue,
                            Icons.inventory,
                          ),
                          _buildStatItem(
                            'تسليم',
                            stats['delivery'].toString(),
                            Colors.green,
                            Icons.local_shipping,
                          ),
                          _buildStatItem(
                            'استلام',
                            stats['pickup'].toString(),
                            Colors.purple,
                            Icons.inventory_2,
                          ),
                          _buildStatItem(
                            'مكتمل',
                            stats['completed'].toString(),
                            Colors.orange,
                            Icons.check_circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إجمالي المبلغ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${stats['totalAmount'].toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // الفلاتر
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          'النوع',
                          _filterType,
                          ['all', 'delivery', 'pickup'],
                          ['الكل', 'تسليم', 'استلام'],
                          (value) => setState(() => _filterType = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterChip(
                          'الحالة',
                          _filterStatus,
                          ['all', 'completed', 'pending', 'cancelled'],
                          ['الكل', 'مكتمل', 'معلق', 'ملغي'],
                          (value) => setState(() => _filterStatus = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // قائمة العمليات
                Expanded(
                  child: _filteredOperations.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد عمليات مطابقة للفلتر'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredOperations.length,
                          itemBuilder: (context, index) {
                            return OperationItem(
                              operation: _filteredOperations[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: List.generate(values.length, (index) {
              final isSelected = currentValue == values[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(values[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A237E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
