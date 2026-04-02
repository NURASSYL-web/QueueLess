import 'package:intl/intl.dart';

class TimeFormatter {
  static String queueWindowLabel(DateTime? value) {
    if (value == null) return 'No recent updates';

    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hr ago';
    return 'Updated ${DateFormat.MMMd().add_Hm().format(value)}';
  }

  static String formatEstimatedTime(int minutes) {
    if (minutes <= 5) return '$minutes min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}
