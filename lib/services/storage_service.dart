import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable.dart';
import '../models/attendance_record.dart';
import '../models/holiday.dart';
import '../models/app_settings.dart';
import '../models/calculator_settings.dart';

class StorageService {
  static const String _keyTimetables = 'attend_pulse_timetables';
  static const String _keyAttendance = 'attend_pulse_attendance_records';
  static const String _keyHolidays = 'attend_pulse_holidays';
  static const String _keySettings = 'attend_pulse_settings';
  static const String _keyCalculatorSettings = 'casio_calculator_settings';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Timetables ---
  List<Timetable> loadTimetables() {
    final raw = _prefs.getString(_keyTimetables);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list.map((e) => Timetable.fromJson(e as Map<String, dynamic>)).toList();
      // Remove the default inbuilt routine if present from earlier runs
      return parsed.where((t) => t.id != 'tt_semester_default').toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTimetables(List<Timetable> timetables) async {
    final raw = jsonEncode(timetables.map((t) => t.toJson()).toList());
    await _prefs.setString(_keyTimetables, raw);
  }

  // --- Attendance Records ---
  List<AttendanceRecord> loadAttendanceRecords() {
    final raw = _prefs.getString(_keyAttendance);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAttendanceRecords(List<AttendanceRecord> records) async {
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await _prefs.setString(_keyAttendance, raw);
  }

  // --- Holidays ---
  List<Holiday> loadHolidays() {
    final raw = _prefs.getString(_keyHolidays);
    if (raw == null || raw.isEmpty) {
      return _generateDefaultPublicHolidays();
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Holiday.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _generateDefaultPublicHolidays();
    }
  }

  Future<void> saveHolidays(List<Holiday> holidays) async {
    final raw = jsonEncode(holidays.map((h) => h.toJson()).toList());
    await _prefs.setString(_keyHolidays, raw);
  }

  // --- Settings ---
  AppSettings loadSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw == null || raw.isEmpty) {
      return const AppSettings();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (e) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await _prefs.setString(_keySettings, raw);
  }

  // --- Calculator Settings ---
  CalculatorSettings loadCalculatorSettings() {
    final raw = _prefs.getString(_keyCalculatorSettings);
    if (raw == null || raw.isEmpty) {
      return const CalculatorSettings();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CalculatorSettings.fromJson(map);
    } catch (_) {
      return const CalculatorSettings();
    }
  }

  Future<void> saveCalculatorSettings(CalculatorSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await _prefs.setString(_keyCalculatorSettings, raw);
  }

  List<Holiday> _generateDefaultPublicHolidays() {
    final year = DateTime.now().year;
    return [
      Holiday(id: 'h_new_year', date: '$year-01-01', title: 'New Year\'s Day', isPublic: true, isCustom: false),
      Holiday(id: 'h_republic_day', date: '$year-01-26', title: 'Republic Day', isPublic: true, isCustom: false),
      Holiday(id: 'h_labor_day', date: '$year-05-01', title: 'Labor Day', isPublic: true, isCustom: false),
      Holiday(id: 'h_independence', date: '$year-08-15', title: 'Independence Day', isPublic: true, isCustom: false),
      Holiday(id: 'h_gandhi', date: '$year-10-02', title: 'Gandhi Jayanti', isPublic: true, isCustom: false),
      Holiday(id: 'h_diwali', date: '$year-11-01', title: 'Diwali Break', isPublic: true, isCustom: false),
      Holiday(id: 'h_christmas', date: '$year-12-25', title: 'Christmas Day', isPublic: true, isCustom: false),
    ];
  }
}
