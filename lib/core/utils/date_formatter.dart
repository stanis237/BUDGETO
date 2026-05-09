import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd MMM', 'fr_FR').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'fr_FR').format(date);
  }

  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM', 'fr_FR').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return format(date);
  }
}
