import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/car_model.dart';
import '../../models/employee_model.dart';
import '../../services/employee_api_service.dart';
import '../../services/external_safety_service.dart';
import '../../utils/safe_preferences.dart';

/// ============================================
/// 🛡️ صفحة فحص السلامة الخارجية - External Safety Check Screen
/// ============================================
class ExternalSafetyCheckScreen extends StatefulWidget {
  final Car car;
  final Employee employee;

  const ExternalSafetyCheckScreen({
    super.key,
    required this.car,
    required this.employee,
  });

  @override
  State<ExternalSafetyCheckScreen> createState() =>
      _ExternalSafetyCheckScreenState();
}

/// ============================================
/// 📷 بطاقة صورة فحص السلامة - Safety Check Image Card
/// ============================================
class SafetyCheckImageCard {
  File? imageFile;
  final TextEditingController notesController = TextEditingController();

  SafetyCheckImageCard();

  void dispose() {
    notesController.dispose();
  }
}

class _ExternalSafetyCheckScreenState extends State<ExternalSafetyCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _driverNationalIdController = TextEditingController();
  final _driverDepartmentController = TextEditingController();
  final _driverCityController = TextEditingController();
  final _currentDelegateController = TextEditingController();
  final _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<SafetyCheckImageCard> _imageCards = [];
  bool _isCreating = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int? _checkId;
  bool _isLoadingEmployee = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    // إضافة بطاقة أولية
    _addImageCard();
  }

  /// جلب بيانات الموظف تلقائياً وملء الحقول
  Future<void> _loadEmployeeData() async {
    setState(() {
      _isLoadingEmployee = true;
    });

    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber != null && apiKey != null && jobNumber.isNotEmpty) {
        final response = await EmployeeApiService.getCompleteProfile(
          jobNumber: jobNumber,
          apiKey: apiKey,
        );

        if (mounted && response.success && response.data != null) {
          final employee = response.data!.employee;

          // ملء الحقول تلقائياً من بيانات الموظف
          setState(() {
            _driverNameController.text = employee.name;
            _driverNationalIdController.text = employee.nationalId ?? '';
            _driverDepartmentController.text = employee.department;
            // محاولة استخراج المدينة من العنوان أو استخدام القسم كبديل
            if (employee.address != null && employee.address!.isNotEmpty) {
              // يمكن تحسين هذا لاستخراج المدينة من العنوان
              _driverCityController.text = employee.address!;
            } else if (employee.section.isNotEmpty) {
              _driverCityController.text = employee.section;
            }
            // المنتدب الحالي يمكن أن يكون اسم الموظف نفسه أو يمكن تركه فارغاً
            _currentDelegateController.text = employee.name;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ExternalSafety] Error loading employee data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء جلب بيانات الموظف: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEmployee = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverNationalIdController.dispose();
    _driverDepartmentController.dispose();
    _driverCityController.dispose();
    _currentDelegateController.dispose();
    _notesController.dispose();
    for (var card in _imageCards) {
      card.dispose();
    }
    super.dispose();
  }

  void _addImageCard() {
    setState(() {
      _imageCards.add(SafetyCheckImageCard());
    });
  }

  void _removeImageCard(int index) {
    if (_imageCards.length > 1) {
      setState(() {
        _imageCards[index].dispose();
        _imageCards.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون هناك بطاقة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (!mounted) return;
      if (image != null) {
        setState(() {
          _imageCards[index].imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageSourceDialog(int index) async {
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'اختر مصدر الصورة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              title: const Text(
                'الكاميرا',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              title: const Text(
                'الاستديو',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(index, source);
    }
  }

  Future<void> _createSafetyCheck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من وجود صور
    final imagesWithFiles = _imageCards
        .where((card) => card.imageFile != null)
        .toList();

    if (imagesWithFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // تحويل vehicle_id من String إلى int
      final vehicleId = int.tryParse(widget.car.carId);
      if (vehicleId == null || vehicleId <= 0) {
        throw Exception('رقم السيارة غير صحيح');
      }

      final result = await ExternalSafetyService.createSafetyCheck(
        vehicleId: vehicleId,
        driverName: _driverNameController.text.trim(),
        driverNationalId: _driverNationalIdController.text.trim(),
        driverDepartment: _driverDepartmentController.text.trim(),
        driverCity: _driverCityController.text.trim(),
        currentDelegate: _currentDelegateController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        _checkId = result.data!['check_id'] as int;

        // رفع الصور
        await _uploadImages();
      } else {
        setState(() {
          _isCreating = false;
        });

        // عرض رسالة خطأ واضحة
        String errorMessage = result.message ?? 'فشل إنشاء فحص السلامة';
        if (errorMessage.contains('404') ||
            errorMessage.contains('غير موجود')) {
          errorMessage =
              'الـ API غير متاح حالياً على السرفر. يرجى المحاولة لاحقاً أو التواصل مع الدعم الفني.';
        }

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'فشل إنشاء الفحص',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadImages() async {
    if (_checkId == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final imagesWithFiles = _imageCards
        .where((card) => card.imageFile != null)
        .toList();

    int uploadedCount = 0;
    for (int i = 0; i < imagesWithFiles.length; i++) {
      final card = imagesWithFiles[i];
      final image = card.imageFile!;
      final description = card.notesController.text.trim().isNotEmpty
          ? card.notesController.text.trim()
          : null;

      final result = await ExternalSafetyService.uploadSafetyCheckImage(
        checkId: _checkId!,
        imageFile: image,
        description: description,
        onProgress: (sent, total) {
          if (mounted) {
            final imageProgress = sent / total;
            final totalProgress =
                (uploadedCount + imageProgress) / imagesWithFiles.length;
            setState(() {
              _uploadProgress = totalProgress;
            });
          }
        },
      );

      if (result.success) {
        uploadedCount++;
      } else {
        debugPrint(
          '❌ [ExternalSafety] Failed to upload image ${i + 1}: ${result.message}',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _isCreating = false;
    });

    if (uploadedCount == imagesWithFiles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء فحص السلامة ورفع الصور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء الفحص لكن فشل رفع بعض الصور ($uploadedCount/${imagesWithFiles.length})',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'فحص السلامة الخارجية',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // معلومات السيارة
                  _buildModernInfoCard(
                    'معلومات السيارة',
                    Icons.directions_car_rounded,
                    const Color(0xFF8B5CF6),
                    [
                      _buildInfoRow(
                        Icons.confirmation_number_rounded,
                        'رقم اللوحة',
                        widget.car.plateNumber,
                      ),
                      _buildInfoRow(
                        Icons.directions_car_rounded,
                        'الموديل',
                        widget.car.model,
                      ),
                      _buildInfoRow(
                        Icons.color_lens_rounded,
                        'اللون',
                        widget.car.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // معلومات السائق
                  _buildModernInfoCard(
                    'معلومات السائق',
                    Icons.person_rounded,
                    const Color(0xFF10B981),
                    [
                      if (_isLoadingEmployee)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _buildTextField(
                          controller: _driverNameController,
                          label: 'اسم السائق *',
                          icon: Icons.person_rounded,
                          hasAutoFill: widget.employee.name.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _driverNationalIdController,
                          label: 'رقم الهوية الوطنية *',
                          icon: Icons.badge_rounded,
                          keyboardType: TextInputType.number,
                          hasAutoFill:
                              widget.employee.nationalId != null &&
                              widget.employee.nationalId!.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _driverDepartmentController,
                          label: 'القسم *',
                          icon: Icons.business_rounded,
                          hasAutoFill: widget.employee.department.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _driverCityController,
                          label: 'المدينة *',
                          icon: Icons.location_city_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _currentDelegateController,
                          label: 'المنتدب الحالي *',
                          icon: Icons.person_outline_rounded,
                          hasAutoFill: widget.employee.name.isNotEmpty,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // الملاحظات العامة
                  _buildModernInfoCard(
                    'ملاحظات عامة',
                    Icons.note_rounded,
                    const Color(0xFFF59E0B),
                    [
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          hintText: 'أدخل ملاحظات عامة حول الفحص...',
                          prefixIcon: const Icon(Icons.note_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // قسم صور الفحص
                  _buildSectionHeader(
                    'صور الفحص',
                    Icons.camera_alt_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),

                  // بطاقات الصور
                  ...List.generate(
                    _imageCards.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildImageCard(index),
                    ),
                  ),

                  // زر إضافة بطاقة جديدة
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _addImageCard,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'إضافة بطاقة صورة جديدة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // شريط التقدم
                  if (_isUploading) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF8B5CF6),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'جاري الرفع... ${(_uploadProgress * 100).toInt()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // زر الإرسال
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: (_isCreating || _isUploading)
                          ? null
                          : _createSafetyCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: (_isCreating || _isUploading)
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'إنشاء فحص السلامة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات حديثة
  Widget _buildModernInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  /// بناء صف معلومات
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حقل نصي
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool hasAutoFill = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: hasAutoFill
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال $label';
        }
        return null;
      },
    );
  }

  /// بناء رأس قسم
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// بناء بطاقة صورة
  Widget _buildImageCard(int index) {
    final card = _imageCards[index];
    final hasImage = card.imageFile != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasImage
              ? [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  const Color(0xFF7C3AED).withValues(alpha: 0.05),
                ]
              : [Colors.grey[50]!, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasImage
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
              : Colors.grey[300]!,
          width: hasImage ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasImage
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: hasImage ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasImage
                        ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
                        : [Colors.grey[400]!, Colors.grey[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (hasImage ? const Color(0xFF8B5CF6) : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  hasImage
                      ? Icons.image_rounded
                      : Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'بطاقة ${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasImage
                        ? const Color(0xFF1F2937)
                        : Colors.grey[600],
                  ),
                ),
              ),
              if (_imageCards.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                    onPressed: () => _removeImageCard(index),
                    tooltip: 'حذف البطاقة',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // حقل الملاحظة
          TextField(
            controller: card.notesController,
            decoration: InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              hintText: 'أدخل ملاحظة حول هذه الصورة...',
              prefixIcon: const Icon(Icons.note_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // معاينة الصورة أو زر الإضافة
          if (hasImage)
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      card.imageFile!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => _showImageSourceDialog(index),
                      tooltip: 'تغيير الصورة',
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showImageSourceDialog(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'إضافة صورة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'من الكاميرا أو الاستديو',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
