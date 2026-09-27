import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../theme/app_colors.dart';

class ClaudeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ClaudeBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory ClaudeBadge.fromStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const ClaudeBadge(
          label: 'Present',
          color: AppColors.present,
          icon: Icons.check_circle_outline,
        );
      case AttendanceStatus.late:
        return const ClaudeBadge(
          label: 'Late',
          color: AppColors.late,
          icon: Icons.access_time,
        );
      case AttendanceStatus.absent:
        return const ClaudeBadge(
          label: 'Absent',
          color: AppColors.absent,
          icon: Icons.highlight_off,
        );
      case AttendanceStatus.notMarked:
        return const ClaudeBadge(
          label: 'Pending',
          color: AppColors.lightTextMuted,
          icon: Icons.radio_button_unchecked,
        );
    }
  }

  factory ClaudeBadge.alert({required String text}) {
    return ClaudeBadge(
      label: text,
      color: AppColors.alertRed,
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color.withOpacity(isDark ? 0.18 : 0.12);
    final border = color.withOpacity(0.35);
    final textCol = textColor ?? (isDark ? color.withOpacity(0.95) : color);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textCol),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textCol,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
