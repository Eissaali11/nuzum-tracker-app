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
    final avatarSize = isSmallScreen ? 100.0 : (isMediumScreen ? 110.0 : 120.0);
    final nameSize = isSmallScreen ? 22.0 : (isMediumScreen ? 24.0 : 26.0);
    final horizontalPadding = isSmallScreen
        ? 16.0
        : (isMediumScreen ? 20.0 : 24.0);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: 8),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isSmallScreen ? 20 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF1E3C72)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ========== الصورة الشخصية مع تأثير متوهج ==========
          _buildProfileAvatar(avatarSize),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // ========== الاسم ==========
          _buildNameSection(nameSize),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // ========== معلومات الموظف في شبكة ==========
          _buildInfoGrid(isSmallScreen),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // ========== خط فاصل ديكوري ==========
          _buildDivider(),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // ========== القسم والمنصب ==========
          _buildDepartmentSection(isSmallScreen),
        ],
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
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
        Expanded(
          child: _buildInfoChip(
            icon: Icons.badge_outlined,
            label: 'الرقم الوظيفي',
            value: employee.jobNumber,
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
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

  /// بناء قسم القسم والمنصب
  Widget _buildDepartmentSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 14 : 16,
        vertical: isSmallScreen ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apartment_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: isSmallScreen ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  employee.department,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: isSmallScreen ? 16 : 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  employee.position,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
