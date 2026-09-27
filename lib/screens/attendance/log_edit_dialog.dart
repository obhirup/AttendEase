import 'package:flutter/material.dart';
import '../../models/class_session.dart';
import '../../models/attendance_record.dart';
import '../../models/absence_reason.dart';
import '../../theme/app_colors.dart';

class LogEditDialog extends StatefulWidget {
  final ClassSession session;
  final AttendanceRecord record;
  final DateTime date;
  final double defaultLateWeight;
  final Function({
    required AttendanceStatus status,
    required double points,
    required double lateWeight,
    AbsenceReason? absenceReason,
    String? note,
  }) onSave;

  const LogEditDialog({
    super.key,
    required this.session,
    required this.record,
    required this.date,
    required this.defaultLateWeight,
    required this.onSave,
  });

  @override
  State<LogEditDialog> createState() => _LogEditDialogState();
}

class _LogEditDialogState extends State<LogEditDialog> {
  late AttendanceStatus _status;
  late double _points;
  late double _lateWeight;
  AbsenceReason? _absenceReason;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _points = widget.record.points;
    _lateWeight = widget.record.lateWeight;
    _absenceReason = widget.record.absenceReason;
    _noteController = TextEditingController(text: widget.record.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Title & Timing
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.subject,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.session.timeFormatted} • ${widget.session.room.isNotEmpty ? widget.session.room : "No room"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Attendance Status Selection
            const Text(
              'Attendance Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusOption(AttendanceStatus.present, 'Present', Icons.check_circle_outline, AppColors.present),
                _buildStatusOption(AttendanceStatus.late, 'Late (${_lateWeight.toStringAsFixed(1)}x)', Icons.access_time, AppColors.late),
                _buildStatusOption(AttendanceStatus.absent, 'Absent', Icons.highlight_off, AppColors.absent),
                _buildStatusOption(AttendanceStatus.notMarked, 'Unmarked', Icons.radio_button_unchecked, AppColors.lightTextMuted),
              ],
            ),
            const SizedBox(height: 20),

            // Attendance Points Multiplier (1-5 points)
            // "Add the ability to make a class count as multiple attendance points (1-5) in the attendance tab."
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Points',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Count this session as 1 to 5 credits/points',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_points.toStringAsFixed(0)} pt${_points > 1 ? "s" : ""}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: primary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [1.0, 2.0, 3.0, 4.0, 5.0].map((pt) {
                final isSelected = _points == pt;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Center(
                        child: Text(
                          '${pt.toInt()}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primary,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _points = pt);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Absence Reason (Conditional: if Absent is selected)
            // "The ability to mark why an absence occurred (e.g., Medical Leave, Extracurricular/Official Duty, Personal)."
            if (_status == AttendanceStatus.absent) ...[
              const Text(
                'Absence Reason',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AbsenceReason.values.map((reason) {
                  final isSelected = _absenceReason == reason;
                  return FilterChip(
                    label: Text(reason.label),
                    selected: isSelected,
                    selectedColor: AppColors.absent.withOpacity(0.15),
                    checkmarkColor: AppColors.absent,
                    side: BorderSide(
                      color: isSelected ? AppColors.absent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.absent : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _absenceReason = selected ? reason : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Quick Notes / Tags
            // "Quick Notes/Tags: A small text field attached to each daily log. If a student marks 'Absent,' they can quickly jot down, 'Asked Sarah for notes.' If they mark 'Present,' they can write, 'Prof mentioned a pop quiz next week.'"
            const Text(
              'Quick Notes / Tag',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _status == AttendanceStatus.absent
                    ? 'e.g., Asked Sarah for notes...'
                    : 'e.g., Prof mentioned a pop quiz next week...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.onSave(
                      status: _status,
                      points: _points,
                      lateWeight: _lateWeight,
                      absenceReason: _status == AttendanceStatus.absent ? _absenceReason : null,
                      note: _noteController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(AttendanceStatus status, String label, IconData icon, Color color) {
    final isSelected = _status == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _status = status;
          if (status != AttendanceStatus.absent) {
            _absenceReason = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.18)
              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
