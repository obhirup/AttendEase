import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timetable_provider.dart';
import '../../models/timetable.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';

class ArchiveTimetablesDialog extends StatelessWidget {
  const ArchiveTimetablesDialog({super.key});

  void _confirmDelete(BuildContext context, TimetableProvider timetable, Timetable tt) {
    showDialog(
      context: context,
      builder: (delCtx) => AlertDialog(
        title: const Text(
          'Delete Routine',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Permanently delete "${tt.name}" and all its classes? Historical attendance records will remain preserved in logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(delCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(delCtx).pop();
              await timetable.deleteTimetable(tt.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetable = context.watch<TimetableProvider>();
    final active = timetable.activeTimetables;
    final archived = timetable.archivedTimetables;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Manage Added Schedules',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Switch active routines, archive past semesters, or delete routines.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  // 1. Active Routines Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Routines (${active.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (active.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No active routines found',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...active.map((tt) {
                      final isCurrentActive = timetable.activeTimetable?.id == tt.id;
                      final dateStr = DateFormat('MMM yyyy').format(tt.createdAt);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClaudeCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          borderColor: isCurrentActive ? primary.withOpacity(0.4) : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tt.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                        ),
                                        if (isCurrentActive) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.present.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Active',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.present,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tt.sessions.length} classes • Created $dateStr',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isCurrentActive)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      ),
                                      child: const Text('Select', style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        timetable.setActiveTimetable(tt.id);
                                      },
                                    ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Archive Routine',
                                    icon: const Icon(Icons.archive_outlined, size: 18),
                                    onPressed: () {
                                      timetable.archiveTimetable(tt.id);
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete Routine',
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.alertRed),
                                    onPressed: () => _confirmDelete(context, timetable, tt),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 2. Archived Routines Section
                  Text(
                    'Archived Semesters (${archived.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  if (archived.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No archived routines',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...archived.map((tt) {
                      final dateStr = DateFormat('MMM yyyy').format(tt.createdAt);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClaudeCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tt.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tt.sessions.length} classes • Created $dateStr',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    ),
                                    icon: const Icon(Icons.unarchive_outlined, size: 16),
                                    label: const Text('Restore', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      timetable.unarchiveTimetable(tt.id);
                                    },
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete Routine',
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.alertRed),
                                    onPressed: () => _confirmDelete(context, timetable, tt),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
