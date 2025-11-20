import '../services/language_service.dart';

/// ============================================
/// 🔔 نموذج الإشعار - Notification Model
/// ============================================
class Notification {
  final int id;
  final String titleAr;
  final String messageAr;
  final String
  type; // 'approved', 'rejected', 'disbursed', 'liability_added', 'request_received'
  final bool isRead;
  final DateTime createdAt;
  final int? requestId;

  Notification({
    required this.id,
    required this.titleAr,
    required this.messageAr,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.requestId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int? ?? 0,
      titleAr: json['title_ar'] as String? ?? json['title'] as String? ?? '',
      messageAr: json['message_ar'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      requestId: json['request_id'] as int? ?? json['requestId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'message_ar': messageAr,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'request_id': requestId,
    };
  }

  String get typeIcon {
    switch (type) {
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      case 'disbursed':
        return '💰';
      case 'liability_added':
        return '⚠️';
      case 'request_received':
        return '📄';
      default:
        return '🔔';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final isArabic = LanguageService.instance.isArabic;

    if (difference.inDays > 0) {
      if (isArabic) {
        return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
      } else {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      }
    } else if (difference.inHours > 0) {
      if (isArabic) {
        return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
      } else {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      }
    } else if (difference.inMinutes > 0) {
      if (isArabic) {
        return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
      } else {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
    } else {
      return isArabic ? 'الآن' : 'Now';
    }
  }
}
