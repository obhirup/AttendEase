import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';
import '../../widgets/claude_badge.dart';
import '../../widgets/attendance_progress_ring.dart';

class CombinedDashboardScreen extends StatefulWidget {
  const CombinedDashboardScreen({super.key});

  @override
  State<CombinedDashboardScreen> createState() => _CombinedDashboardScreenState();
}

class _CombinedDashboardScreenState extends State<CombinedDashboardScreen> {
  String? _selectedTimetableId;

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final timetable = context.watch<TimetableProvider>();
    final settings = context.watch<SettingsProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final allTimetables = timetable.timetables;
    final activeTimetable = timetable.activeTimetable;

    // Resolve current selected routine
    String? currentSelectedId = _selectedTimetableId;
    if (currentSelectedId != 'all' &&
        currentSelectedId != null &&
        !allTimetables.any((t) => t.id == currentSelectedId)) {
      currentSelectedId = null;
    }
    currentSelectedId ??= activeTimetable?.id ?? (allTimetables.isNotEmpty ? allTimetables.first.id : 'all');

    final effectiveFilterId = currentSelectedId == 'all' ? null : currentSelectedId;
    final stats = attendance.calculateStatistics(
      settings: settings.settings,
      filterTimetableId: effectiveFilterId,
    );

    final minReq = settings.minimumAttendance;
    final targetGoal = settings.targetAttendance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard & Statistics',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 0. Routine Selector Dropdown matching the curved theme
          if (allTimetables.isNotEmpty) ...[
            Container(
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
                  value: currentSelectedId,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  items: [
                    if (allTimetables.length > 1)
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Added Routines (Combined)'),
                      ),
                    ...allTimetables.map((tt) {
                      return DropdownMenuItem(
                        value: tt.id,
                        child: Text(
                          '${tt.name}${tt.isArchived ? " (Archived)" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (id) {
                    if (id != null) {
                      setState(() {
                        _selectedTimetableId = id;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Hero Overall Attendance Card
          ClaudeCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (stats.isBelowPar)
                      ClaudeBadge.alert(text: 'Below Minimum Par')
                    else
                      const ClaudeBadge(
                        label: 'Good Standing',
                        color: AppColors.present,
                        icon: Icons.verified_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Large Progress Ring
                AttendanceProgressRing(
                  percentage: stats.overallPercentage,
                  minimumRequired: minReq,
                  size: 150,
                  strokeWidth: 12,
                  subtitle: '${stats.totalAttendedPoints.toStringAsFixed(1)} / ${stats.totalConductedPoints.toStringAsFixed(0)} pts',
                ),
                const SizedBox(height: 16),

                // Red Alert Banner if Below Par
                if (stats.isBelowPar) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.alertRedBgDark : AppColors.alertRedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alertRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.alertRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Your attendance is currently below the required minimum of ${minReq.toStringAsFixed(0)}%.',
                            style: const TextStyle(
                              color: AppColors.alertRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Quick Stat Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, 'Conducted', '${stats.totalConductedClasses}', Icons.class_outlined, isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    _buildStatItem(context, 'Present', '${stats.totalPresent}', Icons.check_circle_outline, AppColors.present),
                    _buildStatItem(context, 'Late', '${stats.totalLate}', Icons.access_time, AppColors.late),
                    _buildStatItem(context, 'Absent', '${stats.totalAbsent}', Icons.highlight_off, AppColors.absent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Bunk / Attendance Predictor Card (Toggleable through settings)
          if (settings.showBunkPredictor && stats.totalConductedPoints > 0) ...[
            _buildBunkPredictorCard(context, stats, minReq, targetGoal, isDark, primary),
            const SizedBox(height: 16),
          ],

          // 3. Target Attendance Goal Progress Card
          if (stats.totalConductedPoints > 0) ...[
            _buildTargetGoalCard(context, stats, targetGoal, isDark, primary),
            const SizedBox(height: 20),
          ],

          // 4. Per-Subject Breakdown Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subject Breakdown',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${stats.subjectBreakdown.length} Subjects',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (stats.subjectBreakdown.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No class records logged yet. Tick your classes in Attendance!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ] else ...[
            ...stats.subjectBreakdown.map((subStat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSubjectCard(context, subStat, minReq, isDark, primary),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBunkPredictorCard(
    BuildContext context,
    AttendanceStatsSummary stats,
    double minReq,
    double targetGoal,
    bool isDark,
    Color primary,
  ) {
    final bool isMeetingGoal = stats.overallPercentage >= targetGoal;
    final bool isMeetingMin = !stats.isBelowPar; // overall percentage >= minReq
    final bool isMeetingGoals = isMeetingGoal || isMeetingMin;

    final int skipCount = stats.overallSafeSkips ?? 0;
    final int neededCount = stats.overallNeededToRecover ?? 0;

    // If the user is meeting attendance goals or requirements, DO NOT show recovery path required!
    if (isMeetingGoals) {
      final bool hasSkips = skipCount > 0;
      return ClaudeCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.present.withOpacity(0.3),
        backgroundColor: isDark ? const Color(0xFF13281E) : const Color(0xFFF0FDF4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.beach_access_rounded,
                  color: AppColors.present,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasSkips ? 'Bunk / Skip Safe Zone' : 'Attendance On Track',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.present,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasSkips) ...[
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'You can safely skip/miss '),
                    TextSpan(
                      text: '$skipCount class${skipCount > 1 ? "es" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present),
                    ),
                    TextSpan(text: ' and still stay at or above your minimum requirement of ${minReq.toStringAsFixed(0)}%.'),
                  ],
                ),
              ),
            ] else ...[
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'You are currently meeting your attendance requirement ('),
                    TextSpan(
                      text: '${stats.overallPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present),
                    ),
                    TextSpan(text: '). Any unexcused absence will lower your attendance below par (${minReq.toStringAsFixed(0)}%).'),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Only when below par (and not meeting goals) do we show the recovery path
    return ClaudeCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.alertRed.withOpacity(0.3),
      backgroundColor: isDark ? const Color(0xFF2E1518) : const Color(0xFFFFF1F2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.alertRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Recovery Path Required',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.alertRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'To recover to '),
                TextSpan(
                  text: '${minReq.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: ', you must attend the next '),
                TextSpan(
                  text: '$neededCount consecutive class${neededCount > 1 ? "es" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.alertRed),
                ),
                const TextSpan(text: ' without absence.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetGoalCard(
    BuildContext context,
    AttendanceStatsSummary stats,
    double targetGoal,
    bool isDark,
    Color primary,
  ) {
    final double currentPct = stats.overallPercentage;
    final bool goalAchieved = currentPct >= targetGoal;
    final int neededForGoal = stats.overallNeededForGoal ?? 0;
    final int safeSkipsForGoal = stats.overallSafeSkipsForGoal ?? 0;

    return ClaudeCard(
      padding: const EdgeInsets.all(16),
      borderColor: goalAchieved ? AppColors.present.withOpacity(0.3) : primary.withOpacity(0.3),
      backgroundColor: isDark
          ? (goalAchieved ? const Color(0xFF13281E) : AppColors.darkSurface)
          : (goalAchieved ? const Color(0xFFF0FDF4) : AppColors.lightSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      goalAchieved ? Icons.military_tech_rounded : Icons.flag_rounded,
                      size: 20,
                      color: goalAchieved ? AppColors.present : primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target Attendance Goal',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: goalAchieved ? AppColors.present : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (goalAchieved ? AppColors.present : primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (goalAchieved ? AppColors.present : primary).withOpacity(0.3)),
                ),
                child: Text(
                  'Goal: ${targetGoal.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: goalAchieved ? AppColors.present : primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linear progress towards target
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentPct / targetGoal).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalAchieved ? AppColors.present : primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (goalAchieved) ...[
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: '🎯 Goal achieved! You are at '),
                  TextSpan(
                    text: '${currentPct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present),
                  ),
                  const TextSpan(text: '. You have a buffer of '),
                  TextSpan(
                    text: '$safeSkipsForGoal safe skip${safeSkipsForGoal != 1 ? "s" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present),
                  ),
                  TextSpan(text: ' before falling below your ${targetGoal.toStringAsFixed(0)}% goal.'),
                ],
              ),
            ),
          ] else ...[
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'To reach your target goal of '),
                  TextSpan(
                    text: '${targetGoal.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.w800, color: primary),
                  ),
                  const TextSpan(text: ', you must attend the next '),
                  TextSpan(
                    text: '$neededForGoal consecutive class${neededForGoal > 1 ? "es" : ""}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: primary),
                  ),
                  const TextSpan(text: ' without absence.'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    SubjectAttendanceStats stat,
    double minReq,
    bool isDark,
    Color primary,
  ) {
    final isBelow = stat.isBelowPar;

    return ClaudeCard(
      padding: const EdgeInsets.all(16),
      borderColor: isBelow ? AppColors.alertRed.withOpacity(0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.subject,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stat.attendedPoints.toStringAsFixed(1)} of ${stat.conductedPoints.toStringAsFixed(0)} points earned',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage Badge (Red if below par!)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isBelow
                      ? AppColors.alertRed.withOpacity(0.15)
                      : primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBelow ? AppColors.alertRed : primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${stat.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isBelow ? AppColors.alertRed : primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBelow ? AppColors.alertRed : (stat.percentage >= 85 ? AppColors.present : primary),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Count details & Bunk status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'P: ${stat.presentCount} • L: ${stat.lateCount} • A: ${stat.absentCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.isBelowPar
                      ? 'Need ${stat.classesNeededToRecover ?? 1} for par'
                      : (stat.isBelowGoal
                          ? 'Need ${stat.classesNeededForGoal ?? 1} for goal'
                          : 'Can skip ${stat.safeSkips ?? 0}'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: stat.isBelowPar
                        ? AppColors.alertRed
                        : (stat.isBelowGoal ? primary : AppColors.present),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
