import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/employee_model.dart';

/// ============================================
/// 🆔 شاشة بطاقة هوية الموظف - Employee ID Card Screen
/// تصميم احترافي مميز يشبه بطاقة الهوية الوظيفية
/// ============================================
class EmployeeIdCardScreen extends StatefulWidget {
  final Employee employee;
  final String? city; // المدينة - يمكن إضافتها من API لاحقاً
  final String? departmentMapUrl; // رابط خريطة الدائرة

  const EmployeeIdCardScreen({
    super.key,
    required this.employee,
    this.city,
    this.departmentMapUrl,
  });

  @override
  State<EmployeeIdCardScreen> createState() => _EmployeeIdCardScreenState();
}

class _EmployeeIdCardScreenState extends State<EmployeeIdCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // حساب الأحجام المتجاوبة
    final cardWidth = isLandscape ? screenWidth * 0.7 : screenWidth * 0.95;
    final cardHeight = isLandscape ? screenHeight * 0.85 : screenHeight * 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'بطاقة هوية الموظف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // زر تصدير PDF
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'تصدير كـ PDF',
            onPressed: _isExporting ? null : () => _exportToPdf(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: cardWidth,
              constraints: BoxConstraints(maxWidth: 600, minHeight: cardHeight),
              decoration: BoxDecoration(
                // خلفية متدرجة احترافية
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E), // أزرق داكن
                    Color(0xFF283593), // أزرق متوسط
                    Color(0xFF3949AB), // أزرق فاتح
                    Color(0xFF1A237E), // أزرق داكن
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                // حدود احترافية
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  // ظل خارجي قوي
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                  // ظل داخلي ناعم
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  // توهج خفيف
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -5),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    // نمط خلفي احترافي
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ========== رأس البطاقة مع الشعار ==========
                      _buildCardHeader(context),
                      const SizedBox(height: 28),

                      // ========== الصورة الشخصية ==========
                      _buildPhotoSection(context),
                      const SizedBox(height: 24),

                      // ========== الاسم ==========
                      _buildNameSection(context),
                      const SizedBox(height: 16),

                      // ========== رقم الموظف بشكل بارز ==========
                      _buildJobNumberBadge(context),
                      const SizedBox(height: 24),

                      // ========== خط فاصل احترافي ==========
                      _buildDivider(),
                      const SizedBox(height: 24),

                      // ========== المعلومات الوظيفية ==========
                      _buildWorkInfoSection(context),
                      const SizedBox(height: 20),

                      // ========== المعلومات الشخصية ==========
                      _buildPersonalInfoSection(context),
                      const SizedBox(height: 20),

                      // ========== تاريخ انتهاء الهوية ==========
                      _buildExpiryDateSection(context),
                      const SizedBox(height: 24),

                      // ========== زر تصدير PDF ==========
                      _buildExportButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء رأس البطاقة مع الشعار
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // شعار الشركة/المؤسسة
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/app_logo.png',
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.business_rounded,
                color: Colors.white,
                size: 32,
              );
            },
          ),
        ),
        // نص "بطاقة هوية الموظف"
        Expanded(
          child: Column(
            children: [
              const Text(
                'بطاقة هوية الموظف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        // أيقونة بطاقة الهوية
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.credit_card_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }

  /// بناء قسم الصورة الشخصية
  Widget _buildPhotoSection(BuildContext context) {
    final photoUrl = widget.employee.photos?.personal;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // دائرة خلفية متوهجة
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // حدود خارجية
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
          // الصورة الرئيسية
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          // شارة نشطة
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// صورة افتراضية
  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: const Icon(Icons.person_rounded, size: 80, color: Colors.white),
    );
  }

  /// بناء قسم الاسم
  Widget _buildNameSection(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.employee.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.transparent, Colors.white, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  /// بناء شارة رقم الموظف بشكل بارز
  Widget _buildJobNumberBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرقم الوظيفي',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.employee.jobNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// خط فاصل احترافي
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// بناء قسم المعلومات الوظيفية
  Widget _buildWorkInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'المعلومات الوظيفية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // شبكة المعلومات
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.apartment_rounded,
                  label: 'الدائرة',
                  value: widget.employee.department.isNotEmpty
                      ? widget.employee.department
                      : 'غير محدد',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.business_center_rounded,
                  label: 'القسم',
                  value: widget.employee.section.isNotEmpty
                      ? widget.employee.section
                      : 'غير محدد',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.badge_rounded,
            label: 'المنصب',
            value: widget.employee.position.isNotEmpty
                ? widget.employee.position
                : 'غير محدد',
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  /// بناء قسم المعلومات الشخصية
  Widget _buildPersonalInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // معلومات إضافية
          if (widget.employee.nationalId != null &&
              widget.employee.nationalId!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.credit_card_rounded,
              label: 'الهوية الوطنية',
              value: widget.employee.nationalId!,
            ),
          if (widget.employee.nationalId != null &&
              widget.employee.nationalId!.isNotEmpty)
            const SizedBox(height: 12),
          if (widget.employee.phone != null &&
              widget.employee.phone!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.phone_rounded,
              label: 'رقم الجوال',
              value: widget.employee.phone!,
            ),
          if (widget.employee.phone != null &&
              widget.employee.phone!.isNotEmpty)
            const SizedBox(height: 12),
          if (widget.employee.email != null &&
              widget.employee.email!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.email_rounded,
              label: 'البريد الإلكتروني',
              value: widget.employee.email!,
            ),
          if (widget.employee.email != null &&
              widget.employee.email!.isNotEmpty)
            const SizedBox(height: 12),
          if (widget.city != null || widget.employee.address != null)
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              label: 'المدينة / العنوان',
              value: widget.city ?? widget.employee.address ?? 'غير محدد',
            ),
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// بناء صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر تصدير PDF - تصميم احترافي مميز
  Widget _buildExportButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade600,
            Colors.red.shade700,
            Colors.red.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting ? null : () => _exportToPdf(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isExporting)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isExporting ? 'جاري التصدير...' : 'تصدير كملف PDF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isExporting) ...[
                        const SizedBox(height: 4),
                        Text(
                          'حفظ ومشاركة بطاقة الهوية',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isExporting) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء قسم تاريخ انتهاء الهوية
  Widget _buildExpiryDateSection(BuildContext context) {
    final expiryDate = widget.employee.residenceExpiryDate;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    final isExpiringSoon =
        expiryDate != null &&
        expiryDate.isAfter(DateTime.now()) &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.warning_rounded;
      statusText = 'منتهية الصلاحية';
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule_rounded;
      statusText = 'تنتهي قريباً';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'سارية المفعول';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.3),
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                'تاريخ انتهاء الإقامة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            expiryDate != null
                ? DateFormat('yyyy-MM-dd', 'ar').format(expiryDate)
                : 'غير محدد',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          if (expiryDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// تحميل خط عربي للـ PDF
  Future<pw.Font?> _loadArabicFont() async {
    // محاولة تحميل خط Cairo من Google Fonts (TTF فقط)
    try {
      final fontUrl =
          'https://fonts.gstatic.com/s/cairo/v28/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQ1z0hGA-W1ToLQ-HmkA.ttf';
      final response = await http
          .get(Uri.parse(fontUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final fontData = ByteData.view(response.bodyBytes.buffer);
        final font = pw.Font.ttf(fontData);
        debugPrint('✅ [PDF] Arabic font loaded from Google Fonts');
        return font;
      }
    } catch (e) {
      debugPrint('⚠️ [PDF] Error loading Arabic font from URL: $e');
    }

    // محاولة تحميل خط بديل - Amiri من GitHub
    try {
      final fontUrl3 =
          'https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf';
      final response2 = await http
          .get(Uri.parse(fontUrl3))
          .timeout(const Duration(seconds: 10));
      if (response2.statusCode == 200) {
        final fontData = ByteData.view(response2.bodyBytes.buffer);
        final font = pw.Font.ttf(fontData);
        debugPrint('✅ [PDF] Alternative Arabic font loaded');
        return font;
      }
    } catch (e) {
      debugPrint('⚠️ [PDF] Error loading alternative font: $e');
    }

    debugPrint('⚠️ [PDF] No Arabic font available, using default');
    return null;
  }

  /// تصدير بطاقة الهوية كملف PDF - التقاط الصفحة كصورة
  Future<void> _exportToPdf(BuildContext context) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // انتظار قليل لضمان أن الويدجت قد تم رسمه بالكامل
      await Future.delayed(const Duration(milliseconds: 500));

      // الحصول على RenderObject من RepaintBoundary
      final RenderRepaintBoundary? renderObject =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (renderObject == null) {
        throw Exception('لا يمكن العثور على عنصر الصفحة للتصدير');
      }

      // التقاط الصورة مع pixelRatio أقل لتقليل استهلاك الذاكرة
      ui.Image? capturedImage;
      int imageWidth = 0;
      int imageHeight = 0;

      try {
        // محاولة التقاط الصورة بـ pixelRatio 2.0 أولاً (أقل من 3.0 لتقليل الذاكرة)
        capturedImage = await renderObject.toImage(pixelRatio: 2.0);
        imageWidth = capturedImage.width;
        imageHeight = capturedImage.height;
      } catch (e) {
        debugPrint('⚠️ [PDF] Error with pixelRatio 2.0, trying 1.5: $e');
        // إذا فشل، جرب pixelRatio أقل
        try {
          capturedImage = await renderObject.toImage(pixelRatio: 1.5);
          imageWidth = capturedImage.width;
          imageHeight = capturedImage.height;
        } catch (e2) {
          debugPrint('⚠️ [PDF] Error with pixelRatio 1.5, trying 1.0: $e2');
          // آخر محاولة بـ pixelRatio 1.0
          capturedImage = await renderObject.toImage(pixelRatio: 1.0);
          imageWidth = capturedImage.width;
          imageHeight = capturedImage.height;
        }
      }

      if (imageWidth == 0 || imageHeight == 0) {
        throw Exception('فشل في التقاط صورة الصفحة');
      }

      // تحويل الصورة إلى بيانات
      ByteData? byteData;
      try {
        byteData = await capturedImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
      } finally {
        // تحرير الذاكرة فوراً بعد الحصول على البيانات
        capturedImage.dispose();
      }

      if (byteData == null) {
        throw Exception('فشل في تحويل الصورة إلى بيانات');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // تحرير byteData من الذاكرة
      byteData = null;

      // إنشاء PDF من الصورة
      final pdf = pw.Document();

      // إضافة الصورة إلى PDF
      final pdfImage = pw.MemoryImage(pngBytes);

      // حساب أبعاد الصورة لتتناسب مع صفحة A4
      // استخدام الأبعاد المحفوظة
      final pdfPageWidth = PdfPageFormat.a4.width - 40; // ناقص الهوامش
      final pdfPageHeight = PdfPageFormat.a4.height - 40;

      // حساب نسبة التكبير/التصغير
      final widthRatio = pdfPageWidth / imageWidth.toDouble();
      final heightRatio = pdfPageHeight / imageHeight.toDouble();
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      final scaledWidth = imageWidth.toDouble() * ratio;
      final scaledHeight = imageHeight.toDouble() * ratio;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                width: scaledWidth,
                height: scaledHeight,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      // حفظ ومشاركة PDF
      final output = await getTemporaryDirectory();

      // تنظيف اسم الموظف من الأحرف الخاصة التي قد تسبب مشاكل في أسماء الملفات
      String cleanEmployeeName = widget.employee.name
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // استبدال الأحرف الخاصة
          .replaceAll(RegExp(r'\s+'), '_') // استبدال المسافات بشرطة سفلية
          .trim();

      final fileName =
          'بطاقة_هوية_${cleanEmployeeName}_${widget.employee.jobNumber}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        // عرض خيارات المشاركة
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'بطاقة هوية الموظف - ${widget.employee.name}',
          subject: 'بطاقة هوية الموظف',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تصدير بطاقة الهوية بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [PDF] Error exporting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// بناء بطاقة معلومات في PDF - مطابق للتصميم في الصفحة
  pw.Widget _buildPdfInfoCard(
    String label,
    String value, {
    bool isFullWidth = false,
    String? iconEmoji,
    pw.Font? font,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(
          0x1AFFFFFF,
        ), // نفس لون الصفحة: Colors.white.withValues(alpha: 0.1)
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: PdfColors.white, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (iconEmoji != null) ...[
            pw.Text(iconEmoji, style: pw.TextStyle(fontSize: 28)),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColor.fromInt(
                0xCCFFFFFF,
              ), // نفس لون الصفحة: Colors.white.withValues(alpha: 0.8)
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// بناء صف معلومات في PDF - مطابق للتصميم في الصفحة
  pw.Widget _buildPdfInfoRow(
    String label,
    String value, {
    String? iconEmoji,
    pw.Font? font,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(
          0x1AFFFFFF,
        ), // نفس لون الصفحة: Colors.white.withValues(alpha: 0.1)
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.white, width: 1.5),
      ),
      child: pw.Row(
        children: [
          if (iconEmoji != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(
                  0x33FFFFFF,
                ), // نفس لون الصفحة: Colors.white.withValues(alpha: 0.2)
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(iconEmoji, style: pw.TextStyle(fontSize: 20)),
            ),
            pw.SizedBox(width: 16),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(
                      0xCCFFFFFF,
                    ), // نفس لون الصفحة: Colors.white.withValues(alpha: 0.8)
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
