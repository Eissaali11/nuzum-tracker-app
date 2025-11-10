import 'package:flutter/material.dart';

import '../models/salary_model.dart';
import '../utils/responsive_helper.dart';
import '../widgets/salary_item.dart';

/// ============================================
/// 💰 صفحة قائمة الرواتب - Salaries List Screen
/// ============================================
class SalariesListScreen extends StatelessWidget {
  final List<Salary> salariesList;

  const SalariesListScreen({super.key, required this.salariesList});

  List<Salary> get _displayList {
    // استخدام البيانات الفعلية من API فقط
    return salariesList;
  }

  @override
  Widget build(BuildContext context) {
    // حساب إجمالي الرواتب
    final totalAmount = _displayList.fold<double>(
      0.0,
      (sum, salary) => sum + salary.amount,
    );

    // حساب متوسط الراتب
    final averageAmount = _displayList.isNotEmpty
        ? totalAmount / _displayList.length
        : 0.0;

    // آخر راتب
    final lastSalary = _displayList.isNotEmpty ? _displayList.first : null;

    // أعلى راتب
    final highestSalary = _displayList.isNotEmpty
        ? _displayList.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _displayList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('لا توجد رواتب'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);
                final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                );

                return Column(
                  children: [
                    // بطاقة الإحصائيات
                    Container(
                      margin: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'إحصائيات الرواتب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          isMobile
                              ? Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'إجمالي',
                                            totalAmount.toStringAsFixed(0),
                                            Colors.green,
                                            Icons.account_balance_wallet,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatItem(
                                            'متوسط',
                                            averageAmount.toStringAsFixed(0),
                                            Colors.blue,
                                            Icons.trending_up,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatItem(
                                      'عدد',
                                      '${_displayList.length}',
                                      Colors.orange,
                                      Icons.receipt,
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'إجمالي',
                                        totalAmount.toStringAsFixed(0),
                                        Colors.green,
                                        Icons.account_balance_wallet,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 8,
                                          ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'متوسط',
                                        averageAmount.toStringAsFixed(0),
                                        Colors.blue,
                                        Icons.trending_up,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 8,
                                          ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'عدد',
                                        '${_displayList.length}',
                                        Colors.orange,
                                        Icons.receipt,
                                      ),
                                    ),
                                  ],
                                ),
                          if (lastSalary != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'آخر راتب',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastSalary.month,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${lastSalary.amount.toStringAsFixed(2)} ${lastSalary.currency}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (lastSalary.paidDate != null)
                                        Text(
                                          '${lastSalary.paidDate!.day}/${lastSalary.paidDate!.month}/${lastSalary.paidDate!.year}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (highestSalary != null &&
                              highestSalary != lastSalary) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber[300],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'أعلى راتب',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${highestSalary.amount.toStringAsFixed(2)} ${highestSalary.currency}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // قائمة الرواتب
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _displayList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SalaryItem(salary: _displayList[index]),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
