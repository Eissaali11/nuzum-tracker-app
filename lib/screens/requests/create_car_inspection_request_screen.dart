import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/car_model.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/employee_api_service.dart';
import '../../services/requests_api_service.dart';

/// ============================================
/// 🔍 صفحة فحص وتوثيق سيارة - Create Car Inspection Request Screen
/// ============================================
class CreateCarInspectionRequestScreen extends StatefulWidget {
  const CreateCarInspectionRequestScreen({super.key});

  @override
  State<CreateCarInspectionRequestScreen> createState() =>
      _CreateCarInspectionRequestScreenState();
}

class _CreateCarInspectionRequestScreenState
    extends State<CreateCarInspectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Car> _cars = [];
  Car? _selectedCar;
  String _inspectionType = 'accident';
  int? _requestId;

  List<File> _images = [];
  List<File> _videos = [];
  final Map<int, double> _uploadProgress = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

    if (!mounted) return;
    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images.map((img) => File(img.path)));
        if (_images.length > 20) {
          _images = _images.take(20).toList();
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (!mounted) return;
    if (video != null) {
      final file = File(video.path);
      final fileSize = await file.length();
      if (fileSize > 500 * 1024 * 1024) {
        _showError('حجم الفيديو كبير جداً (الحد الأقصى 500MB)');
        return;
      }

      setState(() {
        _videos.add(file);
        if (_videos.length > 5) {
          _videos = _videos.take(5).toList();
        }
      });
    }
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCar == null) {
      _showError('الرجاء اختيار سيارة');
      return;
    }

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

      final request = CarInspectionRequest(
        employeeId: int.parse(employeeId),
        vehicleId: int.parse(_selectedCar!.carId),
        inspectionType: _inspectionType,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      final result = await RequestsApiService.createCarInspection(request);

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _requestId = result['data']['request_id'] as int;
          _isSubmitting = false;
        });
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

  Future<void> _uploadMedia() async {
    if (_requestId == null) {
      _showError('الرجاء إنشاء الطلب أولاً');
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      // Upload Images
      for (int i = 0; i < _images.length; i++) {
        if (!mounted) break;
        final result = await RequestsApiService.uploadInspectionImage(
          _requestId!,
          _images[i],
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[i] = sent / total;
              });
            }
          },
        );

        if (result['success'] != true) {
          if (mounted) {
            _showError('فشل رفع الصورة ${i + 1}');
          }
        }
      }

      // Upload Videos
      for (int i = 0; i < _videos.length; i++) {
        if (!mounted) break;
        final videoIndex = _images.length + i;
        final result = await RequestsApiService.uploadInspectionVideo(
          _requestId!,
          _videos[i],
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[videoIndex] = sent / total;
              });
            }
          },
        );

        if (result['success'] != true) {
          if (mounted) {
            _showError('فشل رفع الفيديو ${i + 1}');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع جميع الملفات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('حدث خطأ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
                'فحص وتوثيق سيارة',
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
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
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
                          // Step 1: Create Request
                          if (_requestId == null) ...[
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
                                              Color(0xFF8B5CF6),
                                              Color(0xFF7C3AED),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.search_rounded,
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

                                  // Car Selection
                                  DropdownButtonFormField<Car>(
                                    initialValue: _selectedCar,
                                    decoration: InputDecoration(
                                      labelText: 'اختر السيارة *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.directions_car_rounded,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                    items: _cars.map((car) {
                                      return DropdownMenuItem(
                                        value: car,
                                        child: Text(
                                          '${car.plateNumber} - ${car.model}',
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
                                      if (value == null) {
                                        return 'الرجاء اختيار سيارة';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Inspection Type
                                  DropdownButtonFormField<String>(
                                    initialValue: _inspectionType,
                                    decoration: InputDecoration(
                                      labelText: 'نوع الفحص *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.assessment_rounded,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'accident',
                                        child: Text('حادث'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'periodic',
                                        child: Text('دوري'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'receipt',
                                        child: Text('استلام'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (!mounted) return;
                                      setState(() {
                                        _inspectionType = value!;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Description
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'الوصف',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.note_rounded,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Create Request Button
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _createRequest,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_task_rounded,
                                            size: 22,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'إنشاء الطلب',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ] else ...[
                            // Step 2: Upload Media
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.green.withValues(alpha: 0.1),
                                    Colors.green.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'تم إنشاء الطلب بنجاح',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'رقم الطلب: #$_requestId',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Images Section Card
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFF7C3AED),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.photo_library_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'الصور (${_images.length}/20)',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_images.length < 20)
                                        ElevatedButton.icon(
                                          onPressed: _pickImages,
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('إضافة'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF8B5CF6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  if (_images.isNotEmpty)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                          ),
                                      itemCount: _images.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF7C3AED,
                                                  ).withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.file(
                                                  _images[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                  ),
                                                  color: Colors.white,
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    if (!mounted) return;
                                                    setState(() {
                                                      _images.removeAt(index);
                                                      _uploadProgress.remove(
                                                        index,
                                                      );
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            if (_uploadProgress[index] != null)
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: LinearProgressIndicator(
                                                  value: _uploadProgress[index],
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF7C3AED)),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                  else
                                    Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_library_outlined,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'لا توجد صور',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Videos Section Card
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFF7C3AED),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.video_library_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'الفيديوهات (${_videos.length}/5)',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_videos.length < 5)
                                        ElevatedButton.icon(
                                          onPressed: _pickVideo,
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('إضافة'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF8B5CF6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_videos.isNotEmpty)
                                    ..._videos.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final video = entry.value;
                                      final videoIndex = _images.length + index;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF7C3AED,
                                            ).withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF8B5CF6),
                                                    Color(0xFF7C3AED),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.video_file_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    video.path.split('/').last,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (_uploadProgress[videoIndex] !=
                                                      null) ...[
                                                    const SizedBox(height: 8),
                                                    LinearProgressIndicator(
                                                      value:
                                                          _uploadProgress[videoIndex],
                                                      backgroundColor:
                                                          Colors.grey[300],
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                            Color
                                                          >(Color(0xFF7C3AED)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              color: Colors.red,
                                              onPressed: () {
                                                if (!mounted) return;
                                                setState(() {
                                                  _videos.removeAt(index);
                                                  _uploadProgress.remove(
                                                    videoIndex,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                  else
                                    Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.video_library_outlined,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'لا توجد فيديوهات',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Upload Button
                            if (_images.isNotEmpty || _videos.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF7C3AED),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _uploadMedia,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.upload_rounded,
                                              size: 22,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'رفع الملفات',
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
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
