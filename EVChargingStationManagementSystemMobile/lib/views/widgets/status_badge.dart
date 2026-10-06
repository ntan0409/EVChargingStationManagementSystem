import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = status;

    final lower = status.toLowerCase();
    if (lower == 'available' || lower == 'active' || lower == 'paid' || lower == 'completed' || lower == 'success' || lower == 'sẵn sàng') {
      bg = AppColors.statusAvailable.withOpacity(0.15);
      fg = AppColors.statusAvailable;
      if (lower == 'available') text = 'Sẵn sàng';
      if (lower == 'active') text = 'Hoạt động';
      if (lower == 'paid' || lower == 'success') text = 'Đã thanh toán';
      if (lower == 'completed') text = 'Hoàn tất';
    } else if (lower == 'charging' || lower == 'inuse' || lower == 'đang sạc' || lower == 'đang dùng') {
      bg = AppColors.statusOccupied.withOpacity(0.15);
      fg = AppColors.statusOccupied;
      text = 'Đang sạc';
    } else if (lower == 'reserved' || lower == 'scheduled' || lower == 'pending' || lower == 'đã đặt') {
      bg = AppColors.statusReserved.withOpacity(0.15);
      fg = AppColors.statusReserved;
      if (lower == 'reserved' || lower == 'scheduled') text = 'Đã đặt trước';
      if (lower == 'pending') text = 'Chờ xử lý';
    } else if (lower == 'cancelled' || lower == 'faulted' || lower == 'failed' || lower == 'lỗi' || lower == 'đã hủy') {
      bg = AppColors.statusFaulted.withOpacity(0.15);
      fg = AppColors.statusFaulted;
      if (lower == 'faulted') text = 'Bảo trì / Lỗi';
      if (lower == 'cancelled') text = 'Đã hủy';
      if (lower == 'failed') text = 'Thất bại';
    } else {
      bg = AppColors.statusOffline.withOpacity(0.15);
      fg = AppColors.statusOffline;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
          ],
        ],
      ),
    );
  }
}

