import 'package:flutter/material.dart';

import '../models/car_model.dart';
import '../utils/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../widgets/car_item.dart';

/// ============================================
/// 🚗 صفحة قائمة السيارات - Cars List Screen
/// ============================================
class CarsListScreen extends StatefulWidget {
  final List<Car> carsList;

  const CarsListScreen({super.key, required this.carsList});

  @override
  State<CarsListScreen> createState() => _CarsListScreenState();
}

class _CarsListScreenState extends State<CarsListScreen>
    with SingleTickerProviderStateMixin {
  final _localizations = AppLocalizations();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Car> get _displayList {
    // استخدام البيانات الفعلية من API فقط
    // التأكد من أن جميع السيارات موجودة
    debugPrint('🚗 [CarsList] Displaying ${widget.carsList.length} cars');
    for (var i = 0; i < widget.carsList.length; i++) {
      debugPrint(
        '   ${i + 1}. ${widget.carsList[i].plateNumber} (${widget.carsList[i].status.displayName}) - ID: ${widget.carsList[i].carId}',
      );
    }
    return widget.carsList;
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: _displayList.isEmpty
          ? Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _localizations.noLinkedCars,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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

                return Column(
                  children: [
                    // بطاقة الإحصائيات المحسّنة
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.only(
                          top: margin.top,
                          left: margin.left,
                          right: margin.right,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // خلفية ديكورية
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            // المحتوى
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 20,
                                vertical: isMobile ? 12 : 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // العنوان
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _localizations.carStatistics,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // الإحصائيات
                                  isMobile
                                      ? Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: _buildStatItem(
                                                    _localizations.activeCars,
                                                    activeCars.toString(),
                                                    const Color(0xFF10B981),
                                                    Icons.check_circle_rounded,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildStatItem(
                                                    _localizations.maintenanceCars,
                                                    maintenanceCars.toString(),
                                                    const Color(0xFFF59E0B),
                                                    Icons.build_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: _buildStatItem(
                                                    _localizations.retiredCars,
                                                    retiredCars.toString(),
                                                    const Color(0xFFEF4444),
                                                    Icons.cancel_rounded,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildStatItem(
                                                    _localizations.total,
                                                    _displayList.length.toString(),
                                                    const Color(0xFF3B82F6),
                                                    Icons.directions_car_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: _buildStatItem(
                                                _localizations.activeCars,
                                                activeCars.toString(),
                                                const Color(0xFF10B981),
                                                Icons.check_circle_rounded,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStatItem(
                                                _localizations.maintenanceCars,
                                                maintenanceCars.toString(),
                                                const Color(0xFFF59E0B),
                                                Icons.build_rounded,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStatItem(
                                                _localizations.retiredCars,
                                                retiredCars.toString(),
                                                const Color(0xFFEF4444),
                                                Icons.cancel_rounded,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStatItem(
                                                _localizations.total,
                                                _displayList.length.toString(),
                                                const Color(0xFF3B82F6),
                                                Icons.directions_car_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // قائمة السيارات
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: padding.left),
                        itemCount: _displayList.length,
                        itemBuilder: (context, index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 16,
                                ),
                              ),
                              child: CarItem(car: _displayList[index]),
                            ),
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
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 10 : 12,
        horizontal: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
