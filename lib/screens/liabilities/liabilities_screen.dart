import 'package:flutter/material.dart';

import '../../models/liability_model.dart';
import '../../services/liabilities_api_service.dart';

/// ============================================
/// 💳 صفحة الالتزامات المالية - Liabilities Screen
/// ============================================
class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen>
    with SingleTickerProviderStateMixin {
  LiabilitiesSummary? _summary;
  FinancialSummary? _financialSummary;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // 'all', 'advance', 'damage', 'debt'
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final liabilitiesResult = await LiabilitiesApiService.getLiabilities();
      final financialResult = await LiabilitiesApiService.getFinancialSummary();

      if (!mounted) return;
      if (liabilitiesResult['success'] == true) {
        setState(() {
          _summary = liabilitiesResult['data'] as LiabilitiesSummary;
        });
      }
      if (financialResult['success'] == true) {
        setState(() {
          _financialSummary = financialResult['data'] as FinancialSummary;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  List<Liability> get _filteredLiabilities {
    if (_summary == null) return [];
    if (_selectedFilter == 'all') return _summary!.liabilities;
    return _summary!.liabilities
        .where((l) => l.type == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من تهيئة TabController
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadData,
                tooltip: 'تحديث',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                child: TabBar(
                  controller: _tabController!,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(
                      height: 45,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('الالتزامات'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 45,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.summarize_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('الملخص المالي'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                ? _buildErrorWidget()
                : SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: TabBarView(
                      controller: _tabController!,
                      children: [
                        _buildLiabilitiesTab(),
                        _buildFinancialSummaryTab(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesTab() {
    if (_summary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('لا توجد بيانات'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8B5CF6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 24),
            // Filter Chips
            if (_summary!.liabilities.isNotEmpty) _buildFilterChips(),
            const SizedBox(height: 24),
            // Liabilities List
            _buildLiabilitiesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ملخص الالتزامات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'إجمالي الالتزامات',
                  _summary!.totalLiabilities.toStringAsFixed(2),
                  Icons.account_balance_wallet_rounded,
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildStatCard(
                  'المبلغ المسدد',
                  _summary!.totalPaid.toStringAsFixed(2),
                  Icons.check_circle_rounded,
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildStatCard(
                  'المبلغ المتبقي',
                  _summary!.totalRemaining.toStringAsFixed(2),
                  Icons.pending_actions_rounded,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value ريال',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9)),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'الكل', Icons.list_rounded),
          const SizedBox(width: 8),
          _buildFilterChip(
            'advance',
            'السلف',
            Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterChip('damage', 'التلفيات', Icons.warning_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('debt', 'الديون', Icons.money_off_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      onSelected: (selected) {
        if (!mounted) return;
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF8B5CF6),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1F2937),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildLiabilitiesList() {
    final filtered = _filteredLiabilities;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد التزامات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد التزامات تطابق الفلتر المحدد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group by type
    final grouped = <String, List<Liability>>{};
    for (final liability in filtered) {
      grouped.putIfAbsent(liability.type, () => []).add(liability);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: _getTypeGradient(entry.key),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLiabilityIcon(entry.key),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getTypeLabel(entry.key),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (liability) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildLiabilityCard(liability),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLiabilityCard(Liability liability) {
    final typeGradient = _getTypeGradient(liability.type);
    final statusColor = _getStatusColor(liability.status);
    final progress = liability.progressPercentage / 100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // يمكن إضافة صفحة تفاصيل الالتزام لاحقاً
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: typeGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getLiabilityIcon(liability.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            liability.description,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'التزام #${liability.id}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(liability.status),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusLabel(liability.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amounts Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildAmountCard(
                            'المبلغ الكلي',
                            liability.amount.toStringAsFixed(2),
                            Colors.red,
                            Icons.attach_money_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAmountCard(
                            'المسدد',
                            liability.paid.toStringAsFixed(2),
                            Colors.green,
                            Icons.check_circle_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAmountCard(
                            'المتبقي',
                            liability.remaining.toStringAsFixed(2),
                            Colors.orange,
                            Icons.pending_actions_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'نسبة الإنجاز',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '${liability.progressPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getLiabilityColor(liability.type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getLiabilityColor(liability.type),
                        ),
                      ),
                    ),
                    if (liability.monthlyInstallment != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'القسط الشهري',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${liability.monthlyInstallment!.toStringAsFixed(2)} ريال',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (liability.remainingInstallments !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${liability.remainingInstallments} أقساط متبقية',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (liability.dueDate != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تاريخ الاستحقاق: ${_formatDate(liability.dueDate!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
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

  Widget _buildAmountCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value ريال',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryTab() {
    if (_financialSummary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('لا توجد بيانات'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8B5CF6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Employee Info Card
            _buildEmployeeInfoCard(),
            const SizedBox(height: 24),
            // Financial Overview
            _buildFinancialOverviewCard(),
            const SizedBox(height: 24),
            // Active Advances
            if (_financialSummary!.activeAdvances.isNotEmpty) ...[
              _buildSectionHeader(
                'السلف النشطة',
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 16),
              ..._financialSummary!.activeAdvances.map(
                (advance) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLiabilityCard(advance),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Active Damages
            if (_financialSummary!.activeDamages.isNotEmpty) ...[
              _buildSectionHeader('التلفيات النشطة', Icons.warning_rounded),
              const SizedBox(height: 16),
              ..._financialSummary!.activeDamages.map(
                (damage) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLiabilityCard(damage),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _financialSummary!.employeeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'رقم الموظف: ${_financialSummary!.employeeNumber}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverviewCard() {
    final deductionPercent = _financialSummary!.deductionPercentage;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.summarize_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'الملخص المالي',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFinancialRow(
            'الراتب الحالي',
            '${_financialSummary!.currentSalary.toStringAsFixed(2)} ريال',
            Icons.account_balance_wallet_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildFinancialRow(
            'إجمالي الالتزامات',
            '${_financialSummary!.totalLiabilities.toStringAsFixed(2)} ريال',
            Icons.receipt_long_rounded,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildFinancialRow(
            'صافي الراتب بعد الخصومات',
            '${_financialSummary!.netSalaryAfterDeductions.toStringAsFixed(2)} ريال',
            Icons.account_balance_rounded,
            Colors.green,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'نسبة الخصم',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '${deductionPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: deductionPercent > 30
                      ? Colors.red
                      : deductionPercent > 15
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: deductionPercent / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                deductionPercent > 30
                    ? Colors.red
                    : deductionPercent > 15
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  LinearGradient _getTypeGradient(String type) {
    switch (type) {
      case 'advance':
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        );
      case 'damage':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        );
      case 'debt':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        );
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'advance':
        return 'السلف';
      case 'damage':
        return 'التلفيات';
      case 'debt':
        return 'الديون';
      default:
        return type;
    }
  }

  IconData _getLiabilityIcon(String type) {
    switch (type) {
      case 'advance':
        return Icons.account_balance_wallet_rounded;
      case 'damage':
        return Icons.warning_rounded;
      case 'debt':
        return Icons.money_off_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _getLiabilityColor(String type) {
    switch (type) {
      case 'advance':
        return Colors.amber;
      case 'damage':
        return Colors.red;
      case 'debt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.pending_actions_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
