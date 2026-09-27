import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/calculator_provider.dart';
import '../theme/app_colors.dart';
import 'claude_badge.dart';

class StepHistorySheet extends StatelessWidget {
  final CalculatorProvider provider;

  const StepHistorySheet({
    super.key,
    required this.provider,
  });

  static void show(BuildContext context, CalculatorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StepHistorySheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final steps = provider.steps;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '150-Step Audit Tape',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${steps.length} of ${provider.config.maxSteps} steps recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (steps.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Calculation Tape',
                    onPressed: () {
                      final buffer = StringBuffer();
                      buffer.writeln('${provider.config.name} Calculation Tape:');
                      for (final s in steps) {
                        buffer.writeln('Step ${s.stepNumber.toString().padLeft(2, '0')}: ${s.operator} ${s.inputDisplay} = ${s.resultDisplay}');
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calculation tape copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of Steps
          Expanded(
            child: steps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No steps recorded yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Perform calculations to log up to 150 steps',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: steps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final step = steps[index];
                      final isCurrentReview = provider.isReviewMode && provider.currentReviewIndex == index;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentReview
                              ? primary.withOpacity(0.12)
                              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentReview
                                ? primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isCurrentReview ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Step Number
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Text(
                                '#${step.stepNumber.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Operator badge
                            if (step.operator.isNotEmpty)
                              ClaudeBadge(
                                label: step.operator,
                                color: primary,
                                fontSize: 11,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              ),
                            const SizedBox(width: 8),

                            // Input value
                            Text(
                              step.inputDisplay,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),

                            const Spacer(),

                            // Result
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '= ${step.resultDisplay}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                                if (step.isConstant)
                                  const Text(
                                    'Constant (K)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.irisPastel,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 8),

                            // Actions
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              onSelected: (val) {
                                if (val == 'jump') {
                                  provider.jumpToStep(index);
                                  Navigator.of(context).pop();
                                } else if (val == 'correct') {
                                  provider.jumpToStep(index);
                                  provider.startCorrect();
                                  Navigator.of(context).pop();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'jump',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16),
                                      SizedBox(width: 8),
                                      Text('Jump & Review'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'correct',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: AppColors.amber),
                                      SizedBox(width: 8),
                                      Text('Correct & Recalculate'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
