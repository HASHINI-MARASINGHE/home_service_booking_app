/// Display formatting for LKR amounts, Colombo-local dates and slot times.
abstract final class Formatters {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// `LKR 14,500` — amounts are whole rupees throughout the app.
  static String lkr(num? amount) {
    if (amount == null) return 'LKR —';
    final rounded = amount.round();
    final digits = rounded.abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'LKR ${rounded < 0 ? '-' : ''}$grouped';
  }

  static String monthYear(DateTime date) =>
      '${_monthsLong[date.month - 1]} ${date.year}';

  static String month(DateTime date) => _months[date.month - 1];

  static String weekdayShort(DateTime date) =>
      _weekdays[date.weekday - 1].substring(0, 3).toUpperCase();

  /// `Tuesday, 14 Nov 2024`
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${month(date)} ${date.year}';

  /// `14 Nov 2024`
  static String shortDate(DateTime date) =>
      '${date.day} ${month(date)} ${date.year}';

  /// `Thu 16 Nov`
  static String compactDate(DateTime date) =>
      '${_weekdays[date.weekday - 1].substring(0, 3)} ${date.day} ${month(date)}';

  /// `13:30` → `01:30 PM`; `13:30` → `1:30 PM` when [padHour] is false.
  static String time12(String hhmm, {bool padHour = true}) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final h = padHour ? h12.toString().padLeft(2, '0') : '$h12';
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
  }

  /// `10:00 AM – 11:30 AM`
  static String timeRange(String start, String end) =>
      '${time12(start)} – ${time12(end)}';

  /// Local wall-clock time of a timestamp, e.g. `11:20 AM`.
  static String clock(DateTime time) => time12(
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}',
    padHour: false,
  );

  /// `Today, 11:20 AM`, `Yesterday, …` or `14 Nov, …`.
  static String relativeStamp(DateTime time, DateTime now) {
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final prefix = switch (diff) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => '${time.day} ${month(time)}',
    };
    return '$prefix, ${clock(time)}';
  }

  /// Parses `YYYY-MM-DD` into a date-only [DateTime].
  static DateTime? parseIsoDate(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
