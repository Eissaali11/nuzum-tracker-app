import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../services/requests_api_service.dart';

/// ============================================
/// 📄 صفحة تفاصيل الطلب - Request Details Screen
/// ============================================
class RequestDetailsScreen extends StatefulWidget {
  final int requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // محاولة استخدام الدالة العامة أولاً (الأكثر موثوقية)
      final generalResult = await RequestsApiService.getRequestDetails(widget.requestId);
      if (generalResult['success'] == true && generalResult['data'] != null) {
        final data = generalResult['data'] as Map<String, dynamic>;
        
        // التأكد من وجود الحقول الأساسية
        if (data['id'] == null) {
          data['id'] = widget.requestId;
        }
        if (data['type'] == null) {
          // محاولة تحديد النوع من البيانات المتاحة
          if (data['advance_data'] != null) {
            data['type'] = 'advance';
          } else if (data['invoice_data'] != null) {
            data['type'] = 'invoice';
          } else if (data['car_wash_data'] != null || data['vehicle_id'] != null) {
            data['type'] = 'car_wash';
          } else if (data['inspection_type'] != null || data['images'] != null) {
            data['type'] = 'car_inspection';
          } else {
            data['type'] = 'unknown';
          }
        }
        
        setState(() {
          _requestData = data;
          _isLoading = false;
        });
        return;
      }
      
      // إذا فشلت الدالة العامة، جرب الدوال المتخصصة
      Map<String, dynamic>? result;
      
      // محاولة جلب كطلب غسيل
      result = await RequestsApiService.getCarWashRequestDetails(widget.requestId);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        // إضافة type للتوافق مع الكود الحالي
        data['type'] = 'car_wash';
        if (data['id'] == null) {
          data['id'] = widget.requestId;
        }
        setState(() {
          _requestData = data;
          _isLoading = false;
        });
        return;
      }
      
      // محاولة جلب كطلب فحص (فقط إذا لم يكن الخطأ not_found أو method_not_allowed)
      final carWashError = result['error'] as String?;
      if (carWashError != 'not_found' && carWashError != 'method_not_allowed') {
        result = await RequestsApiService.getCarInspectionRequestDetails(widget.requestId);
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;
          // إضافة type للتوافق مع الكود الحالي
          data['type'] = 'car_inspection';
          if (data['id'] == null) {
            data['id'] = widget.requestId;
          }
          setState(() {
            _requestData = data;
            _isLoading = false;
          });
          return;
        }
      }
      
      // إذا فشلت جميع المحاولات
      setState(() {
        _error = (generalResult['error'] as String?) ?? 
                 (result != null ? (result['error'] as String?) : null) ?? 
                 'فشل جلب تفاصيل الطلب. يرجى المحاولة مرة أخرى.';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestDetails] Error loading details: $e');
      debugPrint('❌ [RequestDetails] Stack trace: $stackTrace');
      setState(() {
        _error = 'حدث خطأ أثناء جلب التفاصيل: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'تفاصيل الطلب',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
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
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? Container(
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
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadRequestDetails,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _requestData == null
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('لا توجد بيانات')),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: 24),
                                    _buildCommonInfo(),
                                    const SizedBox(height: 24),
                                    _buildTypeSpecificData(),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final type = _requestData!['type'] as String? ?? 'unknown';
    final status = _requestData!['status'] as String? ?? 'pending';
    final requestId = _requestData!['id'] as int? ?? widget.requestId;

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getRequestIcon(type),
              size: 48,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTypeLabel(type)} #$requestId',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'معلومات عامة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_requestData!['created_at'] != null)
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'تاريخ الإنشاء',
              _formatDate(_requestData!['created_at']),
            ),
          if (_requestData!['created_at'] != null) const SizedBox(height: 16),
          if (_requestData!['updated_at'] != null)
            _buildInfoRow(
              Icons.update_rounded,
              'آخر تحديث',
              _formatDate(_requestData!['updated_at']),
            ),
          if (_requestData!['admin_notes'] != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.note_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ملاحظات الإدارة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _requestData!['admin_notes'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSpecificData() {
    final type = _requestData!['type'] as String;

    switch (type) {
      case 'advance':
        return _buildAdvanceData();
      case 'invoice':
        return _buildInvoiceData();
      case 'car_wash':
        return _buildCarWashData();
      case 'car_inspection':
        return _buildCarInspectionData();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdvanceData() {
    final advanceData =
        _requestData!['advance_data'] as Map<String, dynamic>?;
    if (advanceData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تفاصيل السلفة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.attach_money_rounded,
            'المبلغ المطلوب',
            '${advanceData['requested_amount']} ريال',
          ),
          if (advanceData['installments'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_month_rounded,
              'عدد الأقساط',
              '${advanceData['installments']} أشهر',
            ),
          ],
          if (advanceData['monthly_installment'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calculate_rounded,
              'مبلغ القسط',
              '${advanceData['monthly_installment']} ريال',
            ),
          ],
          if (advanceData['disbursed_date'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.event_available_rounded,
              'تاريخ الصرف',
              _formatDate(advanceData['disbursed_date']),
            ),
          ],
          if (advanceData['disbursement_method'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.payment_rounded,
              'طريقة الصرف',
              advanceData['disbursement_method'] as String,
            ),
          ],
          if (advanceData['pdf_url'] != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(advanceData['pdf_url'] as String),
                icon: const Icon(Icons.download_rounded, size: 22),
                label: const Text(
                  'تحميل PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceData() {
    final invoiceData =
        _requestData!['invoice_data'] as Map<String, dynamic>?;
    if (invoiceData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تفاصيل الفاتورة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.business_rounded,
            'اسم المورد',
            invoiceData['vendor_name'] as String,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.attach_money_rounded,
            'المبلغ',
            '${invoiceData['amount']} ريال',
          ),
          if (invoiceData['description'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.note_rounded,
              'الوصف',
              invoiceData['description'] as String,
            ),
          ],
          if (invoiceData['invoice_image'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              'صورة الفاتورة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  invoiceData['invoice_image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error_outline, size: 48),
                    );
                  },
                ),
              ),
            ),
          ],
          if (invoiceData['drive_url'] != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(invoiceData['drive_url'] as String),
                icon: const Icon(Icons.open_in_new_rounded, size: 22),
                label: const Text(
                  'فتح في Drive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarWashData() {
    final carWashData =
        _requestData!['car_wash_data'] as Map<String, dynamic>?;
    if (carWashData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_car_wash_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تفاصيل غسيل السيارة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.directions_car_rounded,
            'السيارة',
            carWashData['vehicle'] as String? ?? 'غير محدد',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.cleaning_services_rounded,
            'نوع الخدمة',
            carWashData['service_type'] as String? ?? 'غير محدد',
          ),
          if (carWashData['photos'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              'الصور',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (carWashData['photos'] as List).length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        carWashData['photos'][index] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error_outline, size: 48),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (carWashData['folder_url'] != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(carWashData['folder_url'] as String),
                icon: const Icon(Icons.folder_open_rounded, size: 22),
                label: const Text(
                  'فتح مجلد Drive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarInspectionData() {
    final inspectionData =
        _requestData!['inspection_data'] as Map<String, dynamic>?;
    final mediaFiles = _requestData!['media_files'] as List<dynamic>?;
    if (inspectionData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تفاصيل الفحص',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.directions_car_rounded,
            'السيارة',
            inspectionData['vehicle'] as String? ?? 'غير محدد',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.assessment_rounded,
            'نوع الفحص',
            inspectionData['inspection_type'] as String? ?? 'غير محدد',
          ),
          if (inspectionData['description'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.note_rounded,
              'الوصف',
              inspectionData['description'] as String,
            ),
          ],
          if (mediaFiles != null && mediaFiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'الملفات المرفوعة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            // Images
            if (mediaFiles.any((f) => f['type'] == 'image')) ...[
              const Text(
                'الصور',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaFiles.where((f) => f['type'] == 'image').length,
                  itemBuilder: (context, index) {
                    final imageFiles = mediaFiles.where((f) => f['type'] == 'image').toList();
                    final image = imageFiles[index];
                    
                    // بناء URL الصورة من الحقول المتاحة
                    String? imageUrl;
                    
                    // الأولوية 1: drive_view_url (رابط Google Drive)
                    if (image['drive_view_url'] != null && 
                        (image['drive_view_url'] as String).isNotEmpty) {
                      imageUrl = image['drive_view_url'] as String;
                    }
                    // الأولوية 2: image_url (رابط مباشر)
                    else if (image['image_url'] != null && 
                             (image['image_url'] as String).isNotEmpty) {
                      imageUrl = image['image_url'] as String;
                    }
                    // الأولوية 3: local_path (بناء المسار الكامل)
                    else if (image['local_path'] != null && 
                             (image['local_path'] as String).isNotEmpty) {
                      final localPath = image['local_path'] as String;
                      // إزالة "static/" أو "uploads/" من البداية إذا كانت موجودة
                      final cleanPath = localPath.startsWith('static/') 
                          ? localPath.substring(7)
                          : localPath.startsWith('uploads/')
                              ? localPath
                              : 'uploads/$localPath';
                      // بناء URL كامل
                      imageUrl = '${ApiConfig.nuzumBaseUrl}/static/$cleanPath';
                    }
                    // الأولوية 4: url (الحقل القديم)
                    else if (image['url'] != null && 
                             (image['url'] as String).isNotEmpty) {
                      imageUrl = image['url'] as String;
                    }
                    
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(left: 12),
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'لا توجد صورة',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(left: 12),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('❌ [RequestDetails] Failed to load image: $imageUrl');
                            debugPrint('   Error: $error');
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 32, color: Colors.red),
                                  SizedBox(height: 4),
                                  Text(
                                    'فشل تحميل الصورة',
                                    style: TextStyle(fontSize: 10, color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Videos
            if (mediaFiles.any((f) => f['type'] == 'video')) ...[
              const Text(
                'الفيديوهات',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              ...mediaFiles.where((f) => f['type'] == 'video').map((video) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.video_file_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          video['name'] as String? ?? 'فيديو',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_rounded),
                        color: const Color(0xFF7C3AED),
                        onPressed: () => _openUrl(video['url'] as String),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
          if (inspectionData['folder_url'] != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openUrl(inspectionData['folder_url'] as String),
                icon: const Icon(Icons.folder_open_rounded, size: 22),
                label: const Text(
                  'فتح مجلد Drive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الرابط'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'advance':
        return 'طلب سلفة';
      case 'invoice':
        return 'رفع فاتورة';
      case 'car_wash':
        return 'طلب غسيل سيارة';
      case 'car_inspection':
        return 'فحص وتوثيق سيارة';
      default:
        return type;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      return date;
    } else if (date is DateTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
