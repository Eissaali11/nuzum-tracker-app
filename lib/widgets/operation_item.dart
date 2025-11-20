import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/operation_model.dart';

/// ============================================
/// 📦 عنصر العملية - Operation Item (تصميم أنيق ومميز)
/// ============================================
class OperationItem extends StatelessWidget {
  final Operation operation;

  const OperationItem({
    super.key,
    required this.operation,
  });

  // تحديد الألوان حسب نوع العملية
  Color _getTypeColor() {
    switch (operation.type) {
      case OperationType.delivery:
        return const Color(0xFF10B981); // أخضر للتسليم
      case OperationType.pickup:
        return const Color(0xFF3B82F6); // أزرق للاستلام
    }
  }

  Color _getSecondaryColor() {
    switch (operation.type) {
      case OperationType.delivery:
        return const Color(0xFF059669);
      case OperationType.pickup:
        return const Color(0xFF2563EB);
    }
  }

  // أيقونات تعبيرية
  String _getTypeEmoji() {
    switch (operation.type) {
      case OperationType.delivery:
        return '📤';
      case OperationType.pickup:
        return '📥';
    }
  }

  IconData _getTypeIcon() {
    switch (operation.type) {
      case OperationType.delivery:
        return Icons.upload_rounded;
      case OperationType.pickup:
        return Icons.download_rounded;
    }
  }

  // تحديد ألوان الحالة
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

  List<Color> _getStatusGradient() {
    switch (operation.status) {
      case OperationStatus.completed:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case OperationStatus.pending:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case OperationStatus.cancelled:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  String _getStatusEmoji() {
    switch (operation.status) {
      case OperationStatus.completed:
        return '✓';
      case OperationStatus.pending:
        return '⏰';
      case OperationStatus.cancelled:
        return '⚠️';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = operation.type == OperationType.delivery;
    final primaryColor = _getTypeColor();
    final secondaryColor = _getSecondaryColor();
    final lightColor = isDelivery
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFDBEAFE);
    final typeEmoji = _getTypeEmoji();
    final typeIcon = _getTypeIcon();
    final statusGradient = _getStatusGradient();
    final statusEmoji = _getStatusEmoji();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null, // يمكن إضافة رابط PDF لاحقاً
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // خلفية تدرجية أنيقة
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        lightColor.withValues(alpha: 0.3),
                        Colors.white,
                        lightColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              // محتوى البطاقة
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس البطاقة مع النوع
                    Row(
                      children: [
                        // أيقونة تعبيرية مع خلفية ملونة
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              typeEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                operation.type.displayName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    typeIcon,
                                    size: 14,
                                    color: primaryColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDelivery ? 'عملية تسليم' : 'عملية استلام',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // شارة الحالة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: statusGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor().withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusEmoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                operation.status.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // خط فاصل أنيق
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            primaryColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // معلومات مفصلة مع أيقونات تعبيرية - تصميم مضغوط
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // الصف الأول: التاريخ والوقت
                        SizedBox(
                          width: double.infinity,
                          child: _buildInfoCard(
                            emoji: '📅',
                            icon: Icons.calendar_today_rounded,
                            label: 'التاريخ والوقت',
                            value:
                                '${_formatDate(operation.date)} • ${operation.time}',
                            color: primaryColor,
                          ),
                        ),
                        // الصف الثاني: العميل والعنوان
                        if (operation.clientName.isNotEmpty ||
                            operation.address.isNotEmpty)
                          Row(
                            children: [
                              if (operation.clientName.isNotEmpty)
                                Expanded(
                                  child: _buildInfoCard(
                                    emoji: '👤',
                                    icon: Icons.person_rounded,
                                    label: 'العميل',
                                    value: operation.clientName,
                                    color: primaryColor,
                                  ),
                                ),
                              if (operation.clientName.isNotEmpty &&
                                  operation.address.isNotEmpty)
                                const SizedBox(width: 12),
                              if (operation.address.isNotEmpty)
                                Expanded(
                                  child: _buildInfoCard(
                                    emoji: '📍',
                                    icon: Icons.location_on_rounded,
                                    label: 'العنوان',
                                    value: operation.address,
                                    color: primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        // الصف الثالث: السيارة والعناصر
                        if (operation.carPlateNumber.isNotEmpty ||
                            operation.itemsCount > 0)
                          Row(
                            children: [
                              if (operation.carPlateNumber.isNotEmpty)
                                Expanded(
                                  child: _buildInfoCard(
                                    emoji: '🚗',
                                    icon: Icons.directions_car_rounded,
                                    label: 'لوحة السيارة',
                                    value: operation.carPlateNumber,
                                    color: primaryColor,
                                  ),
                                ),
                              if (operation.carPlateNumber.isNotEmpty &&
                                  operation.itemsCount > 0)
                                const SizedBox(width: 12),
                              if (operation.itemsCount > 0)
                                Expanded(
                                  child: _buildInfoCard(
                                    emoji: '📦',
                                    icon: Icons.inventory_2_rounded,
                                    label: 'عدد العناصر',
                                    value: '${operation.itemsCount} عنصر',
                                    color: primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        // الصف الرابع: المبلغ
                        if (operation.totalAmount > 0)
                          SizedBox(
                            width: double.infinity,
                            child: _buildInfoCard(
                              emoji: '💰',
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'المبلغ الإجمالي',
                              value:
                                  '${operation.totalAmount.toStringAsFixed(2)} ${operation.currency}',
                              color: primaryColor,
                            ),
                          ),
                        // الملاحظات (كاملة العرض)
                        if (operation.notes != null &&
                            operation.notes!.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _buildInfoCard(
                              emoji: '📝',
                              icon: Icons.note_rounded,
                              label: 'ملاحظات',
                              value: operation.notes!,
                              color: primaryColor,
                              isMultiline: true,
                            ),
                          ),
                        ],
                      ],
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

  /// بناء بطاقة معلومات احترافية
  Widget _buildInfoCard({
    required String emoji,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // أيقونة تعبيرية مع خلفية ملونة
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: isMultiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
