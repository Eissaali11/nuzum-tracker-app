import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import 'beautiful_card.dart';

/// ============================================
/// 📅 عنصر الحضور - Attendance Item
/// ============================================
class AttendanceItem extends StatelessWidget {
  final Attendance attendance;

  const AttendanceItem({
    super.key,
    required this.attendance,
  });

  Color _getStatusColor() {
    switch (attendance.status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.earlyLeave:
        return Colors.blue;
      case AttendanceStatus.holiday:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon() {
    switch (attendance.status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.warning;
      case AttendanceStatus.earlyLeave:
        return Icons.access_time;
      case AttendanceStatus.holiday:
        return Icons.beach_access;
    }
  }

  String _getTimeText() {
    if (attendance.checkIn == null && attendance.checkOut == null) {
      return 'لا يوجد';
    }
    if (attendance.checkIn != null && attendance.checkOut != null) {
      return '${attendance.checkIn} - ${attendance.checkOut}';
    }
    if (attendance.checkIn != null) {
      return 'دخل: ${attendance.checkIn}';
    }
    return 'خرج: ${attendance.checkOut}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return BeautifulCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      border: Border.all(
        color: statusColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(attendance.date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getTimeText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  attendance.status.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (attendance.hoursWorked > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${attendance.hoursWorked.toStringAsFixed(1)} ساعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
