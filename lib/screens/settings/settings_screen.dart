import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/claude_card.dart';
import 'backup_restore_dialog.dart';
import '../timetable/archive_timetables_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Appearance & Theme (Dark Mode & Colors)
          _buildSectionHeader(context, 'Appearance & Theme', Icons.palette_outlined),
          const SizedBox(height: 8),
          ClaudeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dark Mode Switcher: Full width layout preventing any screen overflow
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose Light, Dark, or System appearance',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: primary.withOpacity(0.18),
                      selectedForegroundColor: primary,
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16), label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16), label: Text('Dark')),
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 16), label: Text('Auto')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      settings.setThemeMode(newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Color Scheme Palette
                // "change the iris purple name to Iris Pastel and use #8764B8 as its colour"
                // "remove the teal option and add a Pastel red instead"
                // "have the accent color options have a thin border of the same color as mentioned in the option"
                const Text(
                  'Accent Color',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your preferred accent theme',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppColorOption.values.map((opt) {
                    final isSelected = settings.activeColor == opt;
                    return InkWell(
                      onTap: () => settings.setActiveColor(opt),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? opt.color.withOpacity(0.18)
                              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: opt.color,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? opt.color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Weekly Holidays Configuration
          // "allow the user to natively mark other days as weekly holidays (through a settings page)"
          // "allow the user to unmark sunday as a weekly holiday"
          _buildSectionHeader(context, 'Weekly Holidays', Icons.weekend_outlined),
          const SizedBox(height: 8),
          ClaudeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure Weekly Off Days',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select which days count as recurring weekly holidays. You can unmark Sunday or mark any other days (Saturday, Friday, etc.).',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    MapEntry(1, 'Mon'),
                    MapEntry(2, 'Tue'),
                    MapEntry(3, 'Wed'),
                    MapEntry(4, 'Thu'),
                    MapEntry(5, 'Fri'),
                    MapEntry(6, 'Sat'),
                    MapEntry(7, 'Sun'),
                  ].map((entry) {
                    final isHoliday = settings.weeklyHolidays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: isHoliday,
                      showCheckmark: false,
                      selectedColor: primary.withOpacity(0.2),
                      side: BorderSide(
                        color: isHoliday ? primary : (isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder),
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isHoliday ? FontWeight.w700 : FontWeight.w500,
                        color: isHoliday ? primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      onSelected: (_) {
                        settings.toggleWeeklyHoliday(entry.key);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Attendance Thresholds & Criteria
          _buildSectionHeader(context, 'Attendance Criteria & Goals', Icons.rule_folder_outlined),
          const SizedBox(height: 8),
          ClaudeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimum Attendance Slider
                // "Add the option through settings to add a minimum attendance slider and showcase with red attendance % rate that attendance is below par."
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Minimum Attendance Required',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${settings.minimumAttendance.toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.w800, color: primary, fontSize: 16),
                    ),
                  ],
                ),
                Slider(
                  value: settings.minimumAttendance,
                  min: 50.0,
                  max: 95.0,
                  divisions: 45,
                  label: '${settings.minimumAttendance.toStringAsFixed(0)}%',
                  onChanged: (val) => settings.setMinimumAttendance(val),
                ),
                Text(
                  'Falling below this rate will trigger bold red alerts across the dashboard and subject breakdown.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Target Attendance Goal Slider
                // "Add a feature to add a target attendance or an attendance goal %."
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Target Attendance Goal',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${settings.targetAttendance.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present, fontSize: 16),
                    ),
                  ],
                ),
                Slider(
                  value: settings.targetAttendance,
                  min: 60.0,
                  max: 100.0,
                  divisions: 40,
                  label: '${settings.targetAttendance.toStringAsFixed(0)}%',
                  onChanged: (val) => settings.setTargetAttendance(val),
                ),
                Text(
                  'Your personal aspiration goal shown on the dashboard progress tracker.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Late Attendance Weight
                // "Add the ability to mark a class as late which can count as 0.5 attendance (default value is same as normal aka 1, customisable in the settings panel)."
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Late Attendance Credit Weight',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Credit value when you mark a class as Late',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${settings.lateAttendanceWeight.toStringAsFixed(2)}x',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.late, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [0.25, 0.5, 0.75, 1.0].map((w) {
                    final isSel = settings.lateAttendanceWeight == w;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          labelPadding: EdgeInsets.zero,
                          label: Center(
                            child: Text(
                              '${w}x',
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                                color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.late,
                          side: BorderSide(
                            color: isSel ? AppColors.late : (isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder),
                            width: 1,
                          ),
                          onSelected: (val) {
                            if (val) settings.setLateAttendanceWeight(w);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Bunk / Skip Predictor Toggle
                // "Add a feature that predicts how many classes an individual can miss/skip and still maintain their minimum attendance % (toggleable through settings)."
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Bunk / Attendance Predictor',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Predicts how many classes you can safely skip or must attend to recover',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  value: settings.showBunkPredictor,
                  onChanged: (val) => settings.setShowBunkPredictor(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Notifications & Reminders
          _buildSectionHeader(context, 'Notifications & Reminders', Icons.notifications_active_outlined),
          const SizedBox(height: 8),
          ClaudeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Start Reminder
                // "Add a notification reminder that plays before the class starts, make it customisable as to when this notification plays (example at the same time as the class, 5 minutes early etc)."
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Class Start Reminders',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Notify before scheduled class start time',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  value: settings.enableClassReminder,
                  onChanged: (val) => settings.setClassReminder(
                    enabled: val,
                    leadMinutes: settings.classReminderLeadMinutes,
                  ),
                ),
                if (settings.enableClassReminder) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reminder Time:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          settings.classReminderLeadMinutes == 0
                              ? 'At class start'
                              : '${settings.classReminderLeadMinutes} mins before',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preset chips: "remove 10/15/45/60m early options from the class start reminders and keep the rest"
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 5, 30].map((m) {
                      final isSel = settings.classReminderLeadMinutes == m;
                      final label = m == 0 ? 'At start' : '${m}m early';
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(label),
                        selected: isSel,
                        selectedColor: primary,
                        side: BorderSide(
                          color: isSel ? primary : (isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder),
                          width: 1,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        onSelected: (val) {
                          if (val) {
                            settings.setClassReminder(
                              enabled: true,
                              leadMinutes: m,
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.24) : AppColors.lightBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: const Text('Custom minutes', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showExactMinutesDialog(context, settings),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                const SizedBox(height: 10),

                // Missed Log Reminder
                // "If user forgets to mark a class even after the time of the class is over send a notification reminding the user to mark the class (example: ' Did you attend Physics at 10:00 AM?')"
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Missed Attendance Prompt',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'e.g. "Did you attend Physics at 10:00 AM?" if left unmarked',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  value: settings.enableMissedClassReminder,
                  onChanged: (val) => settings.setMissedClassReminder(
                    enabled: val,
                    minutesAfter: settings.missedReminderMinutesAfter,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Pause on Holidays
                // "Integration with local public holidays so it automatically pauses reminders during breaks."
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Pause Reminders on Holidays & Breaks',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Automatically silences class reminders on weekly off days and public breaks',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  value: settings.pauseRemindersOnHolidays,
                  onChanged: (val) => settings.setPauseRemindersOnHolidays(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Data & Backup Management
          _buildSectionHeader(context, 'Data, Archives & Backups', Icons.storage_outlined),
          const SizedBox(height: 8),
          ClaudeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Local Backup & Restore
                // "Add the ability to create a local backup."
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.backup_outlined, color: primary),
                  title: const Text('Local Backup & Restore', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Export or import JSON backup of your attendance records', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const BackupRestoreDialog(),
                    );
                  },
                ),
                const Divider(),
                // Manage Added Schedules
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded, color: AppColors.amber),
                  title: const Text('Manage Added Schedules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('View, switch, archive, or delete added schedules while keeping historical logs', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ArchiveTimetablesDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showExactMinutesDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: '${settings.classReminderLeadMinutes}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Custom Reminder Time',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter how many minutes before class start time you want the notification to alert you (0 - 120 minutes):',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Minutes before class',
                  hintText: 'e.g. 20',
                  suffixText: 'mins',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val >= 0 && val <= 180) {
                  settings.setClassReminder(enabled: true, leadMinutes: val);
                  Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid number between 0 and 180 minutes')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
