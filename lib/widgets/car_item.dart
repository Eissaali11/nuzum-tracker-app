import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../screens/car_details_screen.dart';
import 'saudi_plate_widget.dart';

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
        return const Color(0xFF10B981);
      case CarStatus.maintenance:
        return const Color(0xFFF59E0B);
      case CarStatus.retired:
        return const Color(0xFFEF4444);
    }
  }

  List<Color> _getStatusGradient() {
    switch (car.status) {
      case CarStatus.active:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case CarStatus.maintenance:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case CarStatus.retired:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  IconData _getStatusIcon() {
    switch (car.status) {
      case CarStatus.active:
        return Icons.check_circle_rounded;
      case CarStatus.maintenance:
        return Icons.build_rounded;
      case CarStatus.retired:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusGradient = _getStatusGradient();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarDetailsScreen(car: car),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // خلفية متدرجة في الأعلى
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusGradient[0].withValues(alpha: 0.1),
                        statusGradient[1].withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // المحتوى
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صف العلوي: صورة السيارة + الحالة
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // صورة السيارة
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: car.photo != null
                                ? Image.network(
                                    car.photo!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.grey[200]!,
                                              Colors.grey[300]!,
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_rounded,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          statusGradient[0].withValues(alpha: 0.3),
                                          statusGradient[1].withValues(alpha: 0.2),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.directions_car_rounded,
                                      size: 50,
                                      color: statusColor,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // معلومات السيارة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // لوحة السيارة السعودية
                              SaudiPlateWidget(
                                plateNumberAr: car.plateNumber,
                                plateNumberEn: car.plateNumberEn,
                                width: double.infinity,
                                height: 90,
                                showShield: false,
                              ),
                              const SizedBox(height: 12),
                              // الموديل
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      car.model,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // اللون
                              Row(
                                children: [
                                  Icon(
                                    Icons.color_lens_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    car.color,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // شريط الحالة السفلي
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: statusGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            car.status.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
}
