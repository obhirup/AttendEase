import 'package:flutter/material.dart';
import '../models/calculation_step.dart';
import '../theme/app_colors.dart';
import 'claude_badge.dart';

class CalculatorDisplay extends StatelessWidget {
  final String displayValue;
  final String? pendingOperator;
  final bool hasMemory;
  final bool hasGrandTotal;
  final bool isConstantActive;
  final bool isReviewMode;
  final int currentReviewIndex;
  final int totalSteps;
  final CalculationStep? currentStep;
  final bool isCorrectMode;
  final bool isTaxRateSetMode;
  final double taxRate;
  final bool isError;
  final String errorMessage;
  final bool isAutoReviewing;
  final VoidCallback? onHistoryTap;

  const CalculatorDisplay({
    super.key,
    required this.displayValue,
    this.pendingOperator,
    required this.hasMemory,
    required this.hasGrandTotal,
    required this.isConstantActive,
    required this.isReviewMode,
    required this.currentReviewIndex,
    required this.totalSteps,
    this.currentStep,
    required this.isCorrectMode,
    required this.isTaxRateSetMode,
    required this.taxRate,
    required this.isError,
    required this.errorMessage,
    required this.isAutoReviewing,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isCorrectMode
        ? AppColors.amber
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    // Format display string with commas if standard number
    final formattedMain = _formatDisplayString(displayValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: isCorrectMode ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Model & Status Indicators
          Row(
            children: [
              // 12-Digit Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '12-DIGIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Step Indicator Pill
              if (totalSteps > 0)
                InkWell(
                  onTap: onHistoryTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAutoReviewing ? Icons.play_arrow : Icons.format_list_numbered,
                          size: 11,
                          color: primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isReviewMode
                              ? 'STEP ${currentReviewIndex + 1}/$totalSteps'
                              : '$totalSteps STEPS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Active Casio Flags / Badges
              Wrap(
                spacing: 4,
                children: [
                  if (isCorrectMode)
                    const ClaudeBadge(
                      label: 'CRT',
                      color: AppColors.amber,
                      fontSize: 10,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  if (isReviewMode)
                    ClaudeBadge(
                      label: isAutoReviewing ? 'AUTO REV' : 'REV',
                      color: primary,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  if (hasMemory)
                    const ClaudeBadge(
                      label: 'M',
                      color: AppColors.emerald,
                      fontSize: 10,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  if (hasGrandTotal)
                    const ClaudeBadge(
                      label: 'GT',
                      color: AppColors.skyBlue,
                      fontSize: 10,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  if (isConstantActive)
                    const ClaudeBadge(
                      label: 'K',
                      color: AppColors.irisPastel,
                      fontSize: 10,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  if (isTaxRateSetMode)
                    const ClaudeBadge(
                      label: 'SET RATE',
                      color: AppColors.alertRed,
                      fontSize: 10,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Sub-Display: Step Info or Operation Context
          Container(
            height: 22,
            alignment: Alignment.centerRight,
            child: _buildSubDisplayText(isDark, primary),
          ),

          const SizedBox(height: 4),

          // Main LCD Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Pending Operator Indicator on left
              if (pendingOperator != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    pendingOperator!,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),

              // Main Number
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattedMain,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isError
                          ? AppColors.alertRed
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // CRT Mode Helper instruction
          if (isCorrectMode) ...[
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.edit_note, size: 14, color: AppColors.amber),
                SizedBox(width: 4),
                Text(
                  'Editing step. Enter new number & tap CORRECT to apply',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubDisplayText(bool isDark, Color primary) {
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    if (isTaxRateSetMode) {
      return Text(
        'Programming Tax Rate (Currently: $taxRate%)',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.alertRed,
        ),
      );
    }

    if (isReviewMode && currentStep != null) {
      final s = currentStep!;
      return Text(
        'Step ${s.stepNumber}: ${s.operator} ${s.inputDisplay}  ➔  Result: ${s.resultDisplay}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      );
    }

    if (pendingOperator != null) {
      return Text(
        'Operation: $pendingOperator',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      );
    }

    return Text(
      'Tax Rate: $taxRate%',
      style: TextStyle(
        fontSize: 11,
        color: textMuted,
      ),
    );
  }

  String _formatDisplayString(String val) {
    if (val.startsWith('E') || val.contains('e') || val.contains('E')) {
      return val;
    }

    // Split integer and decimal parts
    final parts = val.split('.');
    String intPart = parts[0];

    bool isNegative = false;
    if (intPart.startsWith('-')) {
      isNegative = true;
      intPart = intPart.substring(1);
    }

    // Format thousands separator
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    intPart = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');

    if (isNegative) {
      intPart = '-$intPart';
    }

    if (parts.length > 1) {
      return '$intPart.${parts[1]}';
    } else if (val.endsWith('.')) {
      return '$intPart.';
    }

    return intPart;
  }
}
