import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/car_model.dart';
import '../models/salary_model.dart';
import '../services/auth_service.dart';
import '../services/employee_api_service.dart';
import '../services/notifications_api_service.dart';
import '../utils/safe_preferences.dart';
import 'attendance_list_screen.dart';
import 'cars_list_screen.dart';
import 'employee_profile_screen.dart';
import 'liabilities/liabilities_screen.dart';
import 'login_screen.dart';
import 'notifications/notifications_screen.dart';
import 'requests/requests_home_screen.dart';
import 'salaries_list_screen.dart';
import 'tracking_screen.dart';

/// ============================================
/// 🏠 الصفحة الرئيسية مع القائمة السفلية
/// ============================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // بيانات للصفحات التي تحتاج بيانات
  List<Attendance> _attendanceList = [];
  List<Car> _carsList = [];
  List<Salary> _salariesList = [];
  int _unreadNotificationsCount = 0;
  String? _employeeName;
  String? _employeePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadDataForScreens();
    _loadNotificationsCount();
    // تحديث عداد الإشعارات كل 30 ثانية
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _loadNotificationsCount();
    });
  }

  Future<void> _loadNotificationsCount() async {
    try {
      final result = await NotificationsApiService.getNotifications();
      if (result['success'] == true && mounted) {
        setState(() {
          _unreadNotificationsCount = result['unread_count'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [MainNav] Failed to load notifications count: $e');
    }
  }

  Future<void> _loadDataForScreens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber != null && apiKey != null) {
        // استخدام الطلب الشامل لجلب جميع البيانات في طلب واحد
        final completeResponse = await EmployeeApiService.getCompleteProfile(
          jobNumber: jobNumber,
          apiKey: apiKey,
        );

        if (completeResponse.success && completeResponse.data != null) {
          final data = completeResponse.data!;

          setState(() {
            _attendanceList = data.attendance;
            // دمج السيارة الحالية مع السيارات السابقة
            _carsList = [
              if (data.currentCar != null) data.currentCar!,
              ...data.previousCars,
            ];
            _salariesList = data.salaries;
            _employeeName = data.employee.name;
            // جلب رابط الصورة الشخصية إذا كانت متوفرة
            _employeePhotoUrl = data.employee.photos?.personal;
            _isLoading = false;
            _errorMessage = null;
          });

          debugPrint('✅ [MainNav] Data loaded successfully:');
          debugPrint('   - Employee: ${data.employee.name}');
          debugPrint('   - Attendance: ${_attendanceList.length} records');
          debugPrint('   - Cars: ${_carsList.length} cars');
          debugPrint('   - Salaries: ${_salariesList.length} records');
          debugPrint('   - Operations: ${data.operations.length} records');
        } else {
          final error = completeResponse.error ?? 'فشل جلب البيانات';
          final errorDetails =
              completeResponse.message ?? 'لا توجد تفاصيل إضافية';
          debugPrint('⚠️ [MainNav] Failed to load data: $error');
          debugPrint('⚠️ [MainNav] Error details: $errorDetails');
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'الرجاء إدخال الرقم الوظيفي والمفتاح في صفحة الإعدادات';
        });
      }
    } catch (e) {
      debugPrint('❌ [MainNav] Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال: $e';
      });
    }
  }

  List<Widget> get _screens {
    // إعادة بناء الصفحات عند تحديث البيانات
    return [
      const TrackingScreen(),
      const EmployeeProfileScreen(),
      AttendanceListScreen(
        key: ValueKey('attendance_${_attendanceList.length}'),
        attendanceList: _attendanceList,
      ),
      SalariesListScreen(
        key: ValueKey('salaries_${_salariesList.length}'),
        salariesList: _salariesList,
      ),
      CarsListScreen(
        key: ValueKey('cars_${_carsList.length}'),
        carsList: _carsList,
      ),
      const RequestsHomeScreen(),
      const LiabilitiesScreen(),
      const NotificationsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل البيانات...'),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    if (_errorMessage != null &&
        _attendanceList.isEmpty &&
        _carsList.isEmpty &&
        _salariesList.isEmpty) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDataForScreens,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      extendBodyBehindAppBar: false,
      appBar: _buildCustomAppBar(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1A237E), // Deep Indigo
                Color(0xFF0D47A1), // Deep Blue
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.location_on_rounded,
                      label: 'التتبع',
                      index: 0,
                      isActive: _currentIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.person_rounded,
                      label: 'الموظف',
                      index: 1,
                      isActive: _currentIndex == 1,
                    ),
                    _buildNavItem(
                      icon: Icons.access_time_rounded,
                      label: 'الحضور',
                      index: 2,
                      isActive: _currentIndex == 2,
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'الرواتب',
                      index: 3,
                      isActive: _currentIndex == 3,
                    ),
                    _buildNavItem(
                      icon: Icons.directions_car_rounded,
                      label: 'السيارات',
                      index: 4,
                      isActive: _currentIndex == 4,
                    ),
                    _buildNavItem(
                      icon: Icons.description_rounded,
                      label: 'الطلبات',
                      index: 5,
                      isActive: _currentIndex == 5,
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_rounded,
                      label: 'الالتزامات',
                      index: 6,
                      isActive: _currentIndex == 6,
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      label: 'الإشعارات',
                      index: 7,
                      isActive: _currentIndex == 7,
                      badgeCount: _unreadNotificationsCount > 0
                          ? _unreadNotificationsCount
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index == 7) {
            // تحديث عداد الإشعارات عند فتح صفحة الإشعارات
            _loadNotificationsCount();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        constraints: const BoxConstraints(minWidth: 60),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white, size: isActive ? 24 : 22),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    // الصفحات التي تحتوي على AppBar خاص بها لا تحتاج AppBar هنا
    final hasOwnAppBar =
        _currentIndex == 5 || _currentIndex == 6 || _currentIndex == 7;

    if (hasOwnAppBar) {
      return const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      );
    }

    final pageInfo = _getPageInfo(_currentIndex);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: pageInfo.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: pageInfo.gradient[0].withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(pageInfo.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              pageInfo.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (_unreadNotificationsCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        _unreadNotificationsCount > 99
                            ? '99+'
                            : '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                setState(() {
                  _currentIndex = 7;
                });
              },
            ),
          ),
      ],
    );
  }

  ({String title, String? subtitle, IconData icon, List<Color> gradient})
  _getPageInfo(int index) {
    switch (index) {
      case 0:
        return (
          title: 'التتبع',
          subtitle: 'تتبع الموقع والحركة',
          icon: Icons.location_on_rounded,
          gradient: const [
            Color(0xFF06B6D4), // Cyan
            Color(0xFF0891B2), // Darker Cyan
          ],
        );
      case 1:
        return (
          title: 'الملف الشخصي',
          subtitle: 'بيانات الموظف',
          icon: Icons.person_rounded,
          gradient: const [
            Color(0xFF8B5CF6), // Purple
            Color(0xFF7C3AED), // Darker Purple
          ],
        );
      case 2:
        return (
          title: 'الحضور',
          subtitle: 'سجل الحضور والانصراف',
          icon: Icons.access_time_rounded,
          gradient: const [
            Color(0xFF10B981), // Green
            Color(0xFF059669), // Darker Green
          ],
        );
      case 3:
        return (
          title: 'الرواتب',
          subtitle: 'سجل الرواتب',
          icon: Icons.account_balance_wallet_rounded,
          gradient: const [
            Color(0xFFF59E0B), // Amber
            Color(0xFFD97706), // Darker Amber
          ],
        );
      case 4:
        return (
          title: 'السيارات',
          subtitle: 'السيارات المرتبطة',
          icon: Icons.directions_car_rounded,
          gradient: const [
            Color(0xFF3B82F6), // Blue
            Color(0xFF2563EB), // Darker Blue
          ],
        );
      case 5:
        return (
          title: 'الطلبات',
          subtitle: 'إنشاء ومتابعة الطلبات',
          icon: Icons.description_rounded,
          gradient: const [
            Color(0xFF06B6D4), // Cyan
            Color(0xFF8B5CF6), // Purple
          ],
        );
      case 6:
        return (
          title: 'الالتزامات المالية',
          subtitle: 'الالتزامات والمدفوعات',
          icon: Icons.account_balance_rounded,
          gradient: const [
            Color(0xFFEF4444), // Red
            Color(0xFFDC2626), // Darker Red
          ],
        );
      case 7:
        return (
          title: 'الإشعارات',
          subtitle: _unreadNotificationsCount > 0
              ? '$_unreadNotificationsCount إشعار غير مقروء'
              : 'عرض الإشعارات',
          icon: Icons.notifications_rounded,
          gradient: const [
            Color(0xFF8B5CF6), // Purple
            Color(0xFF06B6D4), // Cyan
          ],
        );
      default:
        return (
          title: 'نظام نُظم',
          subtitle: 'نظام إدارة الموظفين',
          icon: Icons.dashboard_rounded,
          gradient: const [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF06B6D4), // Cyan
              Color(0xFF8B5CF6), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // صورة المستخدم
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child:
                          _employeePhotoUrl != null &&
                              _employeePhotoUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _employeePhotoUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      );
                                    },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 16),
                    // اسم المستخدم أو اسم النظام
                    Text(
                      _employeeName ?? 'نظام نُظم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _employeeName != null
                          ? 'نظام إدارة الموظفين'
                          : 'نظام إدارة الموظفين',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      _buildDrawerItem(
                        icon: Icons.description_rounded,
                        title: 'الطلبات',
                        subtitle: 'إنشاء ومتابعة الطلبات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestsHomeScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'الالتزامات المالية',
                        subtitle: 'عرض الالتزامات والمدفوعات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LiabilitiesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.notifications_rounded,
                        title: 'الإشعارات',
                        subtitle: 'عرض الإشعارات والتنبيهات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      _buildDrawerItem(
                        icon: Icons.location_on_rounded,
                        title: 'التتبع',
                        subtitle: 'تتبع الموقع',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        title: 'الملف الشخصي',
                        subtitle: 'بيانات الموظف',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.access_time_rounded,
                        title: 'الحضور',
                        subtitle: 'سجل الحضور',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'الرواتب',
                        subtitle: 'سجل الرواتب',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.directions_car_rounded,
                        title: 'السيارات',
                        subtitle: 'السيارات المرتبطة',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 4;
                          });
                        },
                      ),
                      const Divider(height: 32),
                      _buildDrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'تسجيل الخروج',
                        subtitle: 'الخروج من الحساب',
                        color: Colors.red,
                        onTap: () async {
                          Navigator.pop(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تسجيل الخروج'),
                              content: const Text(
                                'هل أنت متأكد من تسجيل الخروج؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('تسجيل الخروج'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await AuthService.logout();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? const Color(0xFF1E3C72);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: itemColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: itemColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: itemColor,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
