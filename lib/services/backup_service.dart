import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/timetable.dart';
import '../models/attendance_record.dart';
import '../models/holiday.dart';
import '../models/app_settings.dart';

class BackupData {
  final String version;
  final String exportedAt;
  final List<Timetable> timetables;
  final List<AttendanceRecord> attendanceRecords;
  final List<Holiday> holidays;
  final AppSettings settings;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.timetables,
    required this.attendanceRecords,
    required this.holidays,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt,
    'timetables': timetables.map((t) => t.toJson()).toList(),
    'attendanceRecords': attendanceRecords.map((r) => r.toJson()).toList(),
    'holidays': holidays.map((h) => h.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0.0',
      exportedAt: json['exportedAt'] as String? ?? DateTime.now().toIso8601String(),
      timetables: (json['timetables'] as List<dynamic>?)
              ?.map((e) => Timetable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceRecords: (json['attendanceRecords'] as List<dynamic>?)
              ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      holidays: (json['holidays'] as List<dynamic>?)
              ?.map((e) => Holiday.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const AppSettings(),
    );
  }
}

class BackupService {
  static String generateBackupJson({
    required List<Timetable> timetables,
    required List<AttendanceRecord> attendanceRecords,
    required List<Holiday> holidays,
    required AppSettings settings,
  }) {
    final backup = BackupData(
      version: '1.0.0',
      exportedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      timetables: timetables,
      attendanceRecords: attendanceRecords,
      holidays: holidays,
      settings: settings,
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup.toJson());
  }

  static BackupData parseBackupJson(String jsonString) {
    final dynamic parsed = jsonDecode(jsonString);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format: root must be a JSON object');
    }
    return BackupData.fromJson(parsed);
  }
}
