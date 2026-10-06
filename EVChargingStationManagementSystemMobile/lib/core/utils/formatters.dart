import 'package:intl/intl.dart';

class Formatters {
  // Format Currency: 50000 -> "50.000 đ"
  static String formatCurrency(num? amount) {
    if (amount == null) return '0 đ';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(amount).trim();
  }

  // Format Date: 2026-09-22 -> "22/09/2026"
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format Time: 14:30
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  // Format Date & Time: "14:30 - 22/09/2026"
  static String formatDateTime(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      date = DateTime.tryParse(dateInput);
    }
    if (date == null) return '-';
    return DateFormat('HH:mm - dd/MM/yyyy').format(date.toLocal());
  }

  // Format Seconds to Duration string: 3665 -> "01:01:05"
  static String formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Format Energy: 15.45 -> "15.45 kWh"
  static String formatEnergy(num? energy) {
    if (energy == null) return '0.00 kWh';
    return '${energy.toStringAsFixed(2)} kWh';
  }

  // Format Power: 60 -> "60 kW"
  static String formatPower(num? power) {
    if (power == null) return '0 kW';
    return '${power.toStringAsFixed(0)} kW';
  }
}
