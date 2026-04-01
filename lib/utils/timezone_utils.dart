import 'package:intl/intl.dart';

class AppTimeZone {
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  static DateTime toIst(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(_istOffset);
  }

  static DateTime? parseToIst(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return toIst(parsed);
  }

  static String formatIst(DateTime dt, String pattern) {
    return DateFormat(pattern).format(toIst(dt));
  }

  static String istDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(toIst(dt));
  }
}
