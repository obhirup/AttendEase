import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';
import '../../widgets/claude_badge.dart';
import 'log_edit_dialog.dart';

class PastEntriesScreen extends StatefulWidget {
  const PastEntriesScreen({super.key});

  @override
  State<PastEntriesScreen> createState() => _PastEntriesScreenState();
}

class _PastEntriesScreenState extends State<PastEntriesScreen> {
  bool _isCalendarView = false;
  String _selectedSubjectFilter = 'All';
  AttendanceStatus? _selectedStatusFilter;
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedCalendarDate;

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final timetable = context.watch<TimetableProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final allRecords = attendance.records.where((r) => r.isConducted).toList();
    // Sort descending by date
    allRecords.sort((a, b) => b.date.compareTo(a.date));

    // Filter by subject
    var filteredRecords = allRecords;
    if (_selectedSubjectFilter != 'All') {
      filteredRecords = filteredRecords.where((r) => r.subject == _selectedSubjectFilter).toList();
    }
    // Filter by status
    if (_selectedStatusFilter != null) {
      filteredRecords = filteredRecords.where((r) => r.status == _selectedStatusFilter).toList();
    }

    final uniqueSubjects = ['All', ...allRecords.map((r) => r.subject).toSet().toList()..sort()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Attendance Entries'),
        actions: [
          // Switch between List and Calendar View
          IconButton(
            tooltip: _isCalendarView ? 'Switch to List View' : 'Switch to Calendar View',
            icon: Icon(_isCalendarView ? Icons.view_list_rounded : Icons.calendar_month_rounded),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // View mode chip
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isCalendarView ? Icons.calendar_month : Icons.list, size: 16),
                        const SizedBox(width: 4),
                        Text(_isCalendarView ? 'Calendar' : 'List'),
                      ],
                    ),
                    selected: true,
                    selectedColor: primary.withOpacity(0.2),
                    onSelected: (_) {
                      setState(() => _isCalendarView = !_isCalendarView);
                    },
                  ),
                  const SizedBox(width: 8),

                  // Subject dropdown filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: uniqueSubjects.contains(_selectedSubjectFilter) ? _selectedSubjectFilter : 'All',
                        isDense: true,
                        dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        items: uniqueSubjects.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSubjectFilter = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status filter chips
                  ...[
                    AttendanceStatus.present,
                    AttendanceStatus.late,
                    AttendanceStatus.absent,
                  ].map((st) {
                    final isSel = _selectedStatusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(st.label),
                        selected: isSel,
                        selectedColor: primary.withOpacity(0.2),
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter = selected ? st : null;
                          });
                        },
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Content: Calendar or List View
          Expanded(
            child: _isCalendarView
                ? _buildCalendarView(context, attendance, timetable, settings)
                : _buildListView(context, filteredRecords, attendance, timetable, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<AttendanceRecord> records,
    AttendanceProvider attendance,
    TimetableProvider timetable,
    SettingsProvider settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off, size: 54, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(height: 12),
              const Text(
                'No past entries found',
                style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Attendance records will show up here as you log classes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final rec = records[idx];
        final dt = DateTime.tryParse(rec.date) ?? DateTime.now();

        return ClaudeCard(
          padding: const EdgeInsets.all(14),
          onTap: () => _openEditDialog(context, rec, attendance, timetable, settings),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge Column
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(dt).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    Text(
                      DateFormat('d').format(dt),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      DateFormat('EEE').format(dt),
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Subject & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rec.subject,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ClaudeBadge.fromStatus(rec.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${rec.points.toStringAsFixed(0)} pt${rec.points > 1 ? "s" : ""} • Earned: ${rec.earnedPoints.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (rec.absenceReason != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.absent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rec.absenceReason!.label,
                              style: const TextStyle(fontSize: 10, color: AppColors.absent, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    if (rec.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '"${rec.note}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    AttendanceProvider attendance,
    TimetableProvider timetable,
    SettingsProvider settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday; // 1=Mon, 7=Sun

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_calendarMonth),
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day of week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 weeks * 7
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, idx) {
              final dayOffset = idx - (firstDayOfWeek - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }
              final dayNumber = dayOffset + 1;
              final dayDate = DateTime(_calendarMonth.year, _calendarMonth.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);

              final dayRecords = attendance.records.where((r) => r.date == dateStr && r.isConducted).toList();
              final isHoliday = attendance.isHolidayOnDate(dayDate, settings.settings);

              final isSelected = _selectedCalendarDate != null &&
                  _selectedCalendarDate!.year == dayDate.year &&
                  _selectedCalendarDate!.month == dayDate.month &&
                  _selectedCalendarDate!.day == dayDate.day;

              // Compute color indicators
              Color? indicatorColor;
              if (isHoliday) {
                indicatorColor = AppColors.holiday;
              } else if (dayRecords.isNotEmpty) {
                if (dayRecords.every((r) => r.status == AttendanceStatus.present)) {
                  indicatorColor = AppColors.present;
                } else if (dayRecords.any((r) => r.status == AttendanceStatus.absent)) {
                  indicatorColor = AppColors.absent;
                } else if (dayRecords.any((r) => r.status == AttendanceStatus.late)) {
                  indicatorColor = AppColors.late;
                }
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCalendarDate = dayDate;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withOpacity(0.2)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      if (indicatorColor != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Selected Day Log Entries
          if (_selectedCalendarDate != null) ...[
            Text(
              'Logs for ${DateFormat('EEE, MMM d, yyyy').format(_selectedCalendarDate!)}',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectedDateLogs(context, _selectedCalendarDate!, attendance, timetable, settings),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDateLogs(
    BuildContext context,
    DateTime date,
    AttendanceProvider attendance,
    TimetableProvider timetable,
    SettingsProvider settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayRecords = attendance.records.where((r) => r.date == dateStr).toList();

    if (dayRecords.isEmpty) {
      return Text(
        'No logs recorded for this day.',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      );
    }

    return Column(
      children: dayRecords.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClaudeCard(
            padding: const EdgeInsets.all(12),
            onTap: () => _openEditDialog(context, rec, attendance, timetable, settings),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.subject,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Points: ${rec.points.toStringAsFixed(0)} • Earned: ${rec.earnedPoints.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ClaudeBadge.fromStatus(rec.status),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, size: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openEditDialog(
    BuildContext context,
    AttendanceRecord rec,
    AttendanceProvider attendance,
    TimetableProvider timetable,
    SettingsProvider settings,
  ) {
    final dt = DateTime.tryParse(rec.date) ?? DateTime.now();
    final daySessions = timetable.getSessionsForDay(dt.weekday);
    final session = daySessions.firstWhere(
      (s) => s.id == rec.classSessionId,
      orElse: () => ClassSession(
        id: rec.classSessionId,
        subject: rec.subject,
        dayOfWeek: dt.weekday,
        startHour: 9,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        defaultPoints: rec.points,
      ),
    );

    showDialog(
      context: context,
      builder: (_) => LogEditDialog(
        session: session,
        record: rec,
        date: dt,
        defaultLateWeight: settings.lateAttendanceWeight,
        onSave: ({required status, required points, required lateWeight, absenceReason, note}) {
          attendance.updateExistingRecord(
            rec.copyWith(
              status: status,
              points: points,
              lateWeight: lateWeight,
              absenceReason: absenceReason,
              clearAbsenceReason: status != AttendanceStatus.absent,
              note: note ?? rec.note,
            ),
          );
        },
      ),
    );
  }
}
