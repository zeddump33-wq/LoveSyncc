import 'package:intl/intl.dart';

class DateFormatUtils {
  static final dateFormat = DateFormat('yyyy-MM-dd');
  static final timeFormat = DateFormat('HH:mm');
  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final displayDateFormat = DateFormat('MMM d, yyyy');
  static final displayDateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  static String formatDate(DateTime date) => dateFormat.format(date);
  static String formatTime(DateTime date) => timeFormat.format(date);
  static String formatDateTime(DateTime date) => dateTimeFormat.format(date);
  static String formatDisplay(DateTime date) => displayDateFormat.format(date);
  static String formatDisplayDateTime(DateTime date) =>
      displayDateTimeFormat.format(date);

  static DateTime parseDate(String date) => dateFormat.parse(date);
  static DateTime parseDateTime(String dateTime) =>
      dateTimeFormat.parse(dateTime);

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}y ago';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  static String daysSince(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    return diff.inDays.toString();
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }
}
