import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/request_model.dart';
import '../../models/car_model.dart';
import '../../services/requests_api_service.dart';
import '../../services/auth_service.dart';
import '../../services/employee_api_service.dart';

/// ============================================
/// 🚗 صفحة طلب غسيل سيارة - Create Car Wash Request Screen
/// ============================================
class CreateCarWashRequestScreen extends StatefulWidget {
  const CreateCarWashRequestScreen({super.key});

  @override
  State<CreateCarWashRequestScreen> createState() =>
      _CreateCarWashRequestScreenState();
}

class _CreateCarWashRequestScreenState
    extends State<CreateCarWashRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<Car> _cars = [];
  Car? _selectedCar;
  String _serviceType = 'normal';
  DateTime? _requestedDate;
  bool _useManualEntry = false;
  final TextEditingController _manualCarInfoController = TextEditingController();

  final Map<String, File?> _photos = {
    'plate': null,
    'front': null,
    'back': null,
    'right_side': null,
    'left_side': null,
  };

  double _uploadProgress = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _manualCarInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final response = await EmployeeApiService.getCompleteProfile(
        jobNumber: employeeId,
        apiKey: '',
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _cars = [
            if (response.data!.currentCar != null) response.data!.currentCar!,
            ...response.data!.previousCars,
          ];
          if (_cars.isNotEmpty) _selectedCar = _cars.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto(String photoType) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (image != null) {
      setState(() {
        _photos[photoType] = File(image.path);
      });
    }
  }

  Future<void> _takePhoto(String photoType) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (image != null) {
      setState(() {
        _photos[photoType] = File(image.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    // التحقق من اختيار السيارة أو إدخالها يدوياً
    if (!_useManualEntry && _selectedCar == null) {
      _showError('الرجاء اختيار سيارة أو إدخال معلومات السيارة يدوياً');
      return;
    }
    
    if (_useManualEntry && _manualCarInfoController.text.trim().isEmpty) {
      _showError('الرجاء إدخال معلومات السيارة');
      return;
    }

    // Check all photos
    final missingPhotos = _photos.entries
        .where((e) => e.value == null)
        .map((e) => e.key)
        .toList();

    if (missingPhotos.isNotEmpty) {
      _showError('الرجاء رفع جميع الصور المطلوبة');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    try {
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        if (!mounted) return;
        _showError('الرجاء تسجيل الدخول');
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0;
        });
        return;
      }

      // استخدام vehicleId من السيارة المختارة أو 0 للإدخال اليدوي
      final vehicleId = _useManualEntry 
          ? 0  // سيتم التعامل معها في الـ backend
          : int.parse(_selectedCar!.carId);
      
      final request = CarWashRequest(
        employeeId: int.parse(employeeId),
        vehicleId: vehicleId,
        manualCarInfo: _useManualEntry 
            ? _manualCarInfoController.text.trim()
            : null,
        serviceType: _serviceType,
        requestedDate: _requestedDate,
        photos: _photos.map((key, value) => MapEntry(key, value?.path)),
      );

      final result = await RequestsApiService.createCarWash(
        request,
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
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
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ: $e');
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0;
      });
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
                'طلب غسيل سيارة',
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
                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                            Color(0xFF14B8A6),
                                            Color(0xFF0D9488)
                                          ],
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

                                // Toggle between selection and manual entry
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _useManualEntry = false;
                                              _manualCarInfoController.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: !_useManualEntry
                                                  ? const Color(0xFF0D9488)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.list_rounded,
                                                  size: 18,
                                                  color: !_useManualEntry
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'اختيار من القائمة',
                                                  style: TextStyle(
                                                    color: !_useManualEntry
                                                        ? Colors.white
                                                        : Colors.grey[600],
                                                    fontWeight: !_useManualEntry
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _useManualEntry = true;
                                              _selectedCar = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _useManualEntry
                                                  ? const Color(0xFF0D9488)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.edit_rounded,
                                                  size: 18,
                                                  color: _useManualEntry
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'إدخال يدوي',
                                                  style: TextStyle(
                                                    color: _useManualEntry
                                                        ? Colors.white
                                                        : Colors.grey[600],
                                                    fontWeight: _useManualEntry
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
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

                                const SizedBox(height: 16),

                                // Car Selection or Manual Entry
                                if (!_useManualEntry) ...[
                                  DropdownButtonFormField<Car>(
                                    initialValue: _selectedCar,
                                    decoration: InputDecoration(
                                      labelText: 'اختر السيارة *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.directions_car_rounded,
                                        color: Color(0xFF0D9488),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(alpha: 0.05),
                                    ),
                                    items: _cars.map((car) {
                                      return DropdownMenuItem(
                                        value: car,
                                        child: Text('${car.plateNumber} - ${car.model}'),
                                      );
                                    }).toList(),
                                    onChanged: (car) {
                                      if (!mounted) return;
                                      setState(() {
                                        _selectedCar = car;
                                      });
                                    },
                                    validator: (value) {
                                      if (!_useManualEntry && value == null) {
                                        return 'الرجاء اختيار سيارة';
                                      }
                                      return null;
                                    },
                                  ),
                                ] else ...[
                                  TextFormField(
                                    controller: _manualCarInfoController,
                                    decoration: InputDecoration(
                                      labelText: 'معلومات السيارة (رقم اللوحة، الموديل، إلخ) *',
                                      hintText: 'مثال: أ ب ج 1234 - تويوتا كامري 2020',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.edit_rounded,
                                        color: Color(0xFF0D9488),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(alpha: 0.05),
                                    ),
                                    maxLines: 2,
                                    validator: (value) {
                                      if (_useManualEntry && (value == null || value.trim().isEmpty)) {
                                        return 'الرجاء إدخال معلومات السيارة';
                                      }
                                      return null;
                                    },
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Service Type
                                DropdownButtonFormField<String>(
                                  initialValue: _serviceType,
                                  decoration: InputDecoration(
                                    labelText: 'نوع الخدمة *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.cleaning_services_rounded,
                                      color: Color(0xFF0D9488),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withValues(alpha: 0.05),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'normal',
                                      child: Text('غسيل عادي'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'polish',
                                      child: Text('تلميع'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'full_clean',
                                      child: Text('تنظيف شامل'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (!mounted) return;
                                    setState(() {
                                      _serviceType = value!;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Requested Date
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF0D9488),
                                    ),
                                    title: Text(
                                      _requestedDate == null
                                          ? 'التاريخ المطلوب (اختياري)'
                                          : '${_requestedDate!.year}-${_requestedDate!.month.toString().padLeft(2, '0')}-${_requestedDate!.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: _requestedDate == null
                                            ? Colors.grey[600]
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.arrow_back_ios_new,
                                        size: 16),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _requestedDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 30),
                                        ),
                                      );
                                      if (!mounted) return;
                                      if (date != null) {
                                        setState(() {
                                          _requestedDate = date;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Photos Section Card
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
                                            Color(0xFF14B8A6),
                                            Color(0xFF0D9488)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'الصور المطلوبة (5 صور) *',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildPhotoPicker('plate', 'صورة اللوحة', Icons.confirmation_number_rounded),
                                _buildPhotoPicker('front', 'من الأمام', Icons.car_rental_rounded),
                                _buildPhotoPicker('back', 'من الخلف', Icons.directions_car_filled_rounded),
                                _buildPhotoPicker('right_side', 'الجانب الأيمن', Icons.arrow_forward_ios_rounded),
                                _buildPhotoPicker('left_side', 'الجانب الأيسر', Icons.arrow_back_ios_rounded),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Upload Progress
                          if (_isSubmitting && _uploadProgress > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _uploadProgress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'جاري الرفع: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildPhotoPicker(String photoType, String label, IconData icon) {
    final photo = _photos[photoType];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (photo != null) ...[
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(photo, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(photoType),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('تغيير'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _takePhoto(photoType),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('التقاط'),
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
          ] else ...[
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'لم يتم اختيار صورة',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickPhoto(photoType),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('اختيار من المعرض'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF14B8A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _takePhoto(photoType),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('التقاط صورة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
