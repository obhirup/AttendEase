import 'package:flutter/material.dart';
import '../providers/calculator_provider.dart';
import '../theme/app_colors.dart';

class TaxRateDialog extends StatefulWidget {
  final CalculatorProvider provider;

  const TaxRateDialog({super.key, required this.provider});

  static Future<void> show(BuildContext context, CalculatorProvider provider) {
    return showDialog(
      context: context,
      builder: (_) => TaxRateDialog(provider: provider),
    );
  }

  @override
  State<TaxRateDialog> createState() => _TaxRateDialogState();
}

class _TaxRateDialogState extends State<TaxRateDialog> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.taxRate.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveRate(double rate) {
    if (rate >= 0 && rate <= 100) {
      widget.provider.setTaxRate(rate);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = 'Rate must be between 0% and 100%';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.percent, color: primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Tax Rate Settings',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set the stored tax percentage used for TAX+ (price with tax) and TAX- (price without tax) calculations.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Custom Input
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tax Percentage (%)',
              suffixText: '%',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Common Presets
          Text(
            'Quick Presets:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [5.0, 10.0, 12.0, 18.0, 28.0].map((rate) {
              final isCurrent = widget.provider.taxRate == rate;
              return ActionChip(
                label: Text('$rate%'),
                backgroundColor: isCurrent ? primary.withOpacity(0.2) : null,
                side: BorderSide(
                  color: isCurrent ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                onPressed: () {
                  _controller.text = rate.toString();
                  setState(() => _error = null);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Casio Shortcut: On MJ-120D, long-press the "%" key on the keypad to program the tax rate directly.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final rate = double.tryParse(_controller.text.trim());
            if (rate != null) {
              _saveRate(rate);
            } else {
              setState(() => _error = 'Invalid number');
            }
          },
          child: const Text('Save Rate'),
        ),
      ],
    );
  }
}
