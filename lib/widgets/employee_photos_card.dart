import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/employee_model.dart';
import 'beautiful_card.dart';

/// ============================================
/// 📸 بطاقة الصور - Employee Photos Card
/// ============================================
class EmployeePhotosCard extends StatelessWidget {
  final EmployeePhotos? photos;
  final bool isDriver;

  const EmployeePhotosCard({
    super.key,
    required this.photos,
    required this.isDriver,
  });

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر المشاركة - تصميم واضح
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        tooltip: 'مشاركة الصورة',
                        onPressed: () => _shareImage(context, imageUrl, title),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, size: 64, color: Colors.red),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// مشاركة الصورة
  Future<void> _shareImage(
    BuildContext context,
    String imageUrl,
    String title,
  ) async {
    try {
      // إغلاق dialog أولاً إذا كان مفتوحاً
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        // انتظار قليل لضمان إغلاق dialog
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // الحصول على context جديد بعد إغلاق dialog
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // إظهار مؤشر التحميل
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('جاري تحميل الصورة...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // تحميل الصورة من الرابط
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل تحميل الصورة');
      }

      // حفظ الصورة مؤقتاً
      final tempDir = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // مشاركة الصورة
      await Share.shareXFiles(
        [XFile(file.path)],
        text: title,
        subject: title,
      );

      // رسالة نجاح
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('✅ تم مشاركة $title بنجاح'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('❌ [Share] Error sharing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في مشاركة الصورة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPlaceholder(IconData icon, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Colors.grey[600]),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة الصور (الهوية والرخصة فقط - بدون الصورة الشخصية)
    final List<Map<String, dynamic>> photoList = [];
    
    if (photos?.id != null) {
      photoList.add({
        'url': photos!.id!,
        'title': 'صورة الهوية',
        'icon': Icons.badge,
      });
    }
    
    if (isDriver && photos?.license != null) {
      photoList.add({
        'url': photos!.license!,
        'title': 'رخصة القيادة',
        'icon': Icons.drive_eta,
      });
    }

    return BeautifulCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library, color: Color(0xFF1A237E), size: 24),
              SizedBox(width: 12),
              Text(
                'الصور',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          photoList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'لا توجد صور متاحة',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: photoList.length,
                    itemBuilder: (context, index) {
                      final photo = photoList[index];
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        margin: EdgeInsets.only(
                          right: index == 0 ? 0 : 16,
                          left: index == photoList.length - 1 ? 0 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GestureDetector(
                            onTap: () => _showImageDialog(
                              context,
                              photo['url'] as String,
                              photo['title'] as String,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photo['url'] as String,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholder(
                                      photo['icon'] as IconData,
                                      photo['title'] as String,
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.4),
                                      ],
                                    ),
                                  ),
                                ),
                                // زر المشاركة في الزاوية العلوية
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A237E),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _shareImage(
                                          context,
                                          photo['url'] as String,
                                          photo['title'] as String,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.share_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          photo['icon'] as IconData,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          photo['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
