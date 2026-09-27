import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  late AppSettings _settings;

  SettingsProvider(this._storageService) {
    _settings = _storageService.loadSettings();
  }

  AppSettings get settings => _settings;

  ThemeMode get themeMode => _settings.themeMode;
  AppColorOption get activeColor => _settings.activeColor;
  Set<int> get weeklyHolidays => _settings.weeklyHolidays;
  double get minimumAttendance => _settings.minimumAttendance;
  double get targetAttendance => _settings.targetAttendance;
  double get lateAttendanceWeight => _settings.lateAttendanceWeight;
  bool get showBunkPredictor => _settings.showBunkPredictor;
  bool get enableClassReminder => _settings.enableClassReminder;
  int get classReminderLeadMinutes => _settings.classReminderLeadMinutes;
  bool get enableMissedClassReminder => _settings.enableMissedClassReminder;
  int get missedReminderMinutesAfter => _settings.missedReminderMinutesAfter;
  bool get pauseRemindersOnHolidays => _settings.pauseRemindersOnHolidays;
  String? get activeTimetableId => _settings.activeTimetableId;

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _storageService.saveSettings(_settings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await updateSettings(_settings.copyWith(themeMode: mode));
  }

  Future<void> setActiveColor(AppColorOption color) async {
    await updateSettings(_settings.copyWith(activeColor: color));
  }

  /// Toggles a day of the week (1=Mon ... 7=Sun) as a weekly holiday.
  /// Allows unmarking Sunday (7) and natively marking Saturday (6) or any other day.
  Future<void> toggleWeeklyHoliday(int dayOfWeek) async {
    final updated = Set<int>.from(_settings.weeklyHolidays);
    if (updated.contains(dayOfWeek)) {
      updated.remove(dayOfWeek);
    } else {
      updated.add(dayOfWeek);
    }
    await updateSettings(_settings.copyWith(weeklyHolidays: updated));
  }

  Future<void> setMinimumAttendance(double value) async {
    await updateSettings(_settings.copyWith(minimumAttendance: value));
  }

  Future<void> setTargetAttendance(double value) async {
    await updateSettings(_settings.copyWith(targetAttendance: value));
  }

  Future<void> setLateAttendanceWeight(double weight) async {
    await updateSettings(_settings.copyWith(lateAttendanceWeight: weight));
  }

  Future<void> setShowBunkPredictor(bool show) async {
    await updateSettings(_settings.copyWith(showBunkPredictor: show));
  }

  Future<void> setClassReminder({
    required bool enabled,
    required int leadMinutes,
  }) async {
    await updateSettings(_settings.copyWith(
      enableClassReminder: enabled,
      classReminderLeadMinutes: leadMinutes,
    ));
  }

  Future<void> setMissedClassReminder({
    required bool enabled,
    required int minutesAfter,
  }) async {
    await updateSettings(_settings.copyWith(
      enableMissedClassReminder: enabled,
      missedReminderMinutesAfter: minutesAfter,
    ));
  }

  Future<void> setPauseRemindersOnHolidays(bool pause) async {
    await updateSettings(_settings.copyWith(pauseRemindersOnHolidays: pause));
  }

  Future<void> setActiveTimetableId(String? id) async {
    if (id == null) {
      await updateSettings(_settings.copyWith(clearActiveTimetable: true));
    } else {
      await updateSettings(_settings.copyWith(activeTimetableId: id));
    }
  }
}
