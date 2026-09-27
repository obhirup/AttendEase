import 'package:intl/intl.dart';
import '../models/class_session.dart';
import '../models/attendance_record.dart';
import '../models/app_settings.dart';
import '../models/holiday.dart';
import 'holiday_service.dart';

class ScheduledReminder {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String type; // 'class_start' or 'missed_mark'

  ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
  });
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final List<ScheduledReminder> _activeReminders = [];

  List<ScheduledReminder> get activeReminders => List.unmodifiable(_activeReminders);

  /// Computes reminders based on today's sessions, attendance status, and holidays
  void computeReminders({
    required List<ClassSession> todaySessions,
    required List<AttendanceRecord> todayRecords,
    required AppSettings settings,
    required List<Holiday> holidays,
    DateTime? simulatedNow,
  }) {
    _activeReminders.clear();

    final now = simulatedNow ?? DateTime.now();

    // Check if reminders should be paused
    final isHolidayToday = HolidayService.isHoliday(
      date: now,
      settings: settings,
      holidays: holidays,
    );

    if (settings.pauseRemindersOnHolidays && isHolidayToday) {
      // Reminders are automatically paused during holidays/breaks
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    for (final session in todaySessions) {
      // 1. Class Start Reminder
      if (settings.enableClassReminder) {
        final startDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          session.startHour,
          session.startMinute,
        );

        final reminderTime = startDateTime.subtract(
          Duration(minutes: settings.classReminderLeadMinutes),
        );

        final leadText = settings.classReminderLeadMinutes == 0
            ? 'starts now'
            : 'starts in ${settings.classReminderLeadMinutes} minutes';

        _activeReminders.add(
          ScheduledReminder(
            id: 'reminder_start_${session.id}',
            title: 'Upcoming Class: ${session.subject}',
            body: '${session.subject} in ${session.room.isNotEmpty ? session.room : "assigned hall"} $leadText (${session.startTimeFormatted}).',
            scheduledTime: reminderTime,
            type: 'class_start',
          ),
        );
      }

      // 2. Missed Log Reminder
      // "If user forgets to mark a class even after the time of the class is over send a notification reminding the user to mark the class (example: 'Did you attend Physics at 10:00 AM?')"
      if (settings.enableMissedClassReminder) {
        final endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          session.endHour,
          session.endMinute,
        );

        final missedCheckTime = endDateTime.add(
          Duration(minutes: settings.missedReminderMinutesAfter),
        );

        // Check if marked
        final existingRecord = todayRecords.firstWhere(
          (r) => r.classSessionId == session.id && r.date == dateStr,
          orElse: () => AttendanceRecord(
            id: '',
            timetableId: '',
            classSessionId: session.id,
            date: dateStr,
            subject: session.subject,
            status: AttendanceStatus.notMarked,
            updatedAt: now,
          ),
        );

        if (existingRecord.status == AttendanceStatus.notMarked) {
          _activeReminders.add(
            ScheduledReminder(
              id: 'reminder_missed_${session.id}',
              title: 'Class Completed: Attendance Check',
              body: 'Did you attend ${session.subject} at ${session.startTimeFormatted}? Tap to log your status.',
              scheduledTime: missedCheckTime,
              type: 'missed_mark',
            ),
          );
        }
      }
    }
  }

  /// Finds any active notifications that should fire right now
  List<ScheduledReminder> getPendingAlerts(DateTime now) {
    return _activeReminders.where((r) {
      final diff = r.scheduledTime.difference(now).inMinutes;
      return diff >= -15 && diff <= 5;
    }).toList();
  }
}
