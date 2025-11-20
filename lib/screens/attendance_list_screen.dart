import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/attendance_model.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';
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

  final _localizations = AppLocalizations();

  // استخدام نفس الخط العام للتطبيق (Google Fonts Cairo)
  TextStyle _getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isArabic = LanguageService.instance.isArabic;
    if (isArabic) {
      try {
        return GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      } catch (e) {
        // في حالة فشل تحميل Cairo، استخدم الخط الافتراضي من Theme
        return TextStyle(
          fontFamily: 'Noto Sans Arabic',
          fontFamilyFallback: const ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      }
    } else {
      return TextStyle(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'],
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
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
              _localizations.attendanceDashboard,
              style: _getTextStyle(
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
                  tooltip: _localizations.selectMonth,
                ),
              ),
            ],
          ),
          if (_displayList.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بطاقة الشهر المحدد
                    _buildMonthSelectorCard(),
                    const SizedBox(height: 16),

                    // داش بورد تحليلي مع دوائر تقدم
                    _buildAnalyticalDashboard(
                      attendanceRate: attendanceRate,
                      totalDays: totalDays,
                      presentDays: presentDays,
                      absentDays: absentDays,
                      lateDays: lateDays,
                      earlyLeaveDays: earlyLeaveDays,
                      totalHours: totalHours,
                      holidayDays: holidayDays,
                    ),
                    const SizedBox(height: 16),

                    // قائمة الحضور
                    _buildAttendanceListHeader(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          // قائمة الحضور في SliverList منفصلة
          if (_displayList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildAttendanceListSliver(),
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
            _localizations.noAttendanceData,
            style: _getTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizations.attendanceDataWillAppear,
            style: _getTextStyle(fontSize: 14, color: Colors.grey[600]),
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
                _localizations.selectedMonth,
                style: _getTextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM yyyy', LanguageService.instance.isArabic ? 'ar' : 'en').format(_selectedDate),
                style: _getTextStyle(
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

  /// بناء داش بورد تحليلي احترافي مع دوائر تقدم
  Widget _buildAnalyticalDashboard({
    required double attendanceRate,
    required int totalDays,
    required int presentDays,
    required int absentDays,
    required int lateDays,
    required int earlyLeaveDays,
    required double totalHours,
    required int holidayDays,
  }) {
    final rateColor = attendanceRate >= 90
        ? Colors.green
        : attendanceRate >= 70
            ? Colors.orange
            : Colors.red;

    final workingDays = totalDays - holidayDays;
    final presentRate = workingDays > 0 ? (presentDays / workingDays * 100) : 0.0;
    final absentRate = workingDays > 0 ? (absentDays / workingDays * 100) : 0.0;
    final lateRate = workingDays > 0 ? (lateDays / workingDays * 100) : 0.0;
    final earlyLeaveRate = workingDays > 0 ? (earlyLeaveDays / workingDays * 100) : 0.0;

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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الداش بورد
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [rateColor, rateColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: rateColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('📊', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'داش بورد تحليلي',
                        style: _getTextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تحليل شامل للحضور والانصراف',
                        style: _getTextStyle(
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
            // بطاقة نسبة الحضور الرئيسية مع دائرة تقدم
            _buildMainRateCard(attendanceRate, totalDays, rateColor),
            const SizedBox(height: 20),
            // خط فاصل
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // بطاقات الإحصائيات مع دوائر تقدم
            Text(
              'إحصائيات مفصلة',
              style: _getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            // الصف الأول: الحضور والغياب
            Row(
              children: [
                Expanded(
                  child: _buildCircularStatCard(
                    title: _localizations.present,
                    value: presentDays,
                    total: workingDays,
                    percentage: presentRate,
                    color: Colors.green,
                    emoji: '✅',
                    icon: Icons.check_circle_rounded,
                    unit: _localizations.days,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularStatCard(
                    title: _localizations.absent,
                    value: absentDays,
                    total: workingDays,
                    percentage: absentRate,
                    color: Colors.red,
                    emoji: '❌',
                    icon: Icons.cancel_rounded,
                    unit: _localizations.days,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // الصف الثاني: التأخير والخروج المبكر
            Row(
              children: [
                Expanded(
                  child: _buildCircularStatCard(
                    title: _localizations.late,
                    value: lateDays,
                    total: workingDays,
                    percentage: lateRate,
                    color: Colors.orange,
                    emoji: '⏰',
                    icon: Icons.schedule_rounded,
                    unit: _localizations.times,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularStatCard(
                    title: _localizations.earlyLeave,
                    value: earlyLeaveDays,
                    total: workingDays,
                    percentage: earlyLeaveRate,
                    color: Colors.blue,
                    emoji: '🚪',
                    icon: Icons.exit_to_app_rounded,
                    unit: _localizations.times,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // الصف الثالث: الساعات والإجازات
            Row(
              children: [
                Expanded(
                  child: _buildHoursCard(totalHours),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularStatCard(
                    title: _localizations.holidays,
                    value: holidayDays,
                    total: totalDays,
                    percentage: totalDays > 0 ? (holidayDays / totalDays * 100) : 0.0,
                    color: Colors.teal,
                    emoji: '🏖️',
                    icon: Icons.beach_access_rounded,
                    unit: _localizations.day,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة نسبة الحضور الرئيسية مع دائرة تقدم كبيرة
  Widget _buildMainRateCard(double rate, int totalDays, Color rateColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rateColor.withValues(alpha: 0.1),
            Colors.white,
            rateColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rateColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rateColor.withValues(alpha: 0.2),
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
                'نسبة الحضور الإجمالية',
                style: _getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rateColor, rateColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: rateColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  rate >= 90
                      ? 'ممتاز'
                      : rate >= 70
                          ? 'جيد'
                          : 'يحتاج تحسين',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // دائرة تقدم كبيرة مع النسبة المئوية
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 20,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: _getTextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: rateColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rateColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'من $totalDays يوم',
                      style: _getTextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
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

  /// بطاقة إحصائية مع دائرة تقدم
  Widget _buildCircularStatCard({
    required String title,
    required int value,
    required int total,
    required double percentage,
    required Color color,
    required String emoji,
    required IconData icon,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: _getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // دائرة تقدم مع القيمة
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    value.toString(),
                    style: _getTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: _getTextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // الوحدة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              unit,
              style: _getTextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الساعات الإجمالية
  Widget _buildHoursCard(double totalHours) {
    final hoursColor = Colors.purple;
    final avgHoursPerDay = totalHours > 0 && _filteredAttendance.isNotEmpty
        ? totalHours / _filteredAttendance.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hoursColor.withValues(alpha: 0.1),
            Colors.white,
            hoursColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hoursColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hoursColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [hoursColor, hoursColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: hoursColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⏱️', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _localizations.totalHours,
                  style: _getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalHours.toStringAsFixed(1),
            style: _getTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: hoursColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _localizations.hour,
            style: _getTextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (avgHoursPerDay > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hoursColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'متوسط ${avgHoursPerDay.toStringAsFixed(1)} ساعة/يوم',
                style: _getTextStyle(
                  fontSize: 11,
                  color: hoursColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _localizations.attendanceRecord,
          style: _getTextStyle(
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
            '${_filteredAttendance.length} ${_localizations.records}',
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

  /// بناء قائمة الحضور كـ SliverList للأداء الأفضل
  Widget _buildAttendanceListSliver() {
    if (_filteredAttendance.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
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
                _localizations.noAttendanceRecords,
                style: _getTextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AttendanceItem(attendance: _filteredAttendance[index]),
          );
        },
        childCount: _filteredAttendance.length,
      ),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      locale: LanguageService.instance.currentLocale,
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

