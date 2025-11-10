import 'package:flutter/material.dart';

import '../../models/notification_model.dart' as models;
import '../../services/notifications_api_service.dart';
import '../requests/request_details_screen.dart';

/// ============================================
/// 🔔 صفحة الإشعارات - Notifications Screen
/// ============================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<models.Notification> _allNotifications = [];
  List<models.Notification> _filteredNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // 'all' or 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await NotificationsApiService.getNotifications();

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _allNotifications = result['data'] as List<models.Notification>;
          _unreadCount = result['unread_count'] as int? ?? 0;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (!mounted) return;
    setState(() {
      if (_filter == 'unread') {
        _filteredNotifications =
            _allNotifications.where((n) => !n.isRead).toList();
      } else {
        _filteredNotifications = _allNotifications;
      }
    });
  }

  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;

    final result =
        await NotificationsApiService.markAsRead(notification.id);

    if (result['success'] == true && mounted) {
      setState(() {
        final index = _allNotifications
            .indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _allNotifications[index] = models.Notification(
            id: notification.id,
            titleAr: notification.titleAr,
            messageAr: notification.messageAr,
            type: notification.type,
            isRead: true,
            createdAt: notification.createdAt,
            requestId: notification.requestId,
          );
        }
        _unreadCount = _allNotifications.where((n) => !n.isRead).length;
        _applyFilter();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await NotificationsApiService.markAllAsRead();

    if (result['success'] == true && mounted) {
      setState(() {
        _allNotifications = _allNotifications.map((n) {
          return models.Notification(
            id: n.id,
            titleAr: n.titleAr,
            messageAr: n.messageAr,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            requestId: n.requestId,
          );
        }).toList();
        _unreadCount = 0;
        _applyFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
            actions: [
              if (_unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('تحديد الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadNotifications,
                tooltip: 'تحديث',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab('all', 'الكل', Icons.list_rounded),
                    ),
                    Expanded(
                      child: _buildFilterTab(
                        'unread',
                        'غير المقروءة',
                        Icons.notifications_active_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Statistics Card
                if (!_isLoading && _error == null && _allNotifications.isNotEmpty)
                  _buildStatisticsCard(),
                
                // List
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildErrorWidget()
                else if (_filteredNotifications.isEmpty)
                  _buildEmptyState()
                else
                  _buildNotificationsList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'إجمالي الإشعارات',
              '${_allNotifications.length}',
              Icons.notifications_rounded,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildStatItem(
              'غير المقروءة',
              '$_unreadCount',
              Icons.notifications_active_rounded,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildStatItem(
              'المقروءة',
              '${_allNotifications.length - _unreadCount}',
              Icons.done_all_rounded,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilterTab(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _filter = value;
        });
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            if (value == 'unread' && _unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[200]!],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'unread'
                ? 'لا توجد إشعارات غير مقروءة'
                : 'لم يتم العثور على أي إشعارات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildNotificationCard(_filteredNotifications[index]),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification) {
    final typeGradient = _getTypeGradient(notification.type);
    final typeColor = _getNotificationColor(notification.type);
    final isUnread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await _markAsRead(notification);
          if (!mounted) return;
          if (notification.requestId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RequestDetailsScreen(requestId: notification.requestId!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? typeColor.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isUnread ? 15 : 10,
                offset: Offset(0, isUnread ? 4 : 2),
              ),
            ],
            border: Border.all(
              color: isUnread
                  ? typeColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: isUnread ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isUnread ? typeGradient : null,
                  color: isUnread ? null : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? Colors.white.withValues(alpha: 0.25)
                            : typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: isUnread ? Colors.white : typeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.titleAr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isUnread
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.messageAr,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    if (notification.requestId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: const Color(0xFF8B5CF6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'طلب #${notification.requestId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getTypeGradient(String type) {
    switch (type) {
      case 'approved':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case 'rejected':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        );
      case 'disbursed':
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        );
      case 'liability_added':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        );
      case 'request_received':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        );
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'disbursed':
        return Icons.account_balance_wallet_rounded;
      case 'liability_added':
        return Icons.warning_rounded;
      case 'request_received':
        return Icons.description_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'disbursed':
        return Colors.amber;
      case 'liability_added':
        return Colors.orange;
      case 'request_received':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
