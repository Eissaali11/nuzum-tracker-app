import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/employee_model.dart';
import '../services/inspection_upload_service.dart';

/// ============================================
/// 📸 نموذج رفع صور فحص السلامة - Inspection Upload Dialog
/// ============================================
class InspectionUploadDialog extends StatefulWidget {
  final Car car;
  final Employee employee;

  const InspectionUploadDialog({
    super.key,
    required this.car,
    required this.employee,
  });

  @override
  State<InspectionUploadDialog> createState() => _InspectionUploadDialogState();
}

class _InspectionUploadDialogState extends State<InspectionUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  final List<InspectionImageCard> _imageCards = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // إضافة بطاقة أولية
    _addImageCard();
  }

  void _addImageCard() {
    setState(() {
      _imageCards.add(InspectionImageCard());
    });
  }

  void _removeImageCard(int index) {
    setState(() {
      _imageCards.removeAt(index);
    });
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'اختر مصدر الصورة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('الاستديو'),
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

  Future<void> _uploadInspection() async {
    // التحقق من وجود صور
    final imagesWithFiles = _imageCards
        .where((card) => card.imageFile != null)
        .toList();

    if (imagesWithFiles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final service = InspectionUploadService();
      final result = await service.uploadInspection(
        vehicleId: widget.car.carId,
        images: imagesWithFiles,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الرفع: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الرفع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 100 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
          maxWidth: isTablet ? 800 : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس النموذج
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
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
                          'رفع صور فحص السلامة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.car.plateNumber} - ${widget.employee.name}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // معلومات الموظف والسيارة
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // معلومات الموظف
                    _buildInfoSection(
                      'معلومات الموظف',
                      Icons.person_rounded,
                      [
                        _buildInfoRow('الاسم', widget.employee.name),
                        _buildInfoRow('رقم الموظف', widget.employee.jobNumber),
                        _buildInfoRow('القسم', widget.employee.department),
                        _buildInfoRow('المنصب', widget.employee.position),
                        if (widget.employee.phone != null)
                          _buildInfoRow('الهاتف', widget.employee.phone!),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // معلومات السيارة
                    _buildInfoSection(
                      'معلومات السيارة',
                      Icons.directions_car_rounded,
                      [
                        _buildInfoRow('رقم اللوحة', widget.car.plateNumber),
                        _buildInfoRow('الموديل', widget.car.model),
                        _buildInfoRow('اللون', widget.car.color),
                        if (widget.car.year != null)
                          _buildInfoRow('السنة', widget.car.year!),
                        if (widget.car.inspectionExpiryDate != null)
                          _buildInfoRow(
                            'انتهاء الفحص',
                            _formatDate(widget.car.inspectionExpiryDate!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // عنوان قسم الصور
                    const Text(
                      'صور الفحص',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // قائمة بطاقات الصور
                    ...List.generate(
                      _imageCards.length,
                      (index) => _buildImageCard(index),
                    ),
                    // مسافة إضافية في الأسفل للزر العائم
                    const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  // زر عائم لإضافة صورة في أعلى الصفحة
                  Positioned(
                    top: 20, // في أعلى الصفحة
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: _isUploading ? null : _addImageCard,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      mini: true, // تصغير حجم الزر
                      child: const Icon(Icons.add_rounded, size: 20),
                      elevation: 6,
                      heroTag: 'add_image_fab',
                      tooltip: 'إضافة صورة',
                    ),
                  ),
                ],
              ),
            ),
            // شريط التقدم وزر الرفع
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جاري الرفع... ${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadInspection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'رفع الصور',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final card = _imageCards[index];
    final hasImage = card.imageFile != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? Colors.blue : Colors.grey[300]!,
          width: hasImage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'صورة ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_imageCards.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => _removeImageCard(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // حقل الملاحظة
          TextField(
            controller: card.notesController,
            decoration: InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              hintText: 'أدخل ملاحظة حول هذه الصورة...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.note_rounded),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          // معاينة الصورة أو زر الإضافة
          if (hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    card.imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      onPressed: () => _showImageSourceDialog(index),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImageSourceDialog(index),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('إضافة صورة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }
}

/// ============================================
/// 📷 بطاقة صورة الفحص - Inspection Image Card
/// ============================================
class InspectionImageCard {
  File? imageFile;
  final TextEditingController notesController = TextEditingController();

  InspectionImageCard();

  void dispose() {
    notesController.dispose();
  }
}

