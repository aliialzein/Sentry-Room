import 'package:intl/intl.dart';

class DateUtils {
  static String formatFull(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  static String formatShortTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String formatLong(DateTime dt) => DateFormat('EEEE, MMM d, yyyy HH:mm:ss').format(dt);
}
