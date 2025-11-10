import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attendance_model.dart';
import '../utils/attendance_calculator.dart';
import '../widgets/attendance_item.dart';

/// ============================================
/// 📅 صفحة قائمة الحضور - Attendance Dashboard
/// تصميم احترافي مع داشبورد منسق
/// ============================================
class AttendanceListScreen extends StatefulWidget {
  final List<Attendance> attendanceList;

  const AttendanceListScreen({super.key, required this.attendanceList});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late List<Attendance> _displayList;

  // خط عربي أنيق
  TextStyle get arabicFont {
    return const TextStyle(
      fontFamily: 'Noto Sans Arabic',
      fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedYear = _selectedDate.year;
    _selectedMonth = _selectedDate.month;
    _displayList = widget.attendanceList;
  }

  @override
  void didUpdateWidget(AttendanceListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceList != widget.attendanceList) {
      setState(() {
        _displayList = widget.attendanceList;
      });
    }
  }

  List<Attendance> get _filteredAttendance {
    return AttendanceCalculator.getAttendanceByMonth(
      _displayList,
      _selectedYear,
      _selectedMonth,
    );
  }

  Map<String, dynamic> get _monthlyStats {
    return AttendanceCalculator.calculateMonthlyStats(
      _displayList,
      _selectedYear,
      _selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _monthlyStats;
    final attendanceRate = stats['attendanceRate'] as double;
    final presentDays = stats['presentDays'] as int;
    final absentDays = stats['absentDays'] as int;
    final lateDays = stats['lateDays'] as int;
    final earlyLeaveDays = stats['earlyLeaveDays'] as int;
    final totalDays = stats['totalDays'] as int;
    final totalHours = stats['totalHours'] as double;
    final holidayDays = stats['holidayDays'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title: Text(
              'داشبورد الحضور',
              style: arabicFont.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: _selectMonth,
                  tooltip: 'اختيار الشهر',
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _displayList.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // بطاقة الشهر المحدد
                        _buildMonthSelectorCard(),
                        const SizedBox(height: 16),

                        // بطاقة نسبة الحضور الرئيسية
                        _buildMainAttendanceCard(attendanceRate, totalDays),
                        const SizedBox(height: 16),

                        // بطاقات الإحصائيات
                        _buildStatisticsCards(
                          presentDays,
                          absentDays,
                          lateDays,
                          earlyLeaveDays,
                          totalHours,
                          holidayDays,
                        ),
                        const SizedBox(height: 16),

                        // قائمة الحضور
                        _buildAttendanceListHeader(),
                        const SizedBox(height: 12),
                        _buildAttendanceList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد بيانات حضور',
            style: arabicFont.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض بيانات الحضور هنا عند توفرها',
            style: arabicFont.copyWith(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الشهر المحدد',
                style: arabicFont.copyWith(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(_selectedDate),
                style: arabicFont.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAttendanceCard(double rate, int totalDays) {
    final rateColor = rate >= 90
        ? Colors.green
        : rate >= 70
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة الحضور',
                style: arabicFont.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rate >= 90
                      ? 'ممتاز'
                      : rate >= 70
                      ? 'جيد'
                      : 'يحتاج تحسين',
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 16,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: arabicFont.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: rateColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من $totalDays يوم',
                    style: arabicFont.copyWith(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(
    int present,
    int absent,
    int late,
    int earlyLeave,
    double hours,
    int holiday,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'حاضر',
                present.toString(),
                Colors.green,
                Icons.check_circle_rounded,
                'أيام',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'غائب',
                absent.toString(),
                Colors.red,
                Icons.cancel_rounded,
                'أيام',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'متأخر',
                late.toString(),
                Colors.orange,
                Icons.schedule_rounded,
                'مرات',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'خروج مبكر',
                earlyLeave.toString(),
                Colors.blue,
                Icons.exit_to_app_rounded,
                'مرات',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي الساعات',
                hours.toStringAsFixed(0),
                Colors.purple,
                Icons.access_time_rounded,
                'ساعة',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'إجازات',
                holiday.toString(),
                Colors.teal,
                Icons.beach_access_rounded,
                'يوم',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: arabicFont.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: arabicFont.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: arabicFont.copyWith(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'سجل الحضور',
          style: arabicFont.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredAttendance.length} سجل',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_filteredAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد سجلات حضور لهذا الشهر',
              style: arabicFont.copyWith(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredAttendance.map((attendance) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AttendanceItem(attendance: attendance),
        );
      }).toList(),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3C72),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
    }
  }
}
