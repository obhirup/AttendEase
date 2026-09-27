import 'package:intl/intl.dart';
import '../models/holiday.dart';
import '../models/app_settings.dart';

class HolidayService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime dt) => _dateFormat.format(dt);

  /// Checks if a given date is any form of holiday (weekly, public, or custom)
  static bool isHoliday({
    required DateTime date,
    required AppSettings settings,
    required List<Holiday> holidays,
  }) {
    // 1. Check weekly holidays (e.g. Sunday = 7, Saturday = 6)
    if (settings.weeklyHolidays.contains(date.weekday)) {
      return true;
    }

    // 2. Check explicitly marked or public holidays
    final dateStr = formatDate(date);
    return holidays.any((h) => h.date == dateStr);
  }

  /// Returns friendly title/reason if the date is a holiday, or null
  static String? getHolidayName({
    required DateTime date,
    required AppSettings settings,
    required List<Holiday> holidays,
  }) {
    final dateStr = formatDate(date);
    final match = holidays.where((h) => h.date == dateStr).toList();
    if (match.isNotEmpty) {
      return match.first.title;
    }

    if (settings.weeklyHolidays.contains(date.weekday)) {
      final dayName = DateFormat('EEEE').format(date);
      return 'Weekly Holiday ($dayName)';
    }

    return null;
  }

  /// Generates the clear holiday notice banner text requested by user:
  /// "In the attendance section when scrolling through the days Notify the user that today is a holiday rather than just 'no classes today'."
  static String getHolidayBannerText({
    required DateTime date,
    required AppSettings settings,
    required List<Holiday> holidays,
  }) {
    final name = getHolidayName(date: date, settings: settings, holidays: holidays);
    if (name != null) {
      return '🎉 Today is a Holiday: $name. Classes & reminders are paused.';
    }
    return 'No classes scheduled for today.';
  }
}
