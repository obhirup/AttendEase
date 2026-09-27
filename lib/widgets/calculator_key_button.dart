import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum KeyCategory {
  number,
  operator,
  action,
  memory,
  tax,
  review,
  clear,
}

class CalculatorKeyButton extends StatelessWidget {
  final String label;
  final String? subLabel;
  final IconData? icon;
  final KeyCategory category;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int flex;
  final bool isHighlighted;

  const CalculatorKeyButton({
    super.key,
    required this.label,
    this.subLabel,
    this.icon,
    this.category = KeyCategory.number,
    required this.onTap,
    this.onLongPress,
    this.flex = 1,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    Color bg;
    Color border;
    Color textColor;
    double fontSize = 20;
    FontWeight fontWeight = FontWeight.w600;

    switch (category) {
      case KeyCategory.number:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        fontSize = 22;
        fontWeight = FontWeight.w700;
        break;

      case KeyCategory.operator:
        bg = isHighlighted
            ? primary
            : (isDark ? primary.withOpacity(0.22) : primary.withOpacity(0.12));
        border = primary.withOpacity(0.4);
        textColor = isHighlighted
            ? Colors.white
            : (isDark ? primary.withOpacity(0.95) : primary);
        fontSize = 24;
        fontWeight = FontWeight.w700;
        break;

      case KeyCategory.action:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        fontSize = 18;
        break;

      case KeyCategory.memory:
        bg = isDark
            ? AppColors.skyBlue.withOpacity(0.16)
            : AppColors.skyBlue.withOpacity(0.10);
        border = AppColors.skyBlue.withOpacity(0.3);
        textColor = isDark ? AppColors.skyBlue : const Color(0xFF0284C7);
        fontSize = 15;
        fontWeight = FontWeight.w700;
        break;

      case KeyCategory.tax:
        bg = isDark
            ? AppColors.pastelRed.withOpacity(0.16)
            : AppColors.pastelRed.withOpacity(0.10);
        border = AppColors.pastelRed.withOpacity(0.3);
        textColor = isDark ? AppColors.pastelRed : const Color(0xFFDC2626);
        fontSize = 14;
        fontWeight = FontWeight.w700;
        break;

      case KeyCategory.review:
        bg = isDark
            ? AppColors.irisPastel.withOpacity(0.16)
            : AppColors.irisPastel.withOpacity(0.10);
        border = AppColors.irisPastel.withOpacity(0.3);
        textColor = isDark ? AppColors.irisPastel : const Color(0xFF7C3AED);
        fontSize = 11;
        fontWeight = FontWeight.w700;
        break;

      case KeyCategory.clear:
        bg = isDark
            ? AppColors.amber.withOpacity(0.16)
            : AppColors.amber.withOpacity(0.12);
        border = AppColors.amber.withOpacity(0.35);
        textColor = isDark ? AppColors.amber : const Color(0xFFD97706);
        fontSize = 18;
        fontWeight = FontWeight.w700;
        break;
    }

    if (isHighlighted && category != KeyCategory.operator) {
      bg = primary;
      textColor = Colors.white;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            onLongPress: onLongPress != null
                ? () {
                    HapticFeedback.mediumImpact();
                    onLongPress!();
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Icon(icon, size: fontSize, color: textColor)
                    else
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    if (subLabel != null)
                      Text(
                        subLabel!,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: textColor.withOpacity(0.7),
                          letterSpacing: 0.1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
