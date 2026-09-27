import 'package:flutter_test/flutter_test.dart';
import 'package:attend_pulse/engine/calculator_engine.dart';
import 'package:attend_pulse/models/calculator_config.dart';
import 'package:attend_pulse/models/calculator_enums.dart';

void main() {
  group('Casio Calculator Engine Unit Tests', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine(
        config: CalculatorConfig.mj120d,
        initialTaxRate: 5.0,
      );
    });

    test('TAX+ calculation and tax amount breakdown', () {
      // Set tax rate = 5%
      engine.setTaxRate(5.0);

      // Enter 100
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.inputDigit('0');
      expect(engine.displayValue, '100');

      // First press of TAX+ should calculate 100 + 5% = 105
      engine.taxPlus();
      expect(engine.currentNumericValue, 105.0);
      expect(engine.displayValue, '105');

      // Second consecutive press of TAX+ should display the tax amount (5)
      engine.taxPlus();
      expect(engine.currentNumericValue, 5.0);
      expect(engine.displayValue, '5');

      // Third press returns to total 105
      engine.taxPlus();
      expect(engine.currentNumericValue, 105.0);
    });

    test('TAX- calculation and tax amount breakdown', () {
      // Set tax rate = 10%
      engine.setTaxRate(10.0);

      // Enter 110
      engine.inputDigit('1');
      engine.inputDigit('1');
      engine.inputDigit('0');

      // First press of TAX- on 110 at 10% tax rate gives price before tax = 100
      engine.taxMinus();
      expect(engine.currentNumericValue, 100.0);
      expect(engine.displayValue, '100');

      // Second press of TAX- displays the tax amount subtracted = 10
      engine.taxMinus();
      expect(engine.currentNumericValue, 10.0);
      expect(engine.displayValue, '10');

      // Third press toggles back to 100
      engine.taxMinus();
      expect(engine.currentNumericValue, 100.0);
    });

    test('Tax rate setting and persistence mode', () {
      engine.startTaxRateSet();
      expect(engine.isTaxRateSetMode, isTrue);

      engine.inputDigit('1');
      engine.inputDigit('8');
      expect(engine.displayValue, '18');

      engine.saveTaxRate();
      expect(engine.isTaxRateSetMode, isFalse);
      expect(engine.taxRate, 18.0);
    });

    test('GT (Grand Total) accumulates sequential equals operations and recalls/clears', () {
      // Calculation 1: 10 + 20 = 30
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.setOperator('+');
      engine.inputDigit('2');
      engine.inputDigit('0');
      engine.equals();
      expect(engine.displayValue, '30');
      expect(engine.hasGrandTotal, isTrue);
      expect(engine.grandTotal, 30.0);

      // Calculation 2: 5 × 4 = 20
      engine.inputDigit('5');
      engine.setOperator('×');
      engine.inputDigit('4');
      engine.equals();
      expect(engine.displayValue, '20');
      expect(engine.grandTotal, 50.0); // 30 + 20 = 50

      // Recall GT (1st press)
      engine.grandTotalRecallClear();
      expect(engine.displayValue, '50');
      expect(engine.hasGrandTotal, isTrue);

      // Clear GT (2nd press)
      engine.grandTotalRecallClear();
      expect(engine.hasGrandTotal, isFalse);
      expect(engine.grandTotal, 0.0);
    });

    test('Independent Memory (M+, M-, MRC) operations and clearing', () {
      expect(engine.hasMemory, isFalse);

      // Add 50 to memory
      engine.inputDigit('5');
      engine.inputDigit('0');
      engine.memoryAdd();
      expect(engine.hasMemory, isTrue);
      expect(engine.memory, 50.0);

      // Add 25 to memory
      engine.inputDigit('2');
      engine.inputDigit('5');
      engine.memoryAdd();
      expect(engine.memory, 75.0);

      // Subtract 15 from memory
      engine.inputDigit('1');
      engine.inputDigit('5');
      engine.memorySubtract();
      expect(engine.memory, 60.0);

      // First press of MRC recalls memory (60)
      engine.memoryRecallClear();
      expect(engine.displayValue, '60');
      expect(engine.hasMemory, isTrue);

      // Second press of MRC clears memory
      engine.memoryRecallClear();
      expect(engine.hasMemory, isFalse);
      expect(engine.memory, 0.0);
    });

    test('Constant calculation (K) via double-operator press', () {
      // 5 × × (sets 5 as constant multiplier)
      engine.inputDigit('5');
      engine.setOperator('×');
      engine.setOperator('×'); // second press triggers constant mode
      expect(engine.isConstantActive, isTrue);

      // 10 = -> 50
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.equals();
      expect(engine.displayValue, '50');

      // 20 = -> 100
      engine.inputDigit('2');
      engine.inputDigit('0');
      engine.equals();
      expect(engine.displayValue, '100');
    });

    test('Constant calculation via repeated equals (=) key', () {
      // 10 + 5 = 15
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.setOperator('+');
      engine.inputDigit('5');
      engine.equals();
      expect(engine.displayValue, '15');

      // Repeating = adds 5 again: 15 + 5 = 20
      engine.equals();
      expect(engine.displayValue, '20');

      // Repeating = adds 5 again: 20 + 5 = 25
      engine.equals();
      expect(engine.displayValue, '25');
    });

    test('150-step Check & Correct buffer records steps, allows review, editing, and recalculation replay', () {
      // Sequence: 10 + 20 + 30 = 60
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.setOperator('+'); // Step 1

      engine.inputDigit('2');
      engine.inputDigit('0');
      engine.setOperator('+'); // Step 2

      engine.inputDigit('3');
      engine.inputDigit('0');
      engine.equals(); // Step 3

      expect(engine.displayValue, '60');
      expect(engine.totalSteps, 3);

      // Review steps
      engine.stepBack(); // Jumps to step 3 (last step)
      expect(engine.isReviewMode, isTrue);
      expect(engine.currentStep?.inputValue, 30.0);

      engine.stepBack(); // Step 2: 20
      expect(engine.currentStep?.inputValue, 20.0);

      // Edit Step 2 from 20 to 50 using CORRECT
      engine.startCorrect();
      expect(engine.isCorrectMode, isTrue);

      // Enter new number 50
      engine.clearEntry();
      engine.inputDigit('5');
      engine.inputDigit('0');
      expect(engine.displayValue, '50');

      // Commit correction
      engine.commitCorrect();
      expect(engine.isCorrectMode, isFalse);

      // Recalculation should be: 10 + 50 + 30 = 90!
      expect(engine.displayValue, '90');
    });

    test('Casio Mark-Up (MU) calculation and gross profit breakdown', () {
      // Cost = 120, desired profit margin = 20%
      // 120 MU 20 % -> Selling price = 120 / (1 - 0.20) = 150
      engine.inputDigit('1');
      engine.inputDigit('2');
      engine.inputDigit('0');
      engine.markUp();

      engine.inputDigit('2');
      engine.inputDigit('0');
      engine.percent();

      expect(engine.displayValue, '150');

      // Pressing = displays profit = 150 - 120 = 30
      engine.equals();
      expect(engine.displayValue, '30');
    });

    test('Decimal and Rounding selector behavior (5/4, CUT, UP)', () {
      // 10 ÷ 3 = 3.333333...
      engine.setDecimalSetting(DecimalSetting.d2);
      engine.setRoundingMode(RoundingMode.cut);

      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.setOperator('÷');
      engine.inputDigit('3');
      engine.equals();
      expect(engine.displayValue, '3.33');

      // UP rounding on 3.331 -> 3.34
      engine.setRoundingMode(RoundingMode.up);
      engine.allClear();
      engine.inputDigit('3');
      engine.inputDecimal();
      engine.inputDigit('3');
      engine.inputDigit('3');
      engine.inputDigit('1');
      engine.setOperator('+');
      engine.inputDigit('0');
      engine.equals();
      expect(engine.displayValue, '3.34');
    });

    test('Casio MJ-12D disables tax keys while MJ-120D enables them', () {
      final engine120d = CalculatorEngine(config: CalculatorConfig.mj120d);
      expect(engine120d.hasTaxKeys, isTrue);

      final engine12d = CalculatorEngine(config: CalculatorConfig.mj12d);
      expect(engine12d.hasTaxKeys, isFalse);

      // In MJ-12D, taxPlus does nothing
      engine12d.inputDigit('1');
      engine12d.inputDigit('0');
      engine12d.inputDigit('0');
      engine12d.taxPlus();
      expect(engine12d.displayValue, '100'); // Unchanged
    });
  });
}
