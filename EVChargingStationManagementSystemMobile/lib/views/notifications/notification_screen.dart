import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/notification_provider.dart';
import '../widgets/empty_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung Tâm Thông Báo'),
        actions: [
          if (notifProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notifProvider.markAllAsRead();
              },
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await notifProvider.fetchNotifications();
        },
        child: notifProvider.notifications.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'Không có thông báo mới',
                description: 'Các cập nhật về phiên sạc, lịch đặt và ưu đãi sẽ xuất hiện ở đây.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: notifProvider.notifications.length,
                itemBuilder: (context, index) {
                  final item = notifProvider.notifications[index];
                  return Card(
                    elevation: item.isRead ? 0.8 : 2.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: item.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    color: item.isRead ? Theme.of(context).cardColor : AppColors.primary.withOpacity(0.04),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        notifProvider.markAsRead(item.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIconColor(item.type).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(item.type),
                                color: _getIconColor(item.type),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Formatters.formatDateTime(item.createdAt),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
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
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'charging':
        return Icons.bolt;
      case 'booking':
        return Icons.calendar_month;
      case 'payment':
        return Icons.receipt_long;
      case 'promo':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'charging':
        return AppColors.primary;
      case 'booking':
        return AppColors.secondary;
      case 'payment':
        return AppColors.accent;
      case 'promo':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }
}
