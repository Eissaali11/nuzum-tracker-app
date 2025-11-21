import 'package:flutter/material.dart';

import '../models/employee_model.dart';

/// ============================================
/// 👤 بطاقة معلومات الموظف - Employee Profile Card
/// تصميم احترافي متجاوب مع جميع الشاشات
/// ============================================
class EmployeeProfileCard extends StatelessWidget {
  final Employee employee;

  const EmployeeProfileCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 400;

    // أحجام متجاوبة
    final avatarSize = isSmallScreen ? 90.0 : (isMediumScreen ? 100.0 : 110.0);
    final nameSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
    final horizontalPadding = isSmallScreen
        ? 16.0
        : (isMediumScreen ? 20.0 : 24.0);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: 8),
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
        borderRadius: BorderRadius.circular(24),
        // حدود احترافية
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          // ظل خارجي قوي
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          // ظل داخلي ناعم
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          // توهج خفيف
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isSmallScreen ? 24 : 28,
          ),
          decoration: BoxDecoration(
            // نمط خلفي احترافي
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ========== رأس البطاقة مع الشعار ==========
              _buildCardHeader(isSmallScreen),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // ========== الصورة الشخصية مع تأثير متوهج ==========
              _buildProfileAvatar(avatarSize),

              SizedBox(height: isSmallScreen ? 18 : 22),

              // ========== الاسم ==========
              _buildNameSection(nameSize),

              SizedBox(height: isSmallScreen ? 8 : 10),

              // ========== رقم الموظف بشكل بارز ==========
              _buildJobNumberBadge(isSmallScreen),

              SizedBox(height: isSmallScreen ? 18 : 22),

              // ========== خط فاصل احترافي ==========
              _buildDivider(),

              SizedBox(height: isSmallScreen ? 18 : 22),

              // ========== معلومات الموظف في شبكة ==========
              _buildInfoGrid(isSmallScreen),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // ========== القسم والمنصب ==========
              _buildDepartmentSection(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء الصورة الشخصية مع تأثيرات
  Widget _buildProfileAvatar(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // دائرة خلفية متوهجة
        Container(
          width: size + 20,
          height: size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent],
            ),
          ),
        ),
        // حدود خارجية
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        // الصورة الرئيسية
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: employee.photos?.personal != null
                ? Image.network(
                    employee.photos!.personal!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(size),
                  )
                : _buildDefaultAvatar(size),
          ),
        ),
        // شارة نشطة
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// صورة افتراضية
  Widget _buildDefaultAvatar(double size) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.5,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  /// بناء قسم الاسم
  Widget _buildNameSection(double fontSize) {
    return Column(
      children: [
        Text(
          employee.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
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

  /// شبكة المعلومات
  Widget _buildInfoGrid(bool isSmallScreen) {
    return Row(
      children: [
        // قسم القسم
        Expanded(
          child: _buildInfoChip(
            icon: Icons.apartment_rounded,
            label: 'القسم',
            value: employee.department.isNotEmpty
                ? employee.department
                : 'غير محدد',
            isSmallScreen: isSmallScreen,
          ),
        ),
        const SizedBox(width: 12),
        // قسم المنصب
        Expanded(
          child: _buildInfoChip(
            icon: Icons.work_rounded,
            label: 'المنصب',
            value: employee.position.isNotEmpty
                ? employee.position
                : 'غير محدد',
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }

  /// بناء شريحة معلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: isSmallScreen ? 22 : 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// خط فاصل ديكوري
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// بناء رأس البطاقة مع الشعار
  Widget _buildCardHeader(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // شعار الشركة/المؤسسة
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Image.asset(
            'assets/icons/app_logo.png',
            width: isSmallScreen ? 32 : 40,
            height: isSmallScreen ? 32 : 40,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.business_rounded,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              );
            },
          ),
        ),
        // نص "بطاقة هوية الموظف"
        Expanded(
          child: Column(
            children: [
              Text(
                'بطاقة هوية الموظف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                width: 80,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        // أيقونة بطاقة الهوية
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.credit_card_rounded,
            color: Colors.white,
            size: isSmallScreen ? 24 : 28,
          ),
        ),
      ],
    );
  }

  /// بناء شارة رقم الموظف بشكل بارز
  Widget _buildJobNumberBadge(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 24,
        vertical: isSmallScreen ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.badge_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرقم الوظيفي',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                employee.jobNumber,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء قسم القسم والمنصب (تم دمجه في _buildInfoGrid)
  Widget _buildDepartmentSection(bool isSmallScreen) {
    // هذا القسم تم دمجه في _buildInfoGrid
    // نتركه فارغاً أو يمكن إضافة معلومات إضافية هنا
    return const SizedBox.shrink();
  }
}
