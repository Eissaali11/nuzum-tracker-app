import 'package:flutter/material.dart';

import '../models/car_model.dart';
import '../utils/responsive_helper.dart';
import '../widgets/car_item.dart';

/// ============================================
/// 🚗 صفحة قائمة السيارات - Cars List Screen
/// ============================================
class CarsListScreen extends StatelessWidget {
  final List<Car> carsList;

  const CarsListScreen({super.key, required this.carsList});

  List<Car> get _displayList {
    // استخدام البيانات الفعلية من API فقط
    return carsList;
  }

  @override
  Widget build(BuildContext context) {
    // حساب الإحصائيات
    final activeCars = _displayList
        .where((car) => car.status == CarStatus.active)
        .length;
    final maintenanceCars = _displayList
        .where((car) => car.status == CarStatus.maintenance)
        .length;
    final retiredCars = _displayList
        .where((car) => car.status == CarStatus.retired)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _displayList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد سيارات مرتبطة'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);
                final padding = ResponsiveHelper.getResponsivePadding(context);
                final margin = ResponsiveHelper.getResponsiveMargin(context);
                final borderRadius = ResponsiveHelper.getResponsiveBorderRadius(
                  context,
                );
                final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                );

                return Column(
                  children: [
                    // بطاقة الإحصائيات
                    Container(
                      margin: margin,
                      padding: padding,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'إحصائيات السيارات',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                              context,
                              mobile: 20,
                              tablet: 24,
                            ),
                          ),
                          isMobile
                              ? Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'نشط',
                                            activeCars.toString(),
                                            Colors.green,
                                            Icons.check_circle,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              ResponsiveHelper.getResponsiveSpacing(
                                                context,
                                                mobile: 8,
                                              ),
                                        ),
                                        Expanded(
                                          child: _buildStatItem(
                                            'صيانة',
                                            maintenanceCars.toString(),
                                            Colors.orange,
                                            Icons.build,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 12,
                                          ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'متقاعد',
                                            retiredCars.toString(),
                                            Colors.red,
                                            Icons.cancel,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              ResponsiveHelper.getResponsiveSpacing(
                                                context,
                                                mobile: 8,
                                              ),
                                        ),
                                        Expanded(
                                          child: _buildStatItem(
                                            'إجمالي',
                                            _displayList.length.toString(),
                                            Colors.blue,
                                            Icons.directions_car,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'نشط',
                                        activeCars.toString(),
                                        Colors.green,
                                        Icons.check_circle,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 8,
                                          ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'صيانة',
                                        maintenanceCars.toString(),
                                        Colors.orange,
                                        Icons.build,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 8,
                                          ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'متقاعد',
                                        retiredCars.toString(),
                                        Colors.red,
                                        Icons.cancel,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 8,
                                          ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'إجمالي',
                                        _displayList.length.toString(),
                                        Colors.blue,
                                        Icons.directions_car,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    // قائمة السيارات
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: padding.left),
                        itemCount: _displayList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 12,
                              ),
                            ),
                            child: CarItem(car: _displayList[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
