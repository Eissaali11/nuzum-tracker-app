import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/employee_model.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/employee_api_service.dart';
import '../../services/requests_api_service.dart';

/// ============================================
/// 💰 صفحة إنشاء طلب سلفة - Create Advance Request Screen
/// ============================================
class CreateAdvanceRequestScreen extends StatefulWidget {
  const CreateAdvanceRequestScreen({super.key});

  @override
  State<CreateAdvanceRequestScreen> createState() =>
      _CreateAdvanceRequestScreenState();
}

class _CreateAdvanceRequestScreenState
    extends State<CreateAdvanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  Employee? _employee;
  int? _installments = 1;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  double _monthlyInstallment = 0;
  double? _netSalary;
  
  File? _advanceImage;
  double _uploadProgress = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    _amountController.addListener(_calculateInstallment);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (image != null) {
      setState(() {
        _advanceImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (image != null) {
      setState(() {
        _advanceImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    if (!mounted) return;
    setState(() {
      _advanceImage = null;
    });
  }

  Future<void> _loadEmployeeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'الرجاء تسجيل الدخول';
        });
        _showError('الرجاء تسجيل الدخول');
        return;
      }

      // التحقق من وجود JWT token
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'الرجاء تسجيل الدخول مرة أخرى';
        });
        _showError('الرجاء تسجيل الدخول مرة أخرى');
        return;
      }

      final response = await EmployeeApiService.getCompleteProfile(
        jobNumber: employeeId,
        apiKey: '', // Will use JWT from AuthService
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _employee = response.data!.employee;
          _netSalary = response.data!.statistics.salaries.lastSalary;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response.error ?? 'فشل تحميل بيانات الموظف';
        });
        _showError(response.error ?? 'فشل تحميل بيانات الموظف');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'حدث خطأ: $e';
      });
      _showError('حدث خطأ في تحميل البيانات: $e');
    }
  }

  void _calculateInstallment() {
    if (!mounted) return;
    final amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0 && _installments != null) {
      setState(() {
        _monthlyInstallment = amount / _installments!;
      });
    } else {
      setState(() {
        _monthlyInstallment = 0;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        if (!mounted) return;
        _showError('الرجاء تسجيل الدخول');
        setState(() => _isSubmitting = false);
        return;
      }

      final request = AdvancePaymentRequest(
        employeeId: int.parse(employeeId),
        requestedAmount: double.parse(_amountController.text),
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        installments: _installments,
        imagePath: _advanceImage?.path,
      );

      final result = await RequestsApiService.createAdvancePayment(
        request,
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = (sent / total) * 100;
          });
        },
      );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'تم إنشاء الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['error'] ?? 'فشل إنشاء الطلب');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ: $e');
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                'طلب سلفة',
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
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
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
                : _employee == null
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error ?? 'فشل تحميل بيانات الموظف',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadEmployeeData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Employee Info Card
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                              colors: [
                                                Color(0xFFFBBF24),
                                                Color(0xFFF59E0B)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'معلومات الموظف',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildInfoField('اسم الموظف', _employee!.name),
                                    _buildInfoField(
                                      'رقم الهوية',
                                      _employee!.nationalId ?? 'غير محدد',
                                    ),
                                    _buildInfoField(
                                      'الرقم الوظيفي',
                                      _employee!.jobNumber,
                                    ),
                                    _buildInfoField(
                                      'المسمى الوظيفي',
                                      _employee!.position,
                                    ),
                                    _buildInfoField('القسم', _employee!.section),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Request Details Card
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                              colors: [
                                                Color(0xFFFBBF24),
                                                Color(0xFFF59E0B)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'تفاصيل الطلب',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Amount
                                    TextFormField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'مبلغ السلفة المطلوب *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.currency_lira_rounded,
                                          color: Color(0xFFF59E0B),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withValues(alpha: 0.05),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال المبلغ';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null || amount <= 0) {
                                          return 'المبلغ يجب أن يكون أكبر من صفر';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Installments
                                    DropdownButtonFormField<int>(
                                      initialValue: _installments,
                                      decoration: InputDecoration(
                                        labelText: 'عدد الأقساط',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: Color(0xFFF59E0B),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withValues(alpha: 0.05),
                                      ),
                                      items: List.generate(12, (index) {
                                        final months = index + 1;
                                        return DropdownMenuItem(
                                          value: months,
                                          child: Text(
                                            '$months ${months == 1 ? 'شهر' : 'أشهر'}',
                                          ),
                                        );
                                      }),
                                    onChanged: (value) {
                                      if (!mounted) return;
                                      setState(() {
                                        _installments = value;
                                      });
                                      _calculateInstallment();
                                    },
                                    ),

                                    const SizedBox(height: 16),

                                    // Reason (Optional)
                                    TextFormField(
                                      controller: _reasonController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        labelText: 'سبب السلفة (اختياري)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.note_rounded,
                                          color: Color(0xFFF59E0B),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withValues(alpha: 0.05),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Image Upload Section
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'صورة مرفقة (اختياري)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (_advanceImage != null) ...[
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  _advanceImage!,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.red,
                                                  radius: 18,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    onPressed: _removeImage,
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _pickImage,
                                                  icon: const Icon(Icons.photo_library),
                                                  label: const Text('اختر من المعرض'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _takePhoto,
                                                  icon: const Icon(Icons.camera_alt),
                                                  label: const Text('التقط صورة'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (_isSubmitting && _uploadProgress > 0) ...[
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: _uploadProgress / 100,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFF59E0B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'جاري الرفع: ${_uploadProgress.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Calculation Results
                                    if (_monthlyInstallment > 0) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [
                                              const Color(0xFFFBBF24)
                                                  .withValues(alpha: 0.1),
                                              const Color(0xFFF59E0B)
                                                  .withValues(alpha: 0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calculate_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'حساب القسط',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildCalculationRow(
                                              'مبلغ القسط الشهري',
                                              '${_monthlyInstallment.toStringAsFixed(2)} ريال',
                                            ),
                                            if (_netSalary != null) ...[
                                              const SizedBox(height: 8),
                                              _buildCalculationRow(
                                                'الراتب الصافي بعد الخصم',
                                                '${(_netSalary! - _monthlyInstallment).toStringAsFixed(2)} ريال',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Submit Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<
                                                Color>(Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send_rounded, size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'إرسال الطلب',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}
