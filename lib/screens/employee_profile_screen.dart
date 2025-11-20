import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attendance_model.dart';
import '../models/car_model.dart';
import '../models/employee_model.dart';
import '../models/operation_model.dart';
import '../models/salary_model.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/employee_api_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';
import '../utils/safe_preferences.dart';
import '../widgets/attendance_item.dart';
import '../widgets/beautiful_card.dart';
import '../widgets/employee_photos_card.dart';
import '../widgets/employee_profile_card.dart';
import '../widgets/operation_item.dart';
import 'attendance_list_screen.dart';
import 'cars_list_screen.dart';
import 'employee_id_card_screen.dart';
import 'login_screen.dart';
import 'operations_list_screen.dart';
import 'salaries_list_screen.dart';

/// ============================================
/// 👤 صفحة الموظف الرئيسية - Employee Profile Screen
/// ============================================
class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  Employee? _employee;
  List<Attendance> _attendanceList = [];
  List<Car> _carsList = [];
  List<Salary> _salariesList = [];
  List<Operation> _operationsList = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// ============================================
  /// 🚪 تسجيل الخروج - Logout
  /// ============================================
  Future<void> _logout() async {
    // عرض تأكيد
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations().logout),
        content: Text(AppLocalizations().logoutConfirm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations().cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations().logout),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // إيقاف تتبع الموقع
      await stopLocationTracking();

      // تسجيل خروج صريح - مسح جميع البيانات بما فيها بيانات التتبع
      await AuthService.logout(clearTrackingData: true);
      
      // حذف بيانات إضافية
      await SafePreferences.setBool('disclaimerAccepted', false);

      // التنقل إلى صفحة تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeProfile] Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations().logoutError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber == null || apiKey == null) {
        setState(() {
          _error = AppLocalizations().pleaseEnterJobNumber;
          _isLoading = false;
        });
        return;
      }

      // استخدام الطلب الشامل بدلاً من عدة طلبات
      final completeResponse = await EmployeeApiService.getCompleteProfile(
        jobNumber: jobNumber,
        apiKey: apiKey,
      );

      if (!completeResponse.success || completeResponse.data == null) {
        setState(() {
          _error = completeResponse.error ?? 'فشل جلب البيانات';
          _isLoading = false;
        });
        return;
      }

      final data = completeResponse.data!;

      setState(() {
        _employee = data.employee;
        _attendanceList = data.attendance;
        // دمج جميع السيارات: الحالية + السابقة
        // نضمن عدم تكرار السيارة الحالية إذا كانت موجودة في previousCars
        _carsList = [];
        final addedCarIds = <String>{};
        
        // إضافة السيارة الحالية أولاً إذا كانت موجودة
        if (data.currentCar != null) {
          _carsList.add(data.currentCar!);
          addedCarIds.add(data.currentCar!.carId);
        }
        
        // إضافة جميع السيارات السابقة (بما في ذلك السيارات النشطة)
        for (final previousCar in data.previousCars) {
          // التحقق من عدم التكرار بناءً على car_id
          if (!addedCarIds.contains(previousCar.carId)) {
            _carsList.add(previousCar);
            addedCarIds.add(previousCar.carId);
          }
        }
        
        _salariesList = data.salaries;
        _operationsList = data.operations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      final is503Error =
          _error!.contains('503') ||
          _error!.contains('غير متاحة') ||
          _error!.contains('Service Unavailable');

      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: is503Error
                  ? [Colors.orange.shade50, Colors.orange.shade100]
                  : [Colors.red.shade50, Colors.red.shade100],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (is503Error ? Colors.orange : Colors.red)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      is503Error ? Icons.cloud_off : Icons.error_outline,
                      size: 64,
                      color: is503Error ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    is503Error ? 'الخدمة غير متاحة حالياً' : 'حدث خطأ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: is503Error
                          ? Colors.orange.shade900
                          : Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  BeautifulCard(
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        if (is503Error) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'قد يكون السيرفر غير متاح مؤقتاً أو قيد الصيانة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations().retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: is503Error ? Colors.orange : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_employee == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(child: Text(AppLocalizations().noData)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(AppLocalizations().employeePage),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'بطاقة الهوية',
            onPressed: () {
              if (_employee != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeIdCardScreen(
                      employee: _employee!,
                      city: _employee!
                          .address, // يمكن استخدام address كمدينة مؤقتاً
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'المزيد',
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations().logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة المعلومات الشخصية
            EmployeeProfileCard(employee: _employee!),
            const SizedBox(height: 16),

            // بطاقة الصور (الهوية والرخصة فقط)
            EmployeePhotosCard(
              photos: _employee!.photos,
              isDriver: _employee!.isDriver,
            ),
            const SizedBox(height: 16),

            // بطاقة الإحصائيات (قابلة للتمرير)
            _buildStatisticsGrid(),
            const SizedBox(height: 16),

            // بطاقة الحضور
            SectionCard(
              title: 'الحضور',
              titleIcon: Icons.access_time,
              action: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AttendanceListScreen(attendanceList: _attendanceList),
                    ),
                  );
                },
                child: Text(AppLocalizations().viewAll),
              ),
              child: _attendanceList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: Text(AppLocalizations().noAttendanceData)),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _attendanceList
                          .take(5)
                          .map(
                            (attendance) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: AttendanceItem(attendance: attendance),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // بطاقة السيارات والرواتب المدمجة
            _buildCarsAndSalariesCard(),
            const SizedBox(height: 16),

            // بطاقة العمليات
            SectionCard(
              title: 'عمليات التسليم والاستلام',
              titleIcon: Icons.inventory,
              action: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OperationsListScreen(operationsList: _operationsList),
                    ),
                  );
                },
                child: Text(AppLocalizations().viewAll),
              ),
              child: _operationsList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: Text(AppLocalizations().noOperations)),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _operationsList
                          .take(3)
                          .map(
                            (operation) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: OperationItem(operation: operation),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'حضور اليوم',
                value:
                    _attendanceList.isNotEmpty &&
                        _attendanceList.first.date.day == DateTime.now().day
                    ? 'حاضر'
                    : '0',
                icon: Icons.access_time,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                title: 'راتب الشهر',
                value: _salariesList.isNotEmpty
                    ? _salariesList.first.amount.toStringAsFixed(0)
                    : '0',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'العمليات',
                value: '${_operationsList.length}',
                icon: Icons.inventory,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                title: 'السيارات',
                value: '${_carsList.length}',
                icon: Icons.directions_car,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ============================================
  /// 🚗💰 بطاقة السيارات والرواتب المدمجة
  /// ============================================
  Widget _buildCarsAndSalariesCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header مع العنوان والأزرار
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'السيارات والرواتب',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_carsList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CarsListScreen(carsList: _carsList),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'السيارات',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    if (_carsList.isNotEmpty && _salariesList.isNotEmpty)
                      const SizedBox(width: 8),
                    if (_salariesList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalariesListScreen(
                                salariesList: _salariesList,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'الرواتب',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // المحتوى
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // قسم السيارات
                if (_carsList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'السيارات المرتبطة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF667EEA,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_carsList.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _carsList
                          .take(2)
                          .map(
                            (car) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildModernCarCard(car),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_carsList.length > 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CarsListScreen(carsList: _carsList),
                            ),
                          );
                        },
                        child: const Text(
                          'عرض جميع السيارات',
                          style: TextStyle(
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'لا توجد سيارات مرتبطة',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),

                // فاصل بين السيارات والرواتب
                if (_carsList.isNotEmpty && _salariesList.isNotEmpty)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                    indent: 20,
                    endIndent: 20,
                  ),

                // قسم الرواتب
                if (_salariesList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'الرواتب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF11998E,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_salariesList.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF11998E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildModernSalaryCard(_salariesList.first),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'لا توجد رواتب',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// 🚗 بطاقة سيارة عصرية
  /// ============================================
  Widget _buildModernCarCard(Car car) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (car.status) {
      case CarStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'نشطة';
        break;
      case CarStatus.maintenance:
        statusColor = Colors.orange;
        statusIcon = Icons.build_rounded;
        statusText = 'صيانة';
        break;
      case CarStatus.retired:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusText = 'متوقفة';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة السيارة
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: car.photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      car.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: statusColor,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.directions_car_rounded,
                    size: 40,
                    color: statusColor,
                  ),
          ),
          const SizedBox(width: 16),
          // معلومات السيارة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.plateNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  car.model,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.color_lens_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      car.color,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // حالة السيارة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.08),
                ],
              ),
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
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
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

  /// ============================================
  /// 💰 بطاقة راتب عصرية
  /// ============================================
  Widget _buildModernSalaryCard(Salary salary) {
    final dateFormat = DateFormat('yyyy-MM-dd', LanguageService.instance.isArabic ? 'ar' : 'en');
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (salary.status) {
      case SalaryStatus.paid:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'مدفوع';
        break;
      case SalaryStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusText = 'قيد الانتظار';
        break;
      case SalaryStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusText = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            statusColor.withValues(alpha: 0.08),
            statusColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.2),
                          statusColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salary.month,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      if (salary.paidDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${AppLocalizations().paymentDate}: ${dateFormat.format(salary.paidDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.15),
                      statusColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ الإجمالي',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${salary.amount.toStringAsFixed(2)} ${salary.currency}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (salary.notes != null && salary.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      salary.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
