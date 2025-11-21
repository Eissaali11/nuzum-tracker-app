import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car_model.dart';
import '../models/employee_model.dart';
import '../models/handover_record_model.dart';
import '../services/employee_api_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../utils/safe_preferences.dart';
import '../widgets/inspection_upload_dialog.dart';
import '../widgets/saudi_plate_widget.dart';
import 'external_safety/external_safety_check_screen.dart';

/// ============================================
/// 🚗 صفحة تفاصيل السيارة - Car Details Screen
/// ============================================
class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  Car? _carDetails;
  List<HandoverRecord> _handoverRecords = [];
  bool _isLoading = true;
  String? _error;
  final _localizations = AppLocalizations();
  Employee? _employee;

  @override
  void initState() {
    super.initState();
    _loadCarDetails();
  }

  Future<void> _loadCarDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber == null || apiKey == null) {
        setState(() {
          _error = _localizations.enterJobNumber;
          _isLoading = false;
        });
        return;
      }

      // محاولة جلب التفاصيل الكاملة مع سجلات التسليم/الاستلام
      final employeeId = await SafePreferences.getString('employee_id');
      if (employeeId != null && employeeId.isNotEmpty) {
        final vehicleDetailsResponse =
            await EmployeeApiService.getVehicleDetailsWithHandovers(
              employeeId: employeeId,
              vehicleId: widget.car.carId,
            );

        if (!mounted) return;
        if (vehicleDetailsResponse.success &&
            vehicleDetailsResponse.data != null) {
          debugPrint(
            '✅ [CarDetails] Successfully loaded car details with handovers',
          );
          setState(() {
            _carDetails = vehicleDetailsResponse.data!.vehicle;
            _handoverRecords = vehicleDetailsResponse.data!.handoverRecords;
            _isLoading = false;
          });
          return;
        }
      }

      // إذا فشل، جرب الطريقة القديمة
      final response = await EmployeeApiService.getCarDetails(
        carId: widget.car.carId,
        jobNumber: jobNumber,
        apiKey: apiKey,
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        debugPrint(
          '✅ [CarDetails] Successfully loaded car details (old method)',
        );
        setState(() {
          _carDetails = response.data;
          _handoverRecords = [];
          _isLoading = false;
        });
      } else {
        debugPrint(
          '⚠️ [CarDetails] Failed to load car details: ${response.message}',
        );
        setState(() {
          _carDetails = widget.car;
          _handoverRecords = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carDetails = widget.car;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return _localizations.noData;
    return DateFormat(
      'yyyy-MM-dd',
      LanguageService.instance.isArabic ? 'ar' : 'en',
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final car = _carDetails ?? widget.car;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    // حساب ارتفاع Header متجاوب
    final expandedHeight = isMobile
        ? screenHeight * 0.35
        : isTablet
        ? screenHeight * 0.30
        : screenHeight * 0.28;

    // حساب مقاس لوحة السيارة متجاوب
    final plateWidth = isMobile
        ? screenWidth * 0.85
        : isTablet
        ? screenWidth * 0.60
        : screenWidth * 0.45;
    final plateHeight = plateWidth * 0.5; // نسبة 2:1

    // حساب padding متجاوب
    final headerPadding = isMobile
        ? 16.0
        : isTablet
        ? 24.0
        : 32.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusGradient(car.status)[0],
                      _getStatusGradient(car.status)[1].withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // خلفية ديكورية متجاوبة
                    Positioned(
                      top: -screenWidth * 0.15,
                      right: -screenWidth * 0.15,
                      child: Container(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -screenWidth * 0.1,
                      left: -screenWidth * 0.1,
                      child: Container(
                        width: screenWidth * 0.35,
                        height: screenWidth * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // محتوى الرأس
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(headerPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // لوحة السيارة السعودية
                            Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: plateWidth,
                                  maxHeight: plateHeight,
                                ),
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 20 : 24,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: isMobile ? 20 : 30,
                                      offset: const Offset(0, 10),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: SaudiPlateWidget(
                                  plateNumberAr: car.plateNumber,
                                  plateNumberEn: car.plateNumberEn,
                                  width: plateWidth - (isMobile ? 24 : 32),
                                  height: plateHeight - (isMobile ? 24 : 32),
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            // معلومات السيارة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 20,
                                    vertical: isMobile ? 8 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 20 : 24,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    car.status.displayName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 13 : 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Text(
              car.plateNumber,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null && _carDetails == null
                ? _buildErrorWidget()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // قسم إجراءات الفحص - تصميم عصري وأنيق
                        _buildInspectionActionsSection(car),
                        // قسم المعلومات الأساسية
                        _buildSectionHeader(
                          'المعلومات الأساسية',
                          Icons.info_rounded,
                        ),
                        const SizedBox(height: 16),
                        // بطاقة التأمين
                        _buildModernInfoCard(
                          icon: Icons.shield_rounded,
                          title: _localizations.insurance,
                          value:
                              (car.insurance != null &&
                                  car.insurance!.isNotEmpty)
                              ? car.insurance!
                              : _localizations.noData,
                          color: const Color(0xFF3B82F6),
                          gradient: const [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ],
                        ),
                        // ملف التأمين
                        if (car.insuranceFile != null &&
                            car.insuranceFile!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildModernLinkCard(
                            car.insuranceFile!,
                            title: _localizations.insuranceFile,
                            icon: Icons.description_rounded,
                            color: const Color(0xFF3B82F6),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // صورة الاستمارة
                        Builder(
                          builder: (context) {
                            final registrationImageUrl =
                                car.registrationFormImage ??
                                car.registrationImage;
                            if (registrationImageUrl != null &&
                                registrationImageUrl.isNotEmpty) {
                              return _buildRegistrationImageCard(
                                registrationImageUrl,
                              );
                            } else {
                              return _buildInfoCard(
                                icon: Icons.description_rounded,
                                title: _localizations.registrationFormImage,
                                value: _localizations.noData,
                                color: Colors.blue,
                              );
                            }
                          },
                        ),
                        // قسم التواريخ المهمة - تصميم مضغوط وأنيق
                        _buildImportantDatesSection(car),
                        // سجلات التسليم/الاستلام
                        if (_handoverRecords.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            'سجلات التسليم والاستلام',
                            Icons.swap_horiz_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._handoverRecords.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHandoverCard(record),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusGradient(CarStatus status) {
    switch (status) {
      case CarStatus.active:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case CarStatus.maintenance:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case CarStatus.retired:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  bool _isExpired(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  bool _isExpiringSoon(DateTime date) {
    final daysUntilExpiry = date.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCarDetails,
              icon: const Icon(Icons.refresh),
              label: Text(_localizations.retry),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رأس قسم
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات حديثة مع تدرج لوني
  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة رابط
  Widget _buildModernLinkCard(
    String url, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.fromRGBO(
              (color.red * 0.7).round(),
              (color.green * 0.7).round(),
              (color.blue * 0.7).round(),
              1.0,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(url),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Text(
                          'اضغط للفتح',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 18,
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
    );
  }

  /// بناء بطاقة صورة الاستمارة
  Widget _buildRegistrationImageCard(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'فشل تحميل الصورة',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'صورة الاستمارة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => _openUrl(imageUrl),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة معلومات بسيطة
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة سجل التسليم/الاستلام - تصميم احترافي وأنيق
  Widget _buildHandoverCard(HandoverRecord record) {
    final isDelivery = record.handoverType == HandoverType.delivery;

    // ألوان وتدرجات احترافية
    final primaryColor = isDelivery
        ? const Color(0xFF10B981) // أخضر للتسليم
        : const Color(0xFF3B82F6); // أزرق للاستلام
    final secondaryColor = isDelivery
        ? const Color(0xFF059669)
        : const Color(0xFF2563EB);
    final lightColor = isDelivery
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFDBEAFE);

    // أيقونات تعبيرية احترافية
    final typeEmoji = isDelivery ? '📤' : '📥';
    final typeIcon = isDelivery ? Icons.upload_rounded : Icons.download_rounded;

    // بناء رابط PDF
    String pdfUrl;
    if (record.formLink != null &&
        record.formLink!.isNotEmpty &&
        record.formLink!.trim().isNotEmpty) {
      pdfUrl = record.formLink!.trim();
    } else {
      if (record.id > 0) {
        pdfUrl = 'https://nuzum.site/vehicles/handover/${record.id}/pdf/public';
      } else {
        pdfUrl = '';
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: pdfUrl.isNotEmpty ? () => _openUrl(pdfUrl) : null,
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
                                record.handoverTypeArabic,
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
                        // أيقونة فتح الرابط
                        if (pdfUrl.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.open_in_new_rounded,
                              color: primaryColor,
                              size: 18,
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
                          child: _buildHandoverInfoCard(
                            emoji: '📅',
                            icon: Icons.calendar_today_rounded,
                            label: 'التاريخ والوقت',
                            value:
                                '${_formatDate(record.handoverDate)} • ${record.handoverTime}',
                            color: primaryColor,
                            isCompact: true,
                          ),
                        ),
                        // الصف الثاني: شخصين في صف واحد
                        if (record.personName.isNotEmpty ||
                            record.supervisorName.isNotEmpty)
                          Row(
                            children: [
                              if (record.personName.isNotEmpty)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '👤',
                                    icon: Icons.person_rounded,
                                    label: 'المسؤول',
                                    value: record.personName,
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                              if (record.personName.isNotEmpty &&
                                  record.supervisorName.isNotEmpty)
                                const SizedBox(width: 12),
                              if (record.supervisorName.isNotEmpty)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '👨‍💼',
                                    icon: Icons.badge_rounded,
                                    label: 'المشرف',
                                    value: record.supervisorName,
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                            ],
                          ),
                        // الصف الثالث: المشروع والمدينة
                        if (record.projectName.isNotEmpty ||
                            record.city.isNotEmpty)
                          Row(
                            children: [
                              if (record.projectName.isNotEmpty)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '🏢',
                                    icon: Icons.business_rounded,
                                    label: 'المشروع',
                                    value: record.projectName,
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                              if (record.projectName.isNotEmpty &&
                                  record.city.isNotEmpty)
                                const SizedBox(width: 12),
                              if (record.city.isNotEmpty)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '📍',
                                    icon: Icons.location_city_rounded,
                                    label: 'المدينة',
                                    value: record.city,
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                            ],
                          ),
                        // الصف الرابع: العداد والوقود
                        if (record.mileage > 0 || record.fuelLevel.isNotEmpty)
                          Row(
                            children: [
                              if (record.mileage > 0)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '🛣️',
                                    icon: Icons.speed_rounded,
                                    label: 'العداد',
                                    value:
                                        '${record.mileage.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} كم',
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                              if (record.mileage > 0 &&
                                  record.fuelLevel.isNotEmpty)
                                const SizedBox(width: 12),
                              if (record.fuelLevel.isNotEmpty)
                                Expanded(
                                  child: _buildHandoverInfoCard(
                                    emoji: '⛽',
                                    icon: Icons.local_gas_station_rounded,
                                    label: 'الوقود',
                                    value: record.fuelLevel,
                                    color: primaryColor,
                                    isCompact: true,
                                  ),
                                ),
                            ],
                          ),
                        // الملاحظات (كاملة العرض)
                        if (record.notes != null &&
                            record.notes!.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _buildHandoverInfoCard(
                              emoji: '📝',
                              icon: Icons.note_rounded,
                              label: 'ملاحظات',
                              value: record.notes!,
                              color: primaryColor,
                              isMultiline: true,
                              isCompact: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // زر فتح النموذج
                    if (pdfUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'فتح نموذج PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قسم التواريخ المهمة - تصميم مضغوط وأنيق
  Widget _buildImportantDatesSection(Car car) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF3F4F6),
            Colors.white,
            const Color(0xFFF9FAFB),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس القسم - مضغوط
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('📅', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'التواريخ المهمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // التواريخ في صفوف مضغوطة جداً
            _buildDateItem(
              emoji: '✅',
              icon: Icons.verified_rounded,
              title: 'تاريخ انتهاء الفحص الدوري',
              date: car.inspectionExpiryDate,
              car: car,
            ),
            const SizedBox(height: 10),
            _buildDateItem(
              emoji: '📄',
              icon: Icons.description_rounded,
              title: _localizations.registrationExpiryDate,
              date: car.registrationExpiryDate,
              car: car,
            ),
            const SizedBox(height: 10),
            _buildDateItem(
              emoji: '🔐',
              icon: Icons.verified_user_rounded,
              title: _localizations.authorizationExpiryDate,
              date: car.authorizationExpiryDate,
              car: car,
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر تاريخ واحد - مضغوط وأنيق
  Widget _buildDateItem({
    required String emoji,
    required IconData icon,
    required String title,
    required DateTime? date,
    required Car car,
  }) {
    final isExpired = date != null && _isExpired(date);
    final isExpiringSoon = date != null && _isExpiringSoon(date);
    final hasDate = date != null;

    // تحديد الألوان حسب الحالة
    Color statusColor;
    List<Color> gradientColors;
    String statusText;
    String statusEmoji;

    if (!hasDate) {
      statusColor = Colors.grey;
      gradientColors = [Colors.grey, Colors.grey.shade700];
      statusText = 'غير متوفر';
      statusEmoji = '❓';
    } else if (isExpired) {
      statusColor = Colors.red;
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      statusText = 'منتهي';
      statusEmoji = '⚠️';
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      statusText = 'قريب الانتهاء';
      statusEmoji = '⏰';
    } else {
      statusColor = Colors.green;
      gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
      statusText = 'ساري';
      statusEmoji = '✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة تعبيرية مع خلفية ملونة - أصغر
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
                        title,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hasDate ? _formatDate(date) : 'غير متوفر',
                        style: TextStyle(
                          color: const Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusEmoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات احترافية في بطاقة التسليم/الاستلام
  Widget _buildHandoverInfoCard({
    required String emoji,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiline = false,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: isCompact ? 6 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // أيقونة تعبيرية مع خلفية ملونة
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: isCompact ? 20 : 24),
              ),
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: isCompact ? 12 : 14,
                      color: color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 4 : 6),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: isMultiline ? 3 : (isCompact ? 1 : 2),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      // التحقق من أن الـ URL غير فارغ وصالح
      if (url.isEmpty || url.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('الرابط غير صالح')));
        }
        return;
      }

      // تنظيف الـ URL من المسافات
      final cleanUrl = url.trim();

      // التحقق من أن الـ URL يحتوي على scheme (http:// أو https://)
      String finalUrl = cleanUrl;
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        finalUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(finalUrl);

      // التحقق من أن الـ URI صالح
      if (!uri.hasScheme || !uri.hasAuthority) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('الرابط غير صالح')));
        }
        return;
      }

      // محاولة فتح الرابط
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الرابط')));
        }
      }
    } on FormatException catch (e) {
      debugPrint('❌ [CarDetails] Invalid URL format: $url - $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('صيغة الرابط غير صحيحة')));
      }
    } catch (e) {
      debugPrint('❌ [CarDetails] Error opening URL: $url - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء فتح الرابط: ${e.toString()}')),
        );
      }
    }
  }

  /// قسم إجراءات الفحص - تصميم عصري وأنيق
  Widget _buildInspectionActionsSection(Car car) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.05),
            const Color(0xFF8B5CF6).withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس القسم مع أيقونة تعبيرية
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔍', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجراءات الفحص',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'فحص شامل للسيارة',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // الأزرار في صف واحد
            Row(
              children: [
                Expanded(child: _buildInspectionUploadButton(car)),
                const SizedBox(width: 16),
                Expanded(child: _buildExternalSafetyButton(car)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// زر رفع صور فحص السلامة - تصميم عصري
  Widget _buildInspectionUploadButton(Car car) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openInspectionUploadDialog(car),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة تعبيرية مع خلفية
              Stack(
                alignment: Alignment.center,
                children: [
                  // خلفية دائرية متوهجة
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  // أيقونة تعبيرية
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('📸', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'رفع طلب صيانة ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'رفع صور وملاحظات ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر فحص السلامة الخارجية - تصميم عصري
  Widget _buildExternalSafetyButton(Car car) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openExternalSafetyCheck(car),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة تعبيرية مع خلفية
              Stack(
                alignment: Alignment.center,
                children: [
                  // خلفية دائرية متوهجة
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  // أيقونة تعبيرية
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🛡️', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'نموذج التفتيش ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'فحص خارجي',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// فتح صفحة فحص السلامة الخارجية
  Future<void> _openExternalSafetyCheck(Car car) async {
    if (!mounted) return;

    // التحقق من وجود معلومات الموظف
    if (_employee == null) {
      try {
        final jobNumber = await SafePreferences.getString('jobNumber');
        final apiKey = await SafePreferences.getString('apiKey');

        if (jobNumber != null && apiKey != null) {
          final response = await EmployeeApiService.getCompleteProfile(
            jobNumber: jobNumber,
            apiKey: apiKey,
          );

          if (response.success && response.data != null) {
            setState(() {
              _employee = response.data!.employee;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ [CarDetails] Error loading employee: $e');
      }
    }

    if (!mounted) return;

    // فتح صفحة فحص السلامة الخارجية
    final jobNumber = await SafePreferences.getString('jobNumber') ?? '';
    final employeeName =
        await SafePreferences.getString('employee_name') ?? 'غير معروف';

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExternalSafetyCheckScreen(
          car: car,
          employee:
              _employee ??
              Employee(
                jobNumber: jobNumber,
                name: employeeName,
                department: '',
                section: '',
                position: '',
                isDriver: false,
              ),
        ),
      ),
    );
  }

  /// فتح نموذج رفع صور الفحص
  Future<void> _openInspectionUploadDialog(Car car) async {
    // التحقق من وجود معلومات الموظف
    if (_employee == null) {
      // محاولة جلب معلومات الموظف
      try {
        final jobNumber = await SafePreferences.getString('jobNumber');
        final apiKey = await SafePreferences.getString('apiKey');

        if (jobNumber != null && apiKey != null) {
          final response = await EmployeeApiService.getCompleteProfile(
            jobNumber: jobNumber,
            apiKey: apiKey,
          );

          if (response.success && response.data != null) {
            setState(() {
              _employee = response.data!.employee;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ [CarDetails] Error loading employee: $e');
      }
    }

    if (!mounted) return;

    // إذا لم يكن الموظف متوفراً، إنشاء موظف افتراضي
    final employee =
        _employee ??
        Employee(
          jobNumber: await SafePreferences.getString('jobNumber') ?? '',
          name: await SafePreferences.getString('employee_name') ?? 'غير معروف',
          department: '',
          section: '',
          position: '',
          isDriver: false,
        );

    // فتح النموذج
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          InspectionUploadDialog(car: car, employee: employee),
    );

    // إذا تم الرفع بنجاح، إعادة تحميل البيانات
    if (result == true && mounted) {
      _loadCarDetails();
    }
  }
}
