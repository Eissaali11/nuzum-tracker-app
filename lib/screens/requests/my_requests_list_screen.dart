import 'package:flutter/material.dart';

import '../../models/request_model.dart';
import '../../services/requests_api_service.dart';
import 'request_details_screen.dart';

/// ============================================
/// 📋 صفحة قائمة الطلبات - My Requests List Screen
/// ============================================
class MyRequestsListScreen extends StatefulWidget {
  const MyRequestsListScreen({super.key});

  @override
  State<MyRequestsListScreen> createState() => _MyRequestsListScreenState();
}

class _MyRequestsListScreenState extends State<MyRequestsListScreen> {
  List<Request> _allRequests = [];
  List<Request> _filteredRequests = [];
  bool _isLoading = true;
  String? _error;

  String _selectedType = 'all';
  String _selectedStatus = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RequestsApiService.getMyRequests(
        type: _selectedType == 'all' ? null : _selectedType,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _allRequests = result['data'] as List<Request>;
          _filteredRequests = _allRequests;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _selectedType = 'all';
      _selectedStatus = 'all';
      _dateFrom = null;
      _dateTo = null;
    });
    _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Statistics Summary
                if (!_isLoading && _error == null && _allRequests.isNotEmpty)
                  _buildStatisticsSummary(),

                // Filters Card
                _buildFiltersCard(),

                // List
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildErrorWidget()
                else if (_filteredRequests.isEmpty)
                  _buildEmptyState()
                else
                  _buildRequestsList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummary() {
    final total = _allRequests.length;
    final pending = _allRequests.where((r) => r.status == 'pending').length;
    final approved = _allRequests.where((r) => r.status == 'approved').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'إجمالي الطلبات',
              '$total',
              Icons.description_rounded,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'قيد الانتظار',
              '$pending',
              Icons.pending_actions_rounded,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'معتمدة',
              '$approved',
              Icons.check_circle_rounded,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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

  Widget _buildFiltersCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Header
          InkWell(
            onTap: () {
              if (!mounted) return;
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الفلترة والبحث',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
          // Filters Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  // Type Filter
                  _buildFilterRow(
                    'النوع',
                    Icons.category_rounded,
                    _buildTypeFilter(),
                  ),
                  const SizedBox(height: 16),
                  // Status Filter
                  _buildFilterRow(
                    'الحالة',
                    Icons.info_outline_rounded,
                    _buildStatusFilter(),
                  ),
                  const SizedBox(height: 16),
                  // Date Range
                  _buildFilterRow(
                    'التاريخ',
                    Icons.calendar_today_rounded,
                    _buildDateRangeFilter(),
                  ),
                  const SizedBox(height: 16),
                  // Clear Filters Button
                  if (_selectedType != 'all' ||
                      _selectedStatus != 'all' ||
                      _dateFrom != null ||
                      _dateTo != null)
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('مسح الفلاتر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String label, IconData icon, Widget filter) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: filter),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: _selectedType,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('الكل')),
          DropdownMenuItem(value: 'advance', child: Text('طلب سلفة')),
          DropdownMenuItem(value: 'invoice', child: Text('رفع فاتورة')),
          DropdownMenuItem(value: 'car_wash', child: Text('طلب غسيل سيارة')),
          DropdownMenuItem(
            value: 'car_inspection',
            child: Text('فحص وتوثيق سيارة'),
          ),
        ],
        onChanged: (value) {
          if (!mounted) return;
          setState(() {
            _selectedType = value!;
          });
          _loadRequests();
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('الكل')),
          DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
          DropdownMenuItem(value: 'approved', child: Text('معتمد')),
          DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
          DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
        ],
        onChanged: (value) {
          if (!mounted) return;
          setState(() {
            _selectedStatus = value!;
          });
          _loadRequests();
        },
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker('من', _dateFrom, (date) {
            if (!mounted) return;
            setState(() {
              _dateFrom = date;
            });
            _loadRequests();
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDatePicker('إلى', _dateTo, (date) {
            if (!mounted) return;
            setState(() {
              _dateTo = date;
            });
            _loadRequests();
          }),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    ValueChanged<DateTime> onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: date != null ? const Color(0xFF8B5CF6) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _formatDate(date) : label,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null
                      ? const Color(0xFF1F2937)
                      : Colors.grey[600],
                  fontWeight: date != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
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
            onPressed: _loadRequests,
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

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
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
            child: Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على أي طلبات تطابق الفلاتر المحددة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRequestCard(_filteredRequests[index]),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions_rounded;
        statusLabel = 'قيد الانتظار';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'معتمد';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'مرفوض';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all_rounded;
        statusLabel = 'مكتمل';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = request.statusLabel;
    }

    LinearGradient typeGradient;
    switch (request.type) {
      case 'advance':
        typeGradient = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        );
        break;
      case 'invoice':
        typeGradient = const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
        break;
      case 'car_wash':
        typeGradient = const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        );
        break;
      case 'car_inspection':
        typeGradient = const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
        break;
      default:
        typeGradient = const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(requestId: request.id),
            ),
          );
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
                        _getRequestIcon(request.type),
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
                            request.typeLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'طلب #${request.id}',
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
                          Icon(statusIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
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
                    if (request.amount != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money_rounded,
                              size: 18,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'المبلغ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${request.amount!.toStringAsFixed(2)} ريال',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تاريخ الإنشاء',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(request.createdAt),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDeleteConfirmation(context, request),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'حذف الطلب',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRequestIcon(String type) {
    switch (type) {
      case 'advance':
        return Icons.account_balance_wallet_rounded;
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'car_wash':
        return Icons.local_car_wash_rounded;
      case 'car_inspection':
        return Icons.search_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Request request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تأكيد الحذف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف هذا الطلب؟',
              style: TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRequestIcon(request.type),
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${request.typeLabel} #${request.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ لا يمكن التراجع عن هذا الإجراء',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_rounded, size: 18),
                SizedBox(width: 8),
                Text('حذف'),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteRequest(request);
    }
  }

  Future<void> _deleteRequest(Request request) async {
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await RequestsApiService.deleteRequest(request.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('تم حذف الطلب بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Reload data
        _loadRequests();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['error'] as String? ?? 'فشل حذف الطلب'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('حدث خطأ: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
