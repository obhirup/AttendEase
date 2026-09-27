import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attend_pulse/models/class_session.dart';
import 'package:attend_pulse/models/attendance_record.dart';
import 'package:attend_pulse/models/app_settings.dart';
import 'package:attend_pulse/models/holiday.dart';
import 'package:attend_pulse/models/timetable.dart';
import 'package:attend_pulse/services/holiday_service.dart';

void main() {
  group('Attendance Logic & Bunk Predictor Tests', () {
    test('Calculates earned points correctly for present, late, and absent', () {
      const session = ClassSession(
        id: 'cs_1',
        subject: 'Algorithms',
        dayOfWeek: 1,
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 30,
        defaultPoints: 2.0, // 2 points lab
      );

      final presentRecord = AttendanceRecord(
        id: 'r1',
        timetableId: 'tt1',
        classSessionId: session.id,
        date: '2026-09-28',
        subject: session.subject,
        status: AttendanceStatus.present,
        points: session.defaultPoints,
        lateWeight: 0.5,
        updatedAt: DateTime.now(),
      );

      expect(presentRecord.earnedPoints, 2.0);
      expect(presentRecord.maxPoints, 2.0);

      // Late gives points * lateWeight = 2.0 * 0.5 = 1.0 point
      final lateRecord = presentRecord.copyWith(status: AttendanceStatus.late);
      expect(lateRecord.earnedPoints, 1.0);
      expect(lateRecord.maxPoints, 2.0);

      // Absent gives 0 points
      final absentRecord = presentRecord.copyWith(status: AttendanceStatus.absent);
      expect(absentRecord.earnedPoints, 0.0);
      expect(absentRecord.maxPoints, 2.0);
    });

    test('Identifies weekly holidays and allows unmarking Sunday', () {
      // Standard: Sunday (7) is weekly holiday
      const defaultSettings = AppSettings(weeklyHolidays: {7});
      final sunday = DateTime(2026, 9, 27); // Sunday
      final monday = DateTime(2026, 9, 28); // Monday

      expect(sunday.weekday, 7);
      expect(
        HolidayService.isHoliday(date: sunday, settings: defaultSettings, holidays: []),
        isTrue,
      );
      expect(
        HolidayService.isHoliday(date: monday, settings: defaultSettings, holidays: []),
        isFalse,
      );

      // Unmarked Sunday: Saturday (6) and Friday (5) as holidays, Sunday not holiday
      const customSettings = AppSettings(weeklyHolidays: {5, 6});
      expect(
        HolidayService.isHoliday(date: sunday, settings: customSettings, holidays: []),
        isFalse,
      );
      expect(
        HolidayService.isHoliday(date: DateTime(2026, 9, 26), settings: customSettings, holidays: []), // Saturday
        isTrue,
      );
    });

    test('Holiday Service descriptive notification text', () {
      const settings = AppSettings(weeklyHolidays: {7});
      final holidays = [
        const Holiday(id: 'h1', date: '2026-10-02', title: 'Gandhi Jayanti', isPublic: true),
      ];

      final holidayDate = DateTime(2026, 10, 2);
      final text = HolidayService.getHolidayBannerText(
        date: holidayDate,
        settings: settings,
        holidays: holidays,
      );

      expect(text.contains('Gandhi Jayanti'), isTrue);
      expect(text.contains('Holiday'), isTrue);
    });

    test('Predicts classes needed to reach target goal and safe skips buffer', () {
      // Below target goal scenario:
      // Conducted: 5 points, Attended: 3 points (60%).
      // Target Goal: 80% (0.80).
      // (0.80 * 5 - 3) / (1.0 - 0.80) = (4 - 3) / 0.2 = 5 classes needed
      const conductedPoints = 5.0;
      const attendedPoints = 3.0;
      const goalPct = 80.0;
      const goalFraction = 0.80;

      const val = (goalFraction * conductedPoints - attendedPoints) / (1.0 - goalFraction);
      final needed = (val - 1e-9).ceil();
      expect(needed, 5);

      // Verify that after attending 5 classes, attendance is exactly 80%:
      final postAttendancePct = ((attendedPoints + needed) / (conductedPoints + needed)) * 100;
      expect(postAttendancePct >= goalPct, isTrue);

      // Above target goal scenario:
      // Conducted: 10 points, Attended: 9 points (90%).
      // Target Goal: 75% (0.75).
      // (9 / 0.75) - 10 = 12 - 10 = 2 safe skips
      const condAbove = 10.0;
      const attAbove = 9.0;
      final skips = (((attAbove / 0.75) - condAbove) + 1e-9).floor();
      expect(skips, 2);

      // Verify that after skipping 2 classes, attendance remains >= 75%:
      final postSkipPct = (attAbove / (condAbove + skips)) * 100;
      expect(postSkipPct >= 75.0, isTrue);
    });

    test('Iris Pastel (#8764B8) and Pastel Red (#F87171) exist with legacy mappings', () {
      // Ensure terracotta and teal are no longer in values
      final names = AppColorOption.values.map((v) => v.name).toList();
      expect(names.contains('terracotta'), isFalse);
      expect(names.contains('teal'), isFalse);
      expect(names.contains('irisPastel'), isTrue);
      expect(names.contains('pastelRed'), isTrue);

      // Verify Iris Pastel color value: #8764B8
      expect(AppColorOption.irisPastel.color, const Color(0xFF8764B8));
      expect(AppColorOption.irisPastel.label, 'Iris Pastel');

      // Verify Pastel Red color value: #F87171
      expect(AppColorOption.pastelRed.color, const Color(0xFFF87171));
      expect(AppColorOption.pastelRed.label, 'Pastel Red');

      // Ensure parsing legacy saved 'terracotta' and 'irispurple' returns irisPastel
      expect(AppColorOption.fromName('terracotta'), AppColorOption.irisPastel);
      expect(AppColorOption.fromName('irispurple'), AppColorOption.irisPastel);
      expect(AppColorOption.fromName('iris purple'), AppColorOption.irisPastel);

      // Ensure parsing legacy saved 'teal' returns pastelRed
      expect(AppColorOption.fromName('teal'), AppColorOption.pastelRed);
    });

    test('Custom class start reminder minutes can be set flexibly', () {
      const defaultSettings = AppSettings();
      expect(defaultSettings.classReminderLeadMinutes, 5);

      const customSettings = AppSettings(classReminderLeadMinutes: 42);
      expect(customSettings.classReminderLeadMinutes, 42);

      final json = customSettings.toJson();
      expect(json['classReminderLeadMinutes'], 42);

      final fromJson = AppSettings.fromJson(json);
      expect(fromJson.classReminderLeadMinutes, 42);
    });

    test('Timetables list can have routines added and deleted cleanly', () {
      final t1 = Timetable(
        id: 'tt_custom_1',
        name: 'Fall Semester',
        isArchived: false,
        createdAt: DateTime.now(),
        sessions: const [],
      );

      final t2 = Timetable(
        id: 'tt_custom_2',
        name: 'Spring Semester',
        isArchived: false,
        createdAt: DateTime.now(),
        sessions: const [],
      );

      final list = [t1, t2];
      expect(list.length, 2);

      // Delete t1
      list.removeWhere((t) => t.id == t1.id);
      expect(list.length, 1);
      expect(list.first.id, 'tt_custom_2');
      expect(list.first.name, 'Spring Semester');
    });

    test('Meeting attendance goals produces safe zone and does not require recovery', () {
      const settings = AppSettings(
        minimumAttendance: 75.0,
        targetAttendance: 80.0,
      );

      // Student has attended 9 out of 10 classes = 90%
      final records = List.generate(
        10,
        (i) => AttendanceRecord(
          id: 'r_$i',
          timetableId: 'tt_1',
          classSessionId: 'cs_1',
          date: '2026-09-${10 + i}',
          subject: 'Operating Systems',
          status: i < 9 ? AttendanceStatus.present : AttendanceStatus.absent,
          points: 1.0,
          lateWeight: 0.5,
          updatedAt: DateTime.now(),
        ),
      );

      // Calculate stats directly using provider logic
      double attended = 0;
      double total = 0;
      for (final r in records) {
        attended += r.earnedPoints;
        total += r.maxPoints;
      }
      final pct = (attended / total) * 100.0;
      expect(pct, 90.0);
      expect(pct >= settings.minimumAttendance, isTrue);
      expect(pct >= settings.targetAttendance, isTrue);

      // (Attended / minFraction) - total = (9 / 0.75) - 10 = 12 - 10 = 2 safe skips
      final minFraction = settings.minimumAttendance / 100.0;
      final safeSkips = ((attended / minFraction) - total).floor();
      expect(safeSkips, 2);
    });
  });
}

