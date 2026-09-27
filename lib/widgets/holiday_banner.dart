import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HolidayBanner extends StatelessWidget {
  final String holidayTitle;
  final bool isWeekly;
  final VoidCallback? onToggleHoliday;

  const HolidayBanner({
    super.key,
    required this.holidayTitle,
    this.isWeekly = false,
    this.onToggleHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E241E) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5A3E29) : const Color(0xFFFDBA74),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF452D1C) : const Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWeekly ? Icons.weekend_outlined : Icons.celebration_outlined,
              color: const Color(0xFFEA580C),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isWeekly ? 'WEEKLY HOLIDAY' : 'HOLIDAY NOTICE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  holidayTitle,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No attendance required. Class reminders are automatically paused.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleHoliday != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Toggle Holiday',
              icon: Icon(
                Icons.edit_calendar_outlined,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              onPressed: onToggleHoliday,
            ),
          ],
        ],
      ),
    );
  }
}
