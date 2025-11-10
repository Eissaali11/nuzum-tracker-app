import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee_model.dart';

/// ============================================
/// 🆔 شاشة بطاقة هوية الموظف - Employee ID Card Screen
/// ============================================
class EmployeeIdCardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // حساب الأحجام المتجاوبة
    final cardWidth = isLandscape 
        ? screenWidth * 0.7 
        : screenWidth * 0.95;
    final cardHeight = isLandscape 
        ? screenHeight * 0.85 
        : screenHeight * 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'بطاقة هوية الموظف',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: cardWidth,
              constraints: BoxConstraints(
                maxWidth: 600,
                minHeight: cardHeight,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // العنوان الرئيسي
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  
                  // الصورة الشخصية
                  _buildPhotoSection(context),
                  const SizedBox(height: 24),
                  
                  // معلومات الموظف
                  _buildEmployeeInfo(context),
                  const SizedBox(height: 24),
                  
                  // تاريخ انتهاء الهوية (بارز)
                  _buildExpiryDateSection(context),
                  const SizedBox(height: 24),
                  
                  // الدائرة والمدينة
                  _buildLocationSection(context),
                  const SizedBox(height: 24),
                  
                  // خريطة الدائرة
                  _buildMapSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3C72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'بطاقة هوية الموظف',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final photoUrl = employee.photos?.personal;
    
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1E3C72),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                      child: CircularProgressIndicator(),
                    );
                  },
                )
              : _buildPlaceholderIcon(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildEmployeeInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoRow(
          context,
          label: 'اسم الموظف',
          value: employee.name,
          icon: Icons.person,
          isBold: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          label: 'الرقم الوظيفي',
          value: employee.jobNumber,
          icon: Icons.badge,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          label: 'القسم',
          value: employee.section,
          icon: Icons.business,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3C72).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E3C72),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateSection(BuildContext context) {
    final expiryDate = employee.residenceExpiryDate;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    final isExpiringSoon = expiryDate != null &&
        expiryDate.isAfter(DateTime.now()) &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.red.shade400, Colors.red.shade600]
              : isExpiringSoon
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isExpired
                    ? Colors.red
                    : isExpiringSoon
                        ? Colors.orange
                        : Colors.green)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpired
                    ? Icons.warning
                    : isExpiringSoon
                        ? Icons.schedule
                        : Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'تاريخ انتهاء الهوية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expiryDate != null
                ? DateFormat('yyyy-MM-dd', 'ar').format(expiryDate)
                : 'غير محدد',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          if (expiryDate != null) ...[
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? '⚠️ منتهية الصلاحية'
                  : isExpiringSoon
                      ? '⚠️ تنتهي قريباً'
                      : '✅ سارية المفعول',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildLocationCard(
            context,
            label: 'الدائرة',
            value: employee.department,
            icon: Icons.business_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLocationCard(
            context,
            label: 'المدينة',
            value: city ?? employee.address ?? 'غير محدد',
            icon: Icons.location_city,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1E3C72),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.map,
              color: Color(0xFF1E3C72),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'خريطة الدائرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: departmentMapUrl != null && departmentMapUrl!.isNotEmpty
                ? Image.network(
                    departmentMapUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildMapPlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  )
                : _buildMapPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'خريطة الدائرة',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

