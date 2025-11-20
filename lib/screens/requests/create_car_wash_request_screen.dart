import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/car_model.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/employee_api_service.dart';
import '../../services/requests_api_service.dart';

/// ============================================
/// 🚗 صفحة طلب غسيل سيارة - Create Car Wash Request Screen
/// تصميم مستقبلي منسق وجميل
/// ============================================
class CreateCarWashRequestScreen extends StatefulWidget {
  const CreateCarWashRequestScreen({super.key});

  @override
  State<CreateCarWashRequestScreen> createState() =>
      _CreateCarWashRequestScreenState();
}

class _CreateCarWashRequestScreenState extends State<CreateCarWashRequestScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<Car> _cars = [];
  Car? _selectedCar;
  String _serviceType = 'normal';
  DateTime? _requestedDate;
  bool _useManualEntry = false;
  final TextEditingController _manualCarInfoController =
      TextEditingController();

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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadCars();

    // إعداد Animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _manualCarInfoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
          // دمج جميع السيارات: الحالية + السابقة
          // نضمن عدم تكرار السيارة الحالية إذا كانت موجودة في previousCars
          _cars = [];
          final addedCarIds = <String>{};
          
          // إضافة السيارة الحالية أولاً إذا كانت موجودة
          if (response.data!.currentCar != null) {
            _cars.add(response.data!.currentCar!);
            addedCarIds.add(response.data!.currentCar!.carId);
          }
          
          // إضافة جميع السيارات السابقة (بما في ذلك السيارات النشطة)
          for (final previousCar in response.data!.previousCars) {
            // التحقق من عدم التكرار بناءً على car_id
            if (!addedCarIds.contains(previousCar.carId)) {
              _cars.add(previousCar);
              addedCarIds.add(previousCar.carId);
            }
          }
          
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

    if (!_useManualEntry && _selectedCar == null) {
      _showError('الرجاء اختيار سيارة أو إدخال معلومات السيارة يدوياً');
      return;
    }

    if (_useManualEntry && _manualCarInfoController.text.trim().isEmpty) {
      _showError('الرجاء إدخال معلومات السيارة');
      return;
    }

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

      final vehicleId = _useManualEntry ? 0 : int.parse(_selectedCar!.carId);

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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'تم إنشاء الطلب بنجاح'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar مع Glassmorphism Effect
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'طلب غسيل سيارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF14B8A6),
                      const Color(0xFF0D9488),
                      const Color(0xFF0F766E),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern Overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(painter: _PatternPainter()),
                      ),
                    ),
                    // Shine Effect
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF14B8A6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل السيارات...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Request Details Card - Glassmorphism
                              _buildGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader(
                                      icon: Icons.local_car_wash_rounded,
                                      title: 'تفاصيل الطلب',
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF14B8A6),
                                          Color(0xFF0D9488),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Toggle Switch - Modern Design
                                    _buildToggleSwitch(),
                                    const SizedBox(height: 20),

                                    // Car Selection or Manual Entry
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: !_useManualEntry
                                          ? _buildCarSelector()
                                          : _buildManualEntry(),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.1, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Service Type - Modern Dropdown
                                    _buildServiceTypeSelector(),
                                    const SizedBox(height: 20),

                                    // Requested Date - Modern Date Picker
                                    _buildDatePicker(),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Photos Section - Grid Layout
                              _buildGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader(
                                      icon: Icons.photo_camera_rounded,
                                      title: 'الصور المطلوبة',
                                      subtitle: '5 صور مطلوبة',
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF14B8A6),
                                          Color(0xFF0D9488),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Photo Grid
                                    _buildPhotoGrid(),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Upload Progress - Animated
                              if (_isSubmitting && _uploadProgress > 0)
                                _buildUploadProgress(),

                              const SizedBox(height: 20),

                              // Submit Button - Modern with Animation
                              _buildSubmitButton(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    required Gradient gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              icon: Icons.list_rounded,
              label: 'من القائمة',
              isSelected: !_useManualEntry,
              onTap: () {
                setState(() {
                  _useManualEntry = false;
                  _manualCarInfoController.clear();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleOption(
              icon: Icons.edit_rounded,
              label: 'إدخال يدوي',
              isSelected: _useManualEntry,
              onTap: () {
                setState(() {
                  _useManualEntry = true;
                  _selectedCar = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarSelector() {
    return DropdownButtonFormField<Car>(
      key: const ValueKey('car_selector'),
      initialValue: _selectedCar,
      decoration: InputDecoration(
        labelText: 'اختر السيارة *',
        hintText: 'اختر من القائمة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Color(0xFF0D9488),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      items: _cars.map((car) {
        return DropdownMenuItem(
          value: car,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 16,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      car.plateNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      car.model,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    );
  }

  Widget _buildManualEntry() {
    return TextFormField(
      key: const ValueKey('manual_entry'),
      controller: _manualCarInfoController,
      decoration: InputDecoration(
        labelText: 'معلومات السيارة *',
        hintText: 'مثال: أ ب ج 1234 - تويوتا كامري 2020',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.edit_rounded,
            color: Color(0xFF0D9488),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      maxLines: 2,
      validator: (value) {
        if (_useManualEntry && (value == null || value.trim().isEmpty)) {
          return 'الرجاء إدخال معلومات السيارة';
        }
        return null;
      },
    );
  }

  Widget _buildServiceTypeSelector() {
    final serviceTypes = [
      {
        'value': 'normal',
        'label': 'غسيل عادي',
        'icon': Icons.water_drop_rounded,
      },
      {'value': 'polish', 'label': 'تلميع', 'icon': Icons.auto_awesome_rounded},
      {
        'value': 'full_clean',
        'label': 'تنظيف شامل',
        'icon': Icons.cleaning_services_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الخدمة *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: serviceTypes.map((type) {
            final isSelected = _serviceType == type['value'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == serviceTypes.first ? 0 : 8,
                  left: type == serviceTypes.last ? 0 : 8,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _serviceType = type['value'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF14B8A6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _requestedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF14B8A6),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF1F2937),
                ),
              ),
              child: child!,
            );
          },
        );
        if (!mounted) return;
        if (date != null) {
          setState(() {
            _requestedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF0D9488),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _requestedDate == null
                        ? 'التاريخ المطلوب (اختياري)'
                        : '${_requestedDate!.year}-${_requestedDate!.month.toString().padLeft(2, '0')}-${_requestedDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _requestedDate == null
                          ? Colors.grey[600]
                          : const Color(0xFF1F2937),
                      fontSize: 15,
                      fontWeight: _requestedDate == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  if (_requestedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'اضغط لتغيير التاريخ',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photoConfigs = [
      {
        'key': 'plate',
        'label': 'اللوحة',
        'icon': Icons.confirmation_number_rounded,
      },
      {'key': 'front', 'label': 'الأمام', 'icon': Icons.car_rental_rounded},
      {
        'key': 'back',
        'label': 'الخلف',
        'icon': Icons.directions_car_filled_rounded,
      },
      {
        'key': 'right_side',
        'label': 'الأيمن',
        'icon': Icons.arrow_forward_ios_rounded,
      },
      {
        'key': 'left_side',
        'label': 'الأيسر',
        'icon': Icons.arrow_back_ios_rounded,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92, // تحسين النسبة لتقليل الحيز
      ),
      itemCount: photoConfigs.length,
      itemBuilder: (context, index) {
        final config = photoConfigs[index];
        return _buildPhotoCard(
          photoType: config['key'] as String,
          label: config['label'] as String,
          icon: config['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildPhotoCard({
    required String photoType,
    required String label,
    required IconData icon,
  }) {
    final photo = _photos[photoType];
    final hasPhoto = photo != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPhoto
              ? const Color(0xFF1A237E).withValues(
                  alpha: 0.3,
                ) // استخدام ألوان المشروع
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasPhoto
                ? const Color(0xFF1A237E).withValues(
                    alpha: 0.1,
                  ) // استخدام ألوان المشروع
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Expanded(
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(photo, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4CAF50,
                              ), // لون النجاح من المشروع
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14, // تقليل حجم الأيقونة
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.withValues(alpha: 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 32, // تقليل حجم الأيقونة
                            color: const Color(
                              0xFF1A237E,
                            ).withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 6), // تقليل المسافة
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2), // تقليل المسافة
                          Text(
                            'مطلوب',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ), // تقليل padding
              color: Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min, // تقليل الحيز
                children: [
                  Expanded(
                    child: _buildPhotoButton(
                      icon: Icons.photo_library_rounded,
                      label: 'معرض',
                      onTap: () => _pickPhoto(photoType),
                      isPrimary: !hasPhoto,
                    ),
                  ),
                  const SizedBox(width: 6), // تقليل المسافة
                  Expanded(
                    child: _buildPhotoButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'كاميرا',
                      onTap: () => _takePhoto(photoType),
                      isPrimary: !hasPhoto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ), // تقليل padding
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF0D47A1),
                  ], // استخدام ألوان المشروع
                )
              : null,
          color: isPrimary ? null : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // تقليل الحيز
          children: [
            Icon(
              icon,
              size: 14, // تقليل حجم الأيقونة
              color: isPrimary
                  ? Colors.white
                  : const Color(0xFF1A237E).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4), // تقليل المسافة
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : const Color(0xFF1A237E).withValues(alpha: 0.8),
                  fontSize: 11, // تقليل حجم الخط
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: 0.1),
            const Color(0xFF0D9488).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: Color(0xFF0D9488)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'جاري رفع الطلب...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF14B8A6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitRequest,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'جاري الإرسال...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 24, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'إرسال الطلب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Pattern Painter for Background
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
