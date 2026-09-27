import 'package:flutter/material.dart';
import '../models/calculator_enums.dart';
import '../theme/app_colors.dart';

class SelectorSwitches extends StatelessWidget {
  final RoundingMode currentRounding;
  final DecimalSetting currentDecimal;
  final ValueChanged<RoundingMode> onRoundingChanged;
  final ValueChanged<DecimalSetting> onDecimalChanged;

  const SelectorSwitches({
    super.key,
    required this.currentRounding,
    required this.currentDecimal,
    required this.onRoundingChanged,
    required this.onDecimalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rounding Mode Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUNDING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: RoundingMode.values.map((mode) {
                  final isSelected = mode == currentRounding;
                  return InkWell(
                    onTap: () => onRoundingChanged(mode),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? primary : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 28,
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const Spacer(),
          // Decimal Places Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DECIMAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: DecimalSetting.values.map((setting) {
                    final isSelected = setting == currentDecimal;
                    return InkWell(
                      onTap: () => onDecimalChanged(setting),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          setting.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? primary
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
