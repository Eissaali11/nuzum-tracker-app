import 'package:flutter/material.dart';
import '../models/car_model.dart';
import 'beautiful_card.dart';

/// ============================================
/// 🚗 عنصر السيارة - Car Item
/// ============================================
class CarItem extends StatelessWidget {
  final Car car;

  const CarItem({
    super.key,
    required this.car,
  });

  Color _getStatusColor() {
    switch (car.status) {
      case CarStatus.active:
        return Colors.green;
      case CarStatus.maintenance:
        return Colors.orange;
      case CarStatus.retired:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (car.status) {
      case CarStatus.active:
        return Icons.check_circle;
      case CarStatus.maintenance:
        return Icons.build;
      case CarStatus.retired:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return BeautifulCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      border: Border.all(
        color: statusColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: car.photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      car.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.directions_car,
                          size: 45,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.directions_car,
                    size: 45,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.plateNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  car.model,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.color_lens, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      car.color,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  car.status.displayName,
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
    );
  }
}
