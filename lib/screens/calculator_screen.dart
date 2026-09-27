import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/calculator_config.dart';
import '../providers/calculator_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/selector_switches.dart';
import '../widgets/step_history_sheet.dart';
import '../widgets/tax_rate_dialog.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CalculatorModel>(
              value: provider.activeModel,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, color: primary),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            onChanged: (newModel) {
              if (newModel != null) {
                provider.switchModel(newModel);
              }
            },
            items: CalculatorModel.values.map((model) {
              return DropdownMenuItem<CalculatorModel>(
                value: model,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: model == provider.activeModel ? primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      model.displayName,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            ),
          ),
        ),
        actions: [
          // 150-Step Audit Tape
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: '150-Step History Tape',
            onPressed: () => StepHistorySheet.show(context, provider),
          ),

          // Tax Rate Settings
          IconButton(
            icon: const Icon(Icons.percent_outlined),
            tooltip: 'Tax Rate Settings',
            onPressed: () => TaxRateDialog.show(context, provider),
          ),

          // Theme & Accent Palette Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Theme & Accent Color',
            onSelected: (val) {
              if (val == 'theme_toggle') {
                final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
                provider.setThemeMode(nextMode);
              } else {
                final opt = AppColorOption.fromName(val);
                provider.setActiveColor(opt);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'theme_toggle',
                child: Row(
                  children: [
                    Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
                    const SizedBox(width: 8),
                    Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'ACCENT COLORS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              ...AppColorOption.values.map((opt) {
                final isSelected = opt == provider.activeColor;
                return PopupMenuItem(
                  value: opt.name,
                  child: Row(
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
                      Text(opt.label),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: primary),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              // Selector switches for Rounding (CUT/UP/5/4) and Decimal (F/4/3/2/1/0/ADD2)
              SelectorSwitches(
                currentRounding: provider.roundingMode,
                currentDecimal: provider.decimalSetting,
                onRoundingChanged: provider.setRoundingMode,
                onDecimalChanged: provider.setDecimalSetting,
              ),

              const SizedBox(height: 10),

              // 12-Digit Display
              CalculatorDisplay(
                displayValue: provider.displayValue,
                pendingOperator: provider.pendingOperator,
                hasMemory: provider.hasMemory,
                hasGrandTotal: provider.hasGrandTotal,
                isConstantActive: provider.isConstantActive,
                isReviewMode: provider.isReviewMode,
                currentReviewIndex: provider.currentReviewIndex,
                totalSteps: provider.totalSteps,
                currentStep: provider.currentStep,
                isCorrectMode: provider.isCorrectMode,
                isTaxRateSetMode: provider.isTaxRateSetMode,
                taxRate: provider.taxRate,
                isError: provider.isError,
                errorMessage: provider.errorMessage,
                isAutoReviewing: provider.isAutoReviewing,
                onHistoryTap: () => StepHistorySheet.show(context, provider),
              ),

              const SizedBox(height: 10),

              // Model banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      provider.config.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.config.hasTaxKeys ? 'TAX / MU / 150-STEP' : 'MU / 150-STEP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Keypad (automatically adapts based on MJ-120D vs MJ-12D)
              Expanded(
                child: SingleChildScrollView(
                  child: CalculatorKeypad(provider: provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
