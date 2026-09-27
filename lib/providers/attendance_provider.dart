import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/absence_reason.dart';
import '../models/holiday.dart';
import '../models/class_session.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/holiday_service.dart';

class SubjectAttendanceStats {
  final String subject;
  final double attendedPoints;
  final double conductedPoints;
  final int totalConducted;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final double percentage;
  final bool isBelowPar;
  final int? safeSkips;
  final int? classesNeededToRecover;
  final bool isBelowGoal;
  final int? safeSkipsForGoal;
  final int? classesNeededForGoal;

  SubjectAttendanceStats({
    required this.subject,
    required this.attendedPoints,
    required this.conductedPoints,
    required this.totalConducted,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.percentage,
    required this.isBelowPar,
    this.safeSkips,
    this.classesNeededToRecover,
    this.isBelowGoal = false,
    this.safeSkipsForGoal,
    this.classesNeededForGoal,
  });
}

class AttendanceStatsSummary {
  final double overallPercentage;
  final double totalAttendedPoints;
  final double totalConductedPoints;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalConductedClasses;
  final bool isBelowPar;
  final int? overallSafeSkips;
  final int? overallNeededToRecover;
  final bool isBelowGoal;
  final int? overallSafeSkipsForGoal;
  final int? overallNeededForGoal;
  final List<SubjectAttendanceStats> subjectBreakdown;

  AttendanceStatsSummary({
    required this.overallPercentage,
    required this.totalAttendedPoints,
    required this.totalConductedPoints,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalConductedClasses,
    required this.isBelowPar,
    this.overallSafeSkips,
    this.overallNeededToRecover,
    this.isBelowGoal = false,
    this.overallSafeSkipsForGoal,
    this.overallNeededForGoal,
    required this.subjectBreakdown,
  });
}

class AttendanceProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<AttendanceRecord> _records = [];
  List<Holiday> _holidays = [];

  AttendanceProvider(this._storageService) {
    _records = _storageService.loadAttendanceRecords();
    _holidays = _storageService.loadHolidays();
  }

  List<AttendanceRecord> get records => List.unmodifiable(_records);
  List<Holiday> get holidays => List.unmodifiable(_holidays);

  static String formatDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  // --- Daily Records Query ---

  AttendanceRecord getRecordForSession({
    required String timetableId,
    required ClassSession session,
    required DateTime date,
    required double defaultLateWeight,
  }) {
    final dateStr = formatDate(date);
    try {
      return _records.firstWhere(
        (r) => r.classSessionId == session.id && r.date == dateStr,
      );
    } catch (_) {
      // Default unlogged record with class default points
      return AttendanceRecord(
        id: 'rec_${session.id}_$dateStr',
        timetableId: timetableId,
        classSessionId: session.id,
        date: dateStr,
        subject: session.subject,
        status: AttendanceStatus.notMarked,
        points: session.defaultPoints,
        lateWeight: defaultLateWeight,
        note: '',
        updatedAt: DateTime.now(),
      );
    }
  }

  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    final dateStr = formatDate(date);
    return _records.where((r) => r.date == dateStr).toList();
  }

  /// Mark or update attendance for a class session on a given date
  Future<void> setAttendance({
    required String timetableId,
    required ClassSession session,
    required DateTime date,
    required AttendanceStatus status,
    double? points,
    double? lateWeight,
    AbsenceReason? absenceReason,
    String? note,
  }) async {
    final dateStr = formatDate(date);
    final idx = _records.indexWhere(
      (r) => r.classSessionId == session.id && r.date == dateStr,
    );

    final resolvedPoints = points ?? session.defaultPoints;
    final resolvedLateWeight = lateWeight ?? 0.5;

    if (idx != -1) {
      final existing = _records[idx];
      _records[idx] = existing.copyWith(
        status: status,
        points: resolvedPoints,
        lateWeight: resolvedLateWeight,
        absenceReason: absenceReason,
        clearAbsenceReason: status != AttendanceStatus.absent,
        note: note ?? existing.note,
        updatedAt: DateTime.now(),
      );
    } else {
      _records.add(
        AttendanceRecord(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          timetableId: timetableId,
          classSessionId: session.id,
          date: dateStr,
          subject: session.subject,
          status: status,
          points: resolvedPoints,
          lateWeight: resolvedLateWeight,
          absenceReason: status == AttendanceStatus.absent ? absenceReason : null,
          note: note ?? '',
          updatedAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
    await _storageService.saveAttendanceRecords(_records);
  }

  /// Update an existing past attendance record directly
  Future<void> updateExistingRecord(AttendanceRecord updated) async {
    final idx = _records.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _records[idx] = updated.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      await _storageService.saveAttendanceRecords(_records);
    }
  }

  // --- Holidays ---

  bool isHolidayOnDate(DateTime date, AppSettings settings) {
    return HolidayService.isHoliday(
      date: date,
      settings: settings,
      holidays: _holidays,
    );
  }

  String? getHolidayTitle(DateTime date, AppSettings settings) {
    return HolidayService.getHolidayName(
      date: date,
      settings: settings,
      holidays: _holidays,
    );
  }

  /// Mark or unmark a date as a custom holiday
  Future<void> toggleHoliday(DateTime date, {String title = 'Holiday'}) async {
    final dateStr = formatDate(date);
    final idx = _holidays.indexWhere((h) => h.date == dateStr);

    if (idx != -1) {
      _holidays.removeAt(idx);
    } else {
      _holidays.add(
        Holiday(
          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
          date: dateStr,
          title: title.trim().isEmpty ? 'Holiday' : title.trim(),
          isPublic: false,
          isCustom: true,
        ),
      );
    }
    notifyListeners();
    await _storageService.saveHolidays(_holidays);
  }

  Future<void> addPublicHoliday(String dateStr, String title) async {
    _holidays.add(
      Holiday(
        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
        date: dateStr,
        title: title,
        isPublic: true,
        isCustom: false,
      ),
    );
    notifyListeners();
    await _storageService.saveHolidays(_holidays);
  }

  Future<void> removeHoliday(String holidayId) async {
    _holidays.removeWhere((h) => h.id == holidayId);
    notifyListeners();
    await _storageService.saveHolidays(_holidays);
  }

  // --- Combined Dashboard & Statistics Calculation ---

  AttendanceStatsSummary calculateStatistics({
    required AppSettings settings,
    String? filterTimetableId,
  }) {
    // Filter records for active timetable if requested
    final filtered = filterTimetableId != null && filterTimetableId.isNotEmpty
        ? _records.where((r) => r.timetableId == filterTimetableId || r.timetableId.isEmpty).toList()
        : _records;

    final conducted = filtered.where((r) => r.isConducted).toList();

    double totalAttendedPoints = 0.0;
    double totalConductedPoints = 0.0;
    int totalPresent = 0;
    int totalLate = 0;
    int totalAbsent = 0;

    final Map<String, List<AttendanceRecord>> bySubject = {};

    for (final r in conducted) {
      totalAttendedPoints += r.earnedPoints;
      totalConductedPoints += r.maxPoints;

      if (r.status == AttendanceStatus.present) totalPresent++;
      if (r.status == AttendanceStatus.late) totalLate++;
      if (r.status == AttendanceStatus.absent) totalAbsent++;

      final sub = r.subject.trim();
      bySubject.putIfAbsent(sub, () => []).add(r);
    }

    final double overallPct = totalConductedPoints > 0
        ? (totalAttendedPoints / totalConductedPoints) * 100.0
        : 100.0;

    final double minPct = settings.minimumAttendance;
    final double minFraction = minPct / 100.0;
    final double goalPct = settings.targetAttendance;
    final double goalFraction = goalPct / 100.0;

    // Overall Minimum Par Bunk / Recovery Prediction
    int? overallSafeSkips;
    int? overallNeededToRecover;

    if (totalConductedPoints > 0) {
      if (overallPct >= minPct) {
        // Safe skips: (Attended / (Total + X)) >= M -> X <= (Attended / M) - Total
        if (minFraction > 0) {
          final maxSkips = (totalAttendedPoints / minFraction) - totalConductedPoints;
          overallSafeSkips = maxSkips > 0 ? (maxSkips + 1e-9).floor() : 0;
        }
      } else {
        // Classes needed: (Attended + Y) / (Total + Y) >= M -> Y >= (M*Total - Attended) / (1 - M)
        if (minFraction < 1.0) {
          final needed = (minFraction * totalConductedPoints - totalAttendedPoints) / (1.0 - minFraction);
          overallNeededToRecover = needed > 0 ? (needed - 1e-9).ceil() : 1;
        }
      }
    }

    // Overall Target Goal Prediction: "predict how much classes you need to attend to achieve target attendance goal"
    int? overallSafeSkipsForGoal;
    int? overallNeededForGoal;

    if (totalConductedPoints > 0) {
      if (overallPct >= goalPct) {
        if (goalFraction > 0) {
          final maxSkips = (totalAttendedPoints / goalFraction) - totalConductedPoints;
          overallSafeSkipsForGoal = maxSkips > 0 ? (maxSkips + 1e-9).floor() : 0;
        }
      } else {
        if (goalFraction < 1.0) {
          final needed = (goalFraction * totalConductedPoints - totalAttendedPoints) / (1.0 - goalFraction);
          overallNeededForGoal = needed > 0 ? (needed - 1e-9).ceil() : 1;
        }
      }
    }

    // Per-Subject Stats
    final List<SubjectAttendanceStats> subjectStats = [];
    bySubject.forEach((subject, subRecords) {
      double subAttended = 0.0;
      double subConducted = 0.0;
      int sPres = 0;
      int sLate = 0;
      int sAbs = 0;

      for (final r in subRecords) {
        subAttended += r.earnedPoints;
        subConducted += r.maxPoints;
        if (r.status == AttendanceStatus.present) sPres++;
        if (r.status == AttendanceStatus.late) sLate++;
        if (r.status == AttendanceStatus.absent) sAbs++;
      }

      final subPct = subConducted > 0 ? (subAttended / subConducted) * 100.0 : 100.0;
      final bool subBelowPar = subConducted > 0 && subPct < minPct;
      final bool subBelowGoal = subConducted > 0 && subPct < goalPct;

      int? subSkips;
      int? subRecover;

      if (subConducted > 0) {
        if (subPct >= minPct) {
          if (minFraction > 0) {
            final val = (subAttended / minFraction) - subConducted;
            subSkips = val > 0 ? (val + 1e-9).floor() : 0;
          }
        } else {
          if (minFraction < 1.0) {
            final val = (minFraction * subConducted - subAttended) / (1.0 - minFraction);
            subRecover = val > 0 ? (val - 1e-9).ceil() : 1;
          }
        }
      }

      int? subSkipsForGoal;
      int? subNeededForGoal;

      if (subConducted > 0) {
        if (subPct >= goalPct) {
          if (goalFraction > 0) {
            final val = (subAttended / goalFraction) - subConducted;
            subSkipsForGoal = val > 0 ? (val + 1e-9).floor() : 0;
          }
        } else {
          if (goalFraction < 1.0) {
            final val = (goalFraction * subConducted - subAttended) / (1.0 - goalFraction);
            subNeededForGoal = val > 0 ? (val - 1e-9).ceil() : 1;
          }
        }
      }

      subjectStats.add(
        SubjectAttendanceStats(
          subject: subject,
          attendedPoints: subAttended,
          conductedPoints: subConducted,
          totalConducted: subRecords.length,
          presentCount: sPres,
          lateCount: sLate,
          absentCount: sAbs,
          percentage: subPct,
          isBelowPar: subBelowPar,
          safeSkips: subSkips,
          classesNeededToRecover: subRecover,
          isBelowGoal: subBelowGoal,
          safeSkipsForGoal: subSkipsForGoal,
          classesNeededForGoal: subNeededForGoal,
        ),
      );
    });

    // Sort subjects alphabetically
    subjectStats.sort((a, b) => a.subject.compareTo(b.subject));

    return AttendanceStatsSummary(
      overallPercentage: overallPct,
      totalAttendedPoints: totalAttendedPoints,
      totalConductedPoints: totalConductedPoints,
      totalPresent: totalPresent,
      totalLate: totalLate,
      totalAbsent: totalAbsent,
      totalConductedClasses: conducted.length,
      isBelowPar: totalConductedPoints > 0 && overallPct < minPct,
      overallSafeSkips: overallSafeSkips,
      overallNeededToRecover: overallNeededToRecover,
      isBelowGoal: totalConductedPoints > 0 && overallPct < goalPct,
      overallSafeSkipsForGoal: overallSafeSkipsForGoal,
      overallNeededForGoal: overallNeededForGoal,
      subjectBreakdown: subjectStats,
    );
  }

  /// Bulk restore for backup
  Future<void> replaceAll({
    required List<AttendanceRecord> records,
    required List<Holiday> holidays,
  }) async {
    _records = List.from(records);
    _holidays = List.from(holidays);
    notifyListeners();
    await _storageService.saveAttendanceRecords(_records);
    await _storageService.saveHolidays(_holidays);
  }
}
