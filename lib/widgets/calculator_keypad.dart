import 'package:flutter/material.dart';
import '../providers/calculator_provider.dart';
import 'calculator_key_button.dart';

class CalculatorKeypad extends StatelessWidget {
  final CalculatorProvider provider;

  const CalculatorKeypad({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final hasTax = provider.config.hasTaxKeys;
    final isCorrectMode = provider.isCorrectMode;
    final isAutoReviewing = provider.isAutoReviewing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Review / Audit Bar (150-Step Check & Correct)
        Row(
          children: [
            CalculatorKeyButton(
              label: isAutoReviewing ? 'STOP' : 'AUTO',
              subLabel: 'REVIEW',
              category: KeyCategory.review,
              isHighlighted: isAutoReviewing,
              onTap: provider.toggleAutoReview,
            ),
            CalculatorKeyButton(
              label: isCorrectMode ? 'APPLY' : 'CORRECT',
              subLabel: isCorrectMode ? 'COMMIT' : 'EDIT',
              category: KeyCategory.review,
              isHighlighted: isCorrectMode,
              onTap: () {
                if (isCorrectMode) {
                  provider.commitCorrect();
                } else {
                  provider.startCorrect();
                }
              },
            ),
            CalculatorKeyButton(
              label: '◀',
              subLabel: 'CHECK',
              category: KeyCategory.review,
              onTap: provider.stepBack,
            ),
            CalculatorKeyButton(
              label: '▶',
              subLabel: 'CHECK',
              category: KeyCategory.review,
              onTap: provider.stepForward,
            ),
          ],
        ),

        // Row 1: Function / Tax Row
        if (hasTax)
          Row(
            children: [
              CalculatorKeyButton(
                label: 'TAX-',
                subLabel: 'EXCL',
                category: KeyCategory.tax,
                onTap: provider.taxMinus,
              ),
              CalculatorKeyButton(
                label: 'TAX+',
                subLabel: 'INCL',
                category: KeyCategory.tax,
                onTap: provider.taxPlus,
              ),
              CalculatorKeyButton(
                label: 'MU',
                subLabel: 'MARK UP',
                category: KeyCategory.action,
                onTap: provider.markUp,
              ),
              CalculatorKeyButton(
                label: '+/-',
                category: KeyCategory.action,
                onTap: provider.changeSign,
              ),
              CalculatorKeyButton(
                label: '▶',
                subLabel: 'DEL',
                category: KeyCategory.action,
                onTap: provider.backspace,
              ),
            ],
          )
        else
          // MJ-12D: Omits dedicated TAX keys
          Row(
            children: [
              CalculatorKeyButton(
                label: 'MU',
                subLabel: 'MARK UP',
                category: KeyCategory.action,
                onTap: provider.markUp,
              ),
              CalculatorKeyButton(
                label: '+/-',
                subLabel: 'SIGN',
                category: KeyCategory.action,
                onTap: provider.changeSign,
              ),
              CalculatorKeyButton(
                label: '▶',
                subLabel: 'DEL',
                category: KeyCategory.action,
                onTap: provider.backspace,
              ),
            ],
          ),

        // Row 2: Memory & Division
        Row(
          children: [
            CalculatorKeyButton(
              label: 'GT',
              subLabel: 'GRAND',
              category: KeyCategory.memory,
              isHighlighted: provider.hasGrandTotal,
              onTap: provider.grandTotalRecallClear,
            ),
            CalculatorKeyButton(
              label: 'MRC',
              subLabel: 'RECALL',
              category: KeyCategory.memory,
              isHighlighted: provider.hasMemory,
              onTap: provider.memoryRecallClear,
            ),
            CalculatorKeyButton(
              label: 'M-',
              category: KeyCategory.memory,
              onTap: provider.memorySubtract,
            ),
            CalculatorKeyButton(
              label: 'M+',
              category: KeyCategory.memory,
              onTap: provider.memoryAdd,
            ),
            CalculatorKeyButton(
              label: '÷',
              category: KeyCategory.operator,
              isHighlighted: provider.pendingOperator == '÷',
              onTap: () => provider.setOperator('÷'),
            ),
          ],
        ),

        // Row 3: Percent & 7, 8, 9, ×
        Row(
          children: [
            CalculatorKeyButton(
              label: '%',
              subLabel: hasTax ? 'HOLD: SET' : null,
              category: KeyCategory.action,
              onTap: provider.percent,
              onLongPress: hasTax ? provider.startTaxRateSet : null,
            ),
            CalculatorKeyButton(
              label: '7',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('7'),
            ),
            CalculatorKeyButton(
              label: '8',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('8'),
            ),
            CalculatorKeyButton(
              label: '9',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('9'),
            ),
            CalculatorKeyButton(
              label: '×',
              category: KeyCategory.operator,
              isHighlighted: provider.pendingOperator == '×',
              onTap: () => provider.setOperator('×'),
            ),
          ],
        ),

        // Row 4: Square Root & 4, 5, 6, -
        Row(
          children: [
            CalculatorKeyButton(
              label: '√',
              category: KeyCategory.action,
              onTap: provider.squareRoot,
            ),
            CalculatorKeyButton(
              label: '4',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('4'),
            ),
            CalculatorKeyButton(
              label: '5',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('5'),
            ),
            CalculatorKeyButton(
              label: '6',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('6'),
            ),
            CalculatorKeyButton(
              label: '-',
              category: KeyCategory.operator,
              isHighlighted: provider.pendingOperator == '-',
              onTap: () => provider.setOperator('-'),
            ),
          ],
        ),

        // Row 5: Clear Entry & 1, 2, 3, +
        Row(
          children: [
            CalculatorKeyButton(
              label: 'C',
              category: KeyCategory.clear,
              onTap: provider.clearEntry,
            ),
            CalculatorKeyButton(
              label: '1',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('1'),
            ),
            CalculatorKeyButton(
              label: '2',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('2'),
            ),
            CalculatorKeyButton(
              label: '3',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('3'),
            ),
            CalculatorKeyButton(
              label: '+',
              category: KeyCategory.operator,
              isHighlighted: provider.pendingOperator == '+',
              onTap: () => provider.setOperator('+'),
            ),
          ],
        ),

        // Row 6: All Clear & 0, 00, ., =
        Row(
          children: [
            CalculatorKeyButton(
              label: 'AC',
              category: KeyCategory.clear,
              onTap: provider.allClear,
            ),
            CalculatorKeyButton(
              label: '0',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('0'),
            ),
            CalculatorKeyButton(
              label: '00',
              category: KeyCategory.number,
              onTap: () => provider.inputDigit('00'),
            ),
            CalculatorKeyButton(
              label: '.',
              category: KeyCategory.number,
              onTap: provider.inputDecimal,
            ),
            CalculatorKeyButton(
              label: '=',
              category: KeyCategory.operator,
              onTap: provider.equals,
            ),
          ],
        ),
      ],
    );
  }
}
