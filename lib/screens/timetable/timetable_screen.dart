import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timetable_provider.dart';
import '../../models/class_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';
import 'add_edit_class_dialog.dart';
import 'add_edit_timetable_dialog.dart';
import 'archive_timetables_dialog.dart';
import 'timetable_calendar_view.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _dayTabController;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    // Default to today's weekday tab (1=Mon, 7=Sun -> 0..6 index)
    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    _dayTabController = TabController(length: 7, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetable = context.watch<TimetableProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final activeTt = timetable.activeTimetable;
    final allActive = timetable.activeTimetables;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Routine',
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 19,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            if (activeTt != null)
              Text(
                '${activeTt.name} (${activeTt.sessions.length} total classes)',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'sans-serif',
                  height: 1.2,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // View Calendar Button
          // "add a viewable calendar into the timetable section with all the classes mentioned in it"
          IconButton(
            tooltip: 'View Timetable Calendar',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimetableCalendarView()),
              );
            },
          ),
          // Manage Added Schedules (formerly Manage Archived Semesters)
          IconButton(
            tooltip: 'Manage Added Schedules',
            icon: const Icon(Icons.schedule_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ArchiveTimetablesDialog(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Routine Switcher / Selector Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activeTt?.id,
                            isExpanded: true,
                            dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            hint: const Text('Select a Routine'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            items: allActive.map((tt) {
                              return DropdownMenuItem(
                                value: tt.id,
                                child: Text(tt.name),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) timetable.setActiveTimetable(id);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Rename Active Timetable Button
                    if (activeTt != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'Rename Routine',
                        icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditTimetableDialog(
                              initialName: activeTt.name,
                              isRename: true,
                              onSave: (newName) {
                                timetable.renameTimetable(activeTt.id, newName);
                              },
                            ),
                          );
                        },
                      ),
                    const SizedBox(width: 4),
                    // Create New Timetable Button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Create New Routine',
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      color: primary,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditTimetableDialog(
                            onSave: (name) {
                              timetable.createTimetable(name);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Weekday Tab Bar
              TabBar(
                controller: _dayTabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: primary,
                labelColor: primary,
                unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: _dayNames.map((name) => Tab(text: name)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: activeTt == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 56,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Routine Created',
                      style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a routine to add your college classes and track daily attendance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Routine', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditTimetableDialog(
                            onSave: (name) {
                              timetable.createTimetable(name);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _dayTabController,
              children: List.generate(7, (idx) {
                final dayOfWeek = idx + 1; // 1 = Mon ... 7 = Sun
                final sessions = timetable.getSessionsForDay(dayOfWeek);

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No classes on ${_dayNames[idx]}',
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the "+" button below to schedule a class.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, sessionIdx) {
                    final session = sessions[sessionIdx];

                    return ClaudeCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(session.colorValue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                    fontSize: 14.5,
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
                                        fontSize: 11.5,
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
                                            fontSize: 11.5,
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
                          const SizedBox(width: 6),
                          // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${session.defaultPoints.toStringAsFixed(0)} pt${session.defaultPoints > 1 ? "s" : ""}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                          // Edit button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditClassDialog(
                                  existingSession: session,
                                  initialDayOfWeek: dayOfWeek,
                                  onSave: (updated) {
                                    timetable.updateClassSession(updated);
                                  },
                                ),
                              );
                            },
                          ),
                          // Delete button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.alertRed),
                            onPressed: () {
                              _confirmDeleteClass(context, timetable, session);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          final currentDayOfWeek = _dayTabController.index + 1;
          showDialog(
            context: context,
            builder: (_) => AddEditClassDialog(
              initialDayOfWeek: currentDayOfWeek,
              onSave: (session) {
                timetable.addClassSession(session);
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, TimetableProvider timetable, ClassSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class Session', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove "${session.subject}" from this routine?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, foregroundColor: Colors.white),
            onPressed: () {
              timetable.deleteClassSession(session.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
