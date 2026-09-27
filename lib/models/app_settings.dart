import 'package:flutter/material.dart';

enum AppColorOption {
  irisPastel('Iris Pastel', 0xFF8764B8), // "change the iris purple name to Iris Pastel and use #8764B8 as its colour"
  blue('Blue', 0xFF38BDF8),             // "make the colour blue a bit more sky blue"
  pastelRed('Pastel Red', 0xFFF87171),   // "remove the teal option and add a Pastel red instead"
  pink('Pink', 0xFFF9A8D4),             // "change the pink to baby pin ( dont change the name of the colours just the shade itself)"
  emerald('Emerald', 0xFF10B981),
  amber('Amber', 0xFFF59E0B);

  final String label;
  final int primaryHex;

  const AppColorOption(this.label, this.primaryHex);

  Color get color => Color(primaryHex);

  static AppColorOption fromName(String? name) {
    if (name == null) return AppColorOption.irisPastel;
    final lower = name.toLowerCase();
    if (lower == 'terracotta' || lower == 'irispurple' || lower == 'iris purple') {
      return AppColorOption.irisPastel;
    }
    if (lower == 'teal') {
      return AppColorOption.pastelRed;
    }
    return AppColorOption.values.firstWhere(
      (e) => e.name.toLowerCase() == lower || e.label.toLowerCase() == lower,
      orElse: () => AppColorOption.irisPastel,
    );
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final AppColorOption activeColor;
  final Set<int> weeklyHolidays; // 1 = Monday, 7 = Sunday
  final double minimumAttendance; // e.g. 75.0%
  final double targetAttendance; // e.g. 85.0%
  final double lateAttendanceWeight; // e.g. 0.5
  final bool showBunkPredictor;
  final bool enableClassReminder;
  final int classReminderLeadMinutes; // 0, 5, 10, 15, 30
  final bool enableMissedClassReminder;
  final int missedReminderMinutesAfter; // 10, 15, 30
  final bool pauseRemindersOnHolidays;
  final String? activeTimetableId;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.activeColor = AppColorOption.irisPastel,
    this.weeklyHolidays = const {7}, // Sunday by default, can unmark or add other days
    this.minimumAttendance = 75.0,
    this.targetAttendance = 85.0,
    this.lateAttendanceWeight = 0.5,
    this.showBunkPredictor = true,
    this.enableClassReminder = true,
    this.classReminderLeadMinutes = 5,
    this.enableMissedClassReminder = true,
    this.missedReminderMinutesAfter = 10,
    this.pauseRemindersOnHolidays = true,
    this.activeTimetableId,
  });

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'activeColor': activeColor.name,
    'weeklyHolidays': weeklyHolidays.toList(),
    'minimumAttendance': minimumAttendance,
    'targetAttendance': targetAttendance,
    'lateAttendanceWeight': lateAttendanceWeight,
    'showBunkPredictor': showBunkPredictor,
    'enableClassReminder': enableClassReminder,
    'classReminderLeadMinutes': classReminderLeadMinutes,
    'enableMissedClassReminder': enableMissedClassReminder,
    'missedReminderMinutesAfter': missedReminderMinutesAfter,
    'pauseRemindersOnHolidays': pauseRemindersOnHolidays,
    'activeTimetableId': activeTimetableId,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode mode = ThemeMode.system;
    if (json['themeMode'] == 'light') mode = ThemeMode.light;
    if (json['themeMode'] == 'dark') mode = ThemeMode.dark;

    final weekly = (json['weeklyHolidays'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toSet() ??
        {7};

    return AppSettings(
      themeMode: mode,
      activeColor: AppColorOption.fromName(json['activeColor'] as String?),
      weeklyHolidays: weekly,
      minimumAttendance: (json['minimumAttendance'] as num?)?.toDouble() ?? 75.0,
      targetAttendance: (json['targetAttendance'] as num?)?.toDouble() ?? 85.0,
      lateAttendanceWeight: (json['lateAttendanceWeight'] as num?)?.toDouble() ?? 0.5,
      showBunkPredictor: json['showBunkPredictor'] as bool? ?? true,
      enableClassReminder: json['enableClassReminder'] as bool? ?? true,
      classReminderLeadMinutes: json['classReminderLeadMinutes'] as int? ?? 5,
      enableMissedClassReminder: json['enableMissedClassReminder'] as bool? ?? true,
      missedReminderMinutesAfter: json['missedReminderMinutesAfter'] as int? ?? 10,
      pauseRemindersOnHolidays: json['pauseRemindersOnHolidays'] as bool? ?? true,
      activeTimetableId: json['activeTimetableId'] as String?,
    );
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppColorOption? activeColor,
    Set<int>? weeklyHolidays,
    double? minimumAttendance,
    double? targetAttendance,
    double? lateAttendanceWeight,
    bool? showBunkPredictor,
    bool? enableClassReminder,
    int? classReminderLeadMinutes,
    bool? enableMissedClassReminder,
    int? missedReminderMinutesAfter,
    bool? pauseRemindersOnHolidays,
    String? activeTimetableId,
    bool clearActiveTimetable = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      activeColor: activeColor ?? this.activeColor,
      weeklyHolidays: weeklyHolidays ?? this.weeklyHolidays,
      minimumAttendance: minimumAttendance ?? this.minimumAttendance,
      targetAttendance: targetAttendance ?? this.targetAttendance,
      lateAttendanceWeight: lateAttendanceWeight ?? this.lateAttendanceWeight,
      showBunkPredictor: showBunkPredictor ?? this.showBunkPredictor,
      enableClassReminder: enableClassReminder ?? this.enableClassReminder,
      classReminderLeadMinutes: classReminderLeadMinutes ?? this.classReminderLeadMinutes,
      enableMissedClassReminder: enableMissedClassReminder ?? this.enableMissedClassReminder,
      missedReminderMinutesAfter: missedReminderMinutesAfter ?? this.missedReminderMinutesAfter,
      pauseRemindersOnHolidays: pauseRemindersOnHolidays ?? this.pauseRemindersOnHolidays,
      activeTimetableId: clearActiveTimetable ? null : (activeTimetableId ?? this.activeTimetableId),
    );
  }
}
