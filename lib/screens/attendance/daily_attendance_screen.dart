import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/absence_reason.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';
import '../../widgets/holiday_banner.dart';
import 'log_edit_dialog.dart';
import 'past_entries_screen.dart';

class DailyAttendanceScreen extends StatefulWidget {
  const DailyAttendanceScreen({super.key});

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int dayDelta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: dayDelta));
    });
  }

  void _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final timetable = context.watch<TimetableProvider>();
    final settings = context.watch<SettingsProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final activeTimetable = timetable.activeTimetable;
    final isHoliday = attendance.isHolidayOnDate(_selectedDate, settings.settings);
    final holidayTitle = attendance.getHolidayTitle(_selectedDate, settings.settings);
    final isWeekly = settings.weeklyHolidays.contains(_selectedDate.weekday);

    final daySessions = activeTimetable != null
        ? timetable.getSessionsForDay(_selectedDate.weekday)
        : <ClassSession>[];

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Attendance',
              style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
            ),
            if (activeTimetable != null)
              Text(
                activeTimetable.name,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'sans-serif',
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // Past entries button
          IconButton(
            tooltip: 'View Past Entries & Mistakes',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PastEntriesScreen()),
              );
            },
          ),
          // Mark Day as Holiday
          IconButton(
            tooltip: isHoliday ? 'Unmark Holiday' : 'Mark as Holiday',
            icon: Icon(
              isHoliday ? Icons.beach_access : Icons.beach_access_outlined,
              color: isHoliday ? AppColors.holiday : null,
            ),
            onPressed: () => _showHolidayDialog(context, attendance, isHoliday, holidayTitle),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Navigator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Day',
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                isToday
                                    ? 'Today, '
                                    : (DateUtils.isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                        ? 'Yesterday, '
                                        : (DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))
                                            ? 'Tomorrow, '
                                            : '')),
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE').format(_selectedDate),
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.calendar_today_outlined, size: 16, color: primary),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Day',
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          // Scrollable Daily Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Holiday Notification Banner
                // "In the attendance section when scrolling through the days Notify the user that today is a holiday rather than just 'no classes today'."
                if (isHoliday) ...[
                  HolidayBanner(
                    holidayTitle: holidayTitle ?? 'Holiday',
                    isWeekly: isWeekly,
                    onToggleHoliday: () => _showHolidayDialog(context, attendance, isHoliday, holidayTitle),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Class List for this day
                if (daySessions.isEmpty) ...[
                  if (!isHoliday)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No classes scheduled for this day',
                              style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can add classes to your routine in the Timetable tab.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Classes Scheduled (${daySessions.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        isHoliday ? 'Holiday mode active' : 'Tap a status to mark',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Session Cards
                  ...daySessions.map((session) {
                    final record = attendance.getRecordForSession(
                      timetableId: activeTimetable?.id ?? '',
                      session: session,
                      date: _selectedDate,
                      defaultLateWeight: settings.lateAttendanceWeight,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSessionCard(
                        context,
                        session,
                        record,
                        attendance,
                        settings,
                        activeTimetable?.id ?? '',
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    ClassSession session,
    AttendanceRecord record,
    AttendanceProvider attendance,
    SettingsProvider settings,
    String timetableId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ClaudeCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _openDetailedEditDialog(context, session, record, attendance, settings, timetableId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject, Time, Room, and Points Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left color pill
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(session.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.timeFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (session.room.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 11)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              session.room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Points multiplier tag
              // "Add the ability to make a class count as multiple attendance points (1-5) in the attendance tab."
              InkWell(
                onTap: () => _openDetailedEditDialog(context, session, record, attendance, settings, timetableId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${record.points.toStringAsFixed(0)} pt${record.points > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendance Quick Action Buttons: Present, Late, Absent
          Row(
            children: [
              _buildQuickStatusButton(
                label: 'Present',
                isSelected: record.status == AttendanceStatus.present,
                color: AppColors.present,
                icon: Icons.check_circle_outline,
                onTap: () {
                  attendance.setAttendance(
                    timetableId: timetableId,
                    session: session,
                    date: _selectedDate,
                    status: AttendanceStatus.present,
                    points: record.points,
                    lateWeight: settings.lateAttendanceWeight,
                    note: record.note,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildQuickStatusButton(
                label: 'Late',
                isSelected: record.status == AttendanceStatus.late,
                color: AppColors.late,
                icon: Icons.access_time,
                onTap: () {
                  attendance.setAttendance(
                    timetableId: timetableId,
                    session: session,
                    date: _selectedDate,
                    status: AttendanceStatus.late,
                    points: record.points,
                    lateWeight: settings.lateAttendanceWeight,
                    note: record.note,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildQuickStatusButton(
                label: 'Absent',
                isSelected: record.status == AttendanceStatus.absent,
                color: AppColors.absent,
                icon: Icons.highlight_off,
                onTap: () {
                  // If tapping absent, prompt or log absent with reason option
                  attendance.setAttendance(
                    timetableId: timetableId,
                    session: session,
                    date: _selectedDate,
                    status: AttendanceStatus.absent,
                    points: record.points,
                    lateWeight: settings.lateAttendanceWeight,
                    absenceReason: record.absenceReason ?? AbsenceReason.personal,
                    note: record.note,
                  );
                },
              ),
            ],
          ),

          // Note & Absence Reason preview if recorded
          if (record.absenceReason != null || record.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (record.absenceReason != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.absent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.absenceReason!.label,
                        style: const TextStyle(fontSize: 10, color: AppColors.absent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (record.note.isNotEmpty)
                    Expanded(
                      child: Text(
                        'Note: "${record.note}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStatusButton({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailedEditDialog(
    BuildContext context,
    ClassSession session,
    AttendanceRecord record,
    AttendanceProvider attendance,
    SettingsProvider settings,
    String timetableId,
  ) {
    showDialog(
      context: context,
      builder: (_) => LogEditDialog(
        session: session,
        record: record,
        date: _selectedDate,
        defaultLateWeight: settings.lateAttendanceWeight,
        onSave: ({required status, required points, required lateWeight, absenceReason, note}) {
          attendance.setAttendance(
            timetableId: timetableId,
            session: session,
            date: _selectedDate,
            status: status,
            points: points,
            lateWeight: lateWeight,
            absenceReason: absenceReason,
            note: note,
          );
        },
      ),
    );
  }

  void _showHolidayDialog(
    BuildContext context,
    AttendanceProvider attendance,
    bool isHoliday,
    String? holidayTitle,
  ) {
    final titleController = TextEditingController(text: holidayTitle ?? '');
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isHoliday ? 'Edit or Remove Holiday' : 'Mark Date as Holiday',
          style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Holiday Title',
                hintText: 'e.g. Sports Day, College Fest, Sick Leave',
              ),
            ),
          ],
        ),
        actions: [
          if (isHoliday)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
              onPressed: () {
                attendance.toggleHoliday(_selectedDate);
                Navigator.of(ctx).pop();
              },
              child: const Text('Unmark Holiday'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              attendance.toggleHoliday(
                _selectedDate,
                title: titleController.text.trim().isEmpty ? 'Holiday' : titleController.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isHoliday ? 'Update' : 'Mark Holiday'),
          ),
        ],
      ),
    );
  }
}
