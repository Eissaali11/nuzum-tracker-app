import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/car_model.dart';
import '../../services/auth_service.dart';
import '../../services/employee_api_service.dart';
import '../../services/requests_api_service.dart';

/// ============================================
/// 🔍 صفحة فحص وتوثيق سيارة - Create Car Inspection Request Screen
/// ============================================

/// نموذج بطاقة ديناميكية
class DynamicCard {
  final String id;
  final TextEditingController textController;
  File? image;

  DynamicCard({required this.id, required this.textController, this.image});

  void dispose() {
    textController.dispose();
  }
}

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
  String _inspectionType = 'vehicle_receipt'; // القيمة الافتراضية (استلام سيارة)
  int? _requestId;
  
  // إدخال رقم اللوحة يدوياً
  bool _useManualEntry = false;
  final TextEditingController _plateNumbersController = TextEditingController(); // 4 أرقام
  final TextEditingController _plateLettersController = TextEditingController(); // 3 حروف عربية

  // الصور والفيديوهات العامة
  List<File> _images = [];
  List<File> _videos = [];
  final Map<int, double> _uploadProgress = {};

  // البطاقات الديناميكية
  List<DynamicCard> _dynamicCards = [];

  // حقول خاصة لتسليم لي ورشة
  File? _workshopDeliveryPdf;
  File? _workshopDeliverySpecialImage;
  List<File> _workshopDeliveryIdImages = [];

  // حقول خاصة لاستلام من ورشة
  List<File> _workshopReceiptReceiptImages = [];
  List<DynamicCard> _workshopReceiptCards = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploading = false;

  // قائمة حالات التوثيق
  static const Map<String, String> _inspectionTypes = {
    'vehicle_receipt': 'استلام سيارة',
    'vehicle_delivery': 'تسليم السيارة',
    'accident': 'توثيق حادث',
    'monthly_inspection': 'تفتيش شهري',
    'delivery_to_workshop': 'تسليم لي ورشة',
    'receipt_from_workshop': 'استلام من ورشة',
  };

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _plateNumbersController.dispose();
    _plateLettersController.dispose();
    for (var card in _dynamicCards) {
      card.dispose();
    }
    for (var card in _workshopReceiptCards) {
      card.dispose();
    }
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

  Future<File?> _pickImageFromSource(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (!mounted) return null;
    if (image != null) {
      return File(image.path);
    }
    return null;
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

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        _workshopDeliveryPdf = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickImageForCard(DynamicCard card) async {
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('الاستديو'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _pickImageFromSource(source);
      if (image != null) {
        if (mounted) {
          setState(() {
            card.image = image;
          });
        }
      }
    }
  }

  void _addDynamicCard() {
    setState(() {
      _dynamicCards.add(
        DynamicCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          textController: TextEditingController(),
        ),
      );
    });
  }

  void _removeDynamicCard(DynamicCard card) {
    setState(() {
      card.dispose();
      _dynamicCards.remove(card);
    });
  }

  void _addWorkshopReceiptCard() {
    setState(() {
      _workshopReceiptCards.add(
        DynamicCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          textController: TextEditingController(),
        ),
      );
    });
  }

  void _removeWorkshopReceiptCard(DynamicCard card) {
    if (!mounted) return;
    setState(() {
      card.dispose();
      _workshopReceiptCards.remove(card);
    });
  }

  Future<void> _pickWorkshopDeliverySpecialImage() async {
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('الاستديو'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _pickImageFromSource(source);
      if (image != null) {
        if (mounted) {
          setState(() {
            _workshopDeliverySpecialImage = image;
          });
        }
      }
    }
  }

  Future<void> _pickWorkshopDeliveryIdImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

    if (!mounted) return;
    if (images.isNotEmpty) {
      setState(() {
        _workshopDeliveryIdImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickWorkshopReceiptReceiptImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

    if (!mounted) return;
    if (images.isNotEmpty) {
      setState(() {
        _workshopReceiptReceiptImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  String get _manualPlateNumber {
    final numbers = _plateNumbersController.text.trim();
    final letters = _plateLettersController.text.trim();
    if (numbers.isEmpty || letters.isEmpty) return '';
    return '$numbers $letters';
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    // التحقق من اختيار السيارة أو إدخال رقم اللوحة
    if (!_useManualEntry && _selectedCar == null) {
      _showError('الرجاء اختيار سيارة أو إدخال رقم اللوحة');
      return;
    }
    
    if (_useManualEntry) {
      if (_plateNumbersController.text.trim().length != 4) {
        _showError('الرجاء إدخال 4 أرقام');
        return;
      }
      if (_plateLettersController.text.trim().length != 3) {
        _showError('الرجاء إدخال 3 حروف');
        return;
      }
    }

    // التحقق من الحقول الإجبارية حسب الحالة
    if (_inspectionType == 'delivery_to_workshop') {
      if (_workshopDeliverySpecialImage == null) {
        _showError('الرجاء إضافة الصورة الخاصة');
        return;
      }
      if (_workshopDeliveryIdImages.isEmpty) {
        _showError('الرجاء إضافة صور الهوية ورقم أبشر');
        return;
      }
    }

    if (_inspectionType == 'receipt_from_workshop') {
      if (_workshopReceiptReceiptImages.isEmpty) {
        _showError('الرجاء إضافة إيصال تسليم السيارة للورشة');
        return;
      }
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

      // جمع جميع الملفات
      final allFiles = <File>[];
      allFiles.addAll(_images);
      allFiles.addAll(_videos);
      
      // إضافة صور البطاقات الديناميكية
      for (final card in _dynamicCards) {
        if (card.image != null) {
          allFiles.add(card.image!);
        }
      }
      
      // إضافة الصور الخاصة لتسليم لي ورشة
      if (_inspectionType == 'delivery_to_workshop') {
        if (_workshopDeliverySpecialImage != null) {
          allFiles.add(_workshopDeliverySpecialImage!);
        }
        allFiles.addAll(_workshopDeliveryIdImages);
      }
      
      // إضافة إيصالات استلام من ورشة
      if (_inspectionType == 'receipt_from_workshop') {
        allFiles.addAll(_workshopReceiptReceiptImages);
        for (final card in _workshopReceiptCards) {
          if (card.image != null) {
            allFiles.add(card.image!);
          }
        }
      }

      if (allFiles.isEmpty) {
        _showError('الرجاء إضافة صورة واحدة على الأقل');
        setState(() => _isSubmitting = false);
        return;
      }

      // استخدام vehicleId من السيارة المختارة أو -1 للإدخال اليدوي
      final vehicleId = _useManualEntry 
          ? -1 // سيتم إرسال رقم اللوحة في notes أو حقل منفصل
          : int.parse(_selectedCar!.carId);
      
      // إضافة رقم اللوحة اليدوي في الملاحظات إذا كان موجوداً
      String? notes = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text;
      
      if (_useManualEntry) {
        final plateNumber = _manualPlateNumber;
        notes = notes != null 
            ? 'رقم اللوحة: $plateNumber\n$notes'
            : 'رقم اللوحة: $plateNumber';
      }

      final result = await RequestsApiService.createCarInspection(
        vehicleId: vehicleId,
        inspectionType: _inspectionType,
        inspectionDate: DateTime.now(),
        notes: notes,
        files: allFiles,
      );

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

      // Upload Dynamic Cards Images
      for (int i = 0; i < _dynamicCards.length; i++) {
        if (!mounted) break;
        final card = _dynamicCards[i];
        if (card.image != null) {
          final cardIndex = _images.length + _videos.length + i;
          final result = await RequestsApiService.uploadInspectionImage(
            _requestId!,
            card.image!,
            onProgress: (sent, total) {
              if (mounted) {
                setState(() {
                  _uploadProgress[cardIndex] = sent / total;
                });
              }
            },
          );

          if (result['success'] != true) {
            if (mounted) {
              _showError('فشل رفع صورة البطاقة ${i + 1}');
            }
          }
        }
      }

      // Upload Workshop Delivery Special Image
      if (_workshopDeliverySpecialImage != null) {
        final specialIndex = _images.length + _videos.length + _dynamicCards.length;
        final result = await RequestsApiService.uploadInspectionImage(
          _requestId!,
          _workshopDeliverySpecialImage!,
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[specialIndex] = sent / total;
              });
            }
          },
        );

        if (result['success'] != true) {
          if (mounted) {
            _showError('فشل رفع الصورة الخاصة');
          }
        }
      }

      // Upload Workshop Delivery ID Images
      for (int i = 0; i < _workshopDeliveryIdImages.length; i++) {
        if (!mounted) break;
        final idIndex = _images.length + _videos.length + _dynamicCards.length +
            (_workshopDeliverySpecialImage != null ? 1 : 0) + i;
        final result = await RequestsApiService.uploadInspectionImage(
          _requestId!,
          _workshopDeliveryIdImages[i],
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[idIndex] = sent / total;
              });
            }
          },
        );

        if (result['success'] != true) {
          if (mounted) {
            _showError('فشل رفع صورة الهوية ${i + 1}');
          }
        }
      }

      // Upload Workshop Receipt Receipt Images
      for (int i = 0; i < _workshopReceiptReceiptImages.length; i++) {
        if (!mounted) break;
        final receiptIndex = _images.length + _videos.length + _dynamicCards.length +
            (_workshopDeliverySpecialImage != null ? 1 : 0) +
            _workshopDeliveryIdImages.length + i;
        final result = await RequestsApiService.uploadInspectionImage(
          _requestId!,
          _workshopReceiptReceiptImages[i],
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[receiptIndex] = sent / total;
              });
            }
          },
        );

        if (result['success'] != true) {
          if (mounted) {
            _showError('فشل رفع إيصال الورشة ${i + 1}');
          }
        }
      }

      // Upload Workshop Receipt Cards Images
      for (int i = 0; i < _workshopReceiptCards.length; i++) {
        if (!mounted) break;
        final card = _workshopReceiptCards[i];
        if (card.image != null) {
          final cardIndex = _images.length + _videos.length + _dynamicCards.length +
              (_workshopDeliverySpecialImage != null ? 1 : 0) +
              _workshopDeliveryIdImages.length +
              _workshopReceiptReceiptImages.length + i;
          final result = await RequestsApiService.uploadInspectionImage(
            _requestId!,
            card.image!,
            onProgress: (sent, total) {
              if (mounted) {
                setState(() {
                  _uploadProgress[cardIndex] = sent / total;
                });
              }
            },
          );

          if (result['success'] != true) {
            if (mounted) {
              _showError('فشل رفع صورة بطاقة الاستلام ${i + 1}');
            }
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

  Widget _buildDynamicCard(DynamicCard card, int index, {bool isWorkshopReceipt = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'البطاقة ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                onPressed: () => isWorkshopReceipt
                    ? _removeWorkshopReceiptCard(card)
                    : _removeDynamicCard(card),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: card.textController,
            decoration: InputDecoration(
              labelText: 'النص',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.text_fields, color: Color(0xFF7C3AED)),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickImageForCard(card),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: card.image != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            card.image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  card.image = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لإضافة صورة',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeliveryToWorkshop = _inspectionType == 'delivery_to_workshop';
    final bool isReceiptFromWorkshop = _inspectionType == 'receipt_from_workshop';

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

                                  // Toggle بين اختيار السيارة والإدخال اليدوي
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _useManualEntry = false;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: !_useManualEntry
                                                    ? const Color(0xFF7C3AED)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'اختيار من القائمة',
                                                  style: TextStyle(
                                                    color: !_useManualEntry
                                                        ? Colors.white
                                                        : Colors.grey[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _useManualEntry = true;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: _useManualEntry
                                                    ? const Color(0xFF7C3AED)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'إدخال يدوي',
                                                  style: TextStyle(
                                                    color: _useManualEntry
                                                        ? Colors.white
                                                        : Colors.grey[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Car Selection أو Manual Entry
                                  if (!_useManualEntry) ...[
                                    DropdownButtonFormField<Car>(
                                      value: _selectedCar,
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
                                        fillColor: Colors.grey.withValues(alpha: 0.05),
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
                                        if (!_useManualEntry && value == null) {
                                          return 'الرجاء اختيار سيارة';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else ...[
                                    // تصميم اللوحة السعودية
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1E40AF), // أزرق داكن
                                            Color(0xFF3B82F6), // أزرق فاتح
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // شعار المملكة (نص بسيط)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.flag_rounded,
                                                color: Colors.white.withValues(alpha: 0.9),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'المملكة العربية السعودية',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // رقم اللوحة
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // الأرقام (4 أرقام)
                                              Container(
                                                width: 80,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: TextFormField(
                                                    controller: _plateNumbersController,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E40AF),
                                                      letterSpacing: 4,
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    maxLength: 4,
                                                    decoration: const InputDecoration(
                                                      border: InputBorder.none,
                                                      counterText: '',
                                                      hintText: '1234',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {});
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // الحروف (3 حروف عربية)
                                              Container(
                                                width: 80,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: TextFormField(
                                                    controller: _plateLettersController,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E40AF),
                                                      letterSpacing: 4,
                                                    ),
                                                    maxLength: 3,
                                                    decoration: const InputDecoration(
                                                      border: InputBorder.none,
                                                      counterText: '',
                                                      hintText: 'أ ب ج',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {});
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // عرض رقم اللوحة الكامل
                                          if (_plateNumbersController.text.isNotEmpty ||
                                              _plateLettersController.text.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _manualPlateNumber.isEmpty
                                                    ? 'رقم اللوحة'
                                                    : _manualPlateNumber,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // رسائل التوجيه
                                    if (_plateNumbersController.text.length != 4 ||
                                        _plateLettersController.text.length != 3)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orange[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _plateNumbersController.text.length != 4
                                                    ? 'الرجاء إدخال 4 أرقام'
                                                    : 'الرجاء إدخال 3 حروف عربية',
                                                style: TextStyle(
                                                  color: Colors.orange[900],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Inspection Type
                                  DropdownButtonFormField<String>(
                                    value: _inspectionType,
                                    decoration: InputDecoration(
                                      labelText: 'حالة التوثيق *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.assessment_rounded,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.withValues(alpha: 0.05),
                                    ),
                                    items: _inspectionTypes.entries.map((entry) {
                                      return DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      );
                                    }).toList(),
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
                                      fillColor: Colors.grey.withValues(alpha: 0.05),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // زر إضافة بطاقة ديناميكية
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _addDynamicCard,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('إضافة بطاقة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // عرض البطاقات الديناميكية
                                  if (_dynamicCards.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    ..._dynamicCards.asMap().entries.map((entry) {
                                      return _buildDynamicCard(entry.value, entry.key);
                                    }),
                                  ],
                                ],
                              ),
                            ),

                            // حقول خاصة لتسليم لي ورشة
                            if (isDeliveryToWorkshop) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.build_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'معلومات تسليم الورشة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // PDF اختياري
                                    ElevatedButton.icon(
                                      onPressed: _pickPdf,
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: Text(
                                        _workshopDeliveryPdf != null
                                            ? 'تم اختيار PDF'
                                            : 'رفع ملف PDF (اختياري)',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                        foregroundColor: Colors.orange[900],
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),

                                    if (_workshopDeliveryPdf != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _workshopDeliveryPdf!.path.split('/').last,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // صورة خاصة إجبارية
                                    GestureDetector(
                                      onTap: _pickWorkshopDeliverySpecialImage,
                                      child: Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _workshopDeliverySpecialImage == null
                                                ? Colors.red.withValues(alpha: 0.5)
                                                : Colors.green.withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: _workshopDeliverySpecialImage != null
                                            ? Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.file(
                                                      _workshopDeliverySpecialImage!,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close_rounded, size: 18),
                                                        color: Colors.white,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () {
                                                          setState(() {
                                                            _workshopDeliverySpecialImage = null;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_photo_alternate_rounded,
                                                      size: 48,
                                                      color: Colors.red[400],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'الصورة الخاصة * (إجباري)',
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

                                    const SizedBox(height: 16),

                                    // صور الهوية ورقم أبشر إجبارية
                                    ElevatedButton.icon(
                                      onPressed: _pickWorkshopDeliveryIdImages,
                                      icon: const Icon(Icons.badge),
                                      label: Text(
                                        _workshopDeliveryIdImages.isEmpty
                                            ? 'إضافة صور الهوية ورقم أبشر * (إجباري)'
                                            : 'تم إضافة ${_workshopDeliveryIdImages.length} صورة',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                                        foregroundColor: Colors.red[900],
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),

                                    if (_workshopDeliveryIdImages.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _workshopDeliveryIdImages.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final image = entry.value;
                                          return Stack(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    image,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _workshopDeliveryIdImages.removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // حقول خاصة لاستلام من ورشة
                            if (isReceiptFromWorkshop) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
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
                                          'معلومات استلام من الورشة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // إيصال تسليم السيارة للورشة (إجباري)
                                    GestureDetector(
                                      onTap: _pickWorkshopReceiptReceiptImages,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _workshopReceiptReceiptImages.isEmpty
                                                ? Colors.red.withValues(alpha: 0.5)
                                                : Colors.green.withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_rounded,
                                              color: _workshopReceiptReceiptImages.isEmpty
                                                  ? Colors.red[400]
                                                  : Colors.green[700],
                                              size: 32,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _workshopReceiptReceiptImages.isEmpty
                                                        ? 'إيصال تسليم السيارة للورشة * (إجباري)'
                                                        : 'تم إضافة ${_workshopReceiptReceiptImages.length} إيصال',
                                                    style: TextStyle(
                                                      color: _workshopReceiptReceiptImages.isEmpty
                                                          ? Colors.red[900]
                                                          : Colors.green[900],
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.add_photo_alternate_rounded,
                                              color: _workshopReceiptReceiptImages.isEmpty
                                                  ? Colors.red[400]
                                                  : Colors.green[700],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (_workshopReceiptReceiptImages.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _workshopReceiptReceiptImages.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final image = entry.value;
                                          return Stack(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    image,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _workshopReceiptReceiptImages.removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    // زر إضافة بطاقة ديناميكية لاستلام من ورشة
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withValues(alpha: 0.1),
                                            Colors.blue.withValues(alpha: 0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _addWorkshopReceiptCard,
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('إضافة بطاقة'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // عرض بطاقات استلام من ورشة
                                    if (_workshopReceiptCards.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      ..._workshopReceiptCards.asMap().entries.map((entry) {
                                        return _buildDynamicCard(entry.value, entry.key, isWorkshopReceipt: true);
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            ],

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
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _createRequest,
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_task_rounded, size: 22),
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
                            // Step 2: Upload Media (الكود الأصلي للرفع)
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              borderRadius: BorderRadius.circular(12),
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
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          label: const Text('إضافة'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF8B5CF6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  if (_images.isNotEmpty)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
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
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.close_rounded, size: 18),
                                                  color: Colors.white,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    if (!mounted) return;
                                                    setState(() {
                                                      _images.removeAt(index);
                                                      _uploadProgress.remove(index);
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
                                                  backgroundColor: Colors.grey[300],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF7C3AED),
                                                  ),
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
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              borderRadius: BorderRadius.circular(12),
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
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          label: const Text('إضافة'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF8B5CF6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
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
                                                  colors: [
                                                    Color(0xFF8B5CF6),
                                                    Color(0xFF7C3AED),
                                                  ],
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    video.path.split('/').last,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (_uploadProgress[videoIndex] != null) ...[
                                                    const SizedBox(height: 8),
                                                    LinearProgressIndicator(
                                                      value: _uploadProgress[videoIndex],
                                                      backgroundColor: Colors.grey[300],
                                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                                        Color(0xFF7C3AED),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded),
                                              color: Colors.red,
                                              onPressed: () {
                                                if (!mounted) return;
                                                setState(() {
                                                  _videos.removeAt(index);
                                                  _uploadProgress.remove(videoIndex);
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
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                            if (_images.isNotEmpty ||
                                _videos.isNotEmpty ||
                                _dynamicCards.any((card) => card.image != null) ||
                                _workshopDeliverySpecialImage != null ||
                                _workshopDeliveryIdImages.isNotEmpty ||
                                _workshopReceiptReceiptImages.isNotEmpty ||
                                _workshopReceiptCards.any((card) => card.image != null))
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
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _uploadMedia,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
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
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.upload_rounded, size: 22),
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
