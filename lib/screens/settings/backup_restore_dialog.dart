import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';

class BackupRestoreDialog extends StatefulWidget {
  final bool isRestoreMode;

  const BackupRestoreDialog({super.key, this.isRestoreMode = false});

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  late bool _isRestore;
  late TextEditingController _jsonController;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _isRestore = widget.isRestoreMode;
    _jsonController = TextEditingController();

    if (!_isRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateExport();
      });
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _generateExport() {
    final timetable = context.read<TimetableProvider>();
    final attendance = context.read<AttendanceProvider>();
    final settings = context.read<SettingsProvider>();

    final jsonString = BackupService.generateBackupJson(
      timetables: timetable.timetables,
      attendanceRecords: attendance.records,
      holidays: attendance.holidays,
      settings: settings.settings,
    );

    setState(() {
      _jsonController.text = jsonString;
    });
  }

  void _executeRestore() async {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please paste the backup JSON payload.');
      return;
    }

    try {
      final backup = BackupService.parseBackupJson(text);

      final timetable = context.read<TimetableProvider>();
      final attendance = context.read<AttendanceProvider>();
      final settings = context.read<SettingsProvider>();

      await timetable.replaceAll(backup.timetables);
      await attendance.replaceAll(records: backup.attendanceRecords, holidays: backup.holidays);
      await settings.updateSettings(backup.settings);

      setState(() {
        _errorMessage = null;
        _successMessage = 'Successfully restored ${backup.timetables.length} timetables, ${backup.attendanceRecords.length} attendance records, and ${backup.holidays.length} holidays!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid backup JSON data: $e';
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                Expanded(
                  child: Text(
                    _isRestore ? 'Restore Local Backup' : 'Create Local Backup',
                    style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700),
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
            const SizedBox(height: 8),

            // Mode toggle buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Export Backup'),
                  selected: !_isRestore,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isRestore = false;
                        _errorMessage = null;
                        _successMessage = null;
                      });
                      _generateExport();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Import / Restore'),
                  selected: _isRestore,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isRestore = true;
                        _jsonController.clear();
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              _isRestore
                  ? 'Paste your JSON backup code below to restore routines, historical attendance records, and configurations.'
                  : 'Copy and save this JSON backup locally. It contains all active/archived timetables, logs, and settings.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Messages
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.alertRed, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (_successMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.present.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.present.withOpacity(0.4)),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: AppColors.present, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Text field for JSON
            Expanded(
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                readOnly: !_isRestore,
                decoration: InputDecoration(
                  hintText: _isRestore ? 'Paste backup JSON here...' : '',
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!_isRestore) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy to Clipboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _jsonController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup JSON copied to clipboard!')),
                      );
                    },
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Restore Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _executeRestore,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
