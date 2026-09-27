import 'dart:math' as math;
import '../models/calculator_config.dart';
import '../models/calculation_step.dart';
import '../models/calculator_enums.dart';

class CalculatorEngine {
  CalculatorConfig _config;

  // Calculation state
  double _accumulator = 0.0;
  String _currentInput = '0';
  bool _isEnteringNumber = true;
  String? _pendingOperator; // '+', '-', '×', '÷', 'MU'

  // Constant calculation (K)
  bool _isConstantActive = false;
  double? _constantValue;
  String? _constantOperator;

  // Memory
  double _memory = 0.0;
  int _consecutiveMrcPresses = 0;

  // Grand Total
  double _grandTotal = 0.0;
  int _consecutiveGtPresses = 0;

  // Tax calculation
  double _taxRate = 5.0;
  bool _isTaxRateSetMode = false;
  String _taxRateInput = '';
  // State for toggling tax amount vs total
  bool _isTaxResultActive = false;
  double _lastTaxTotal = 0.0;
  double _lastTaxAmount = 0.0;
  double _lastTaxBeforePrice = 0.0;
  bool _isShowingTaxAmount = false;
  bool _lastTaxWasPlus = true;

  // Mark Up state
  double? _muCost;
  double? _muMargin;
  double? _muSellingPrice;
  double? _muProfit;
  bool _isMuActive = false;
  bool _isShowingMuProfit = false;

  // 150-Step Check & Correct buffer
  final List<CalculationStep> _steps = [];
  bool _isReviewMode = false;
  int _currentReviewIndex = -1;
  bool _isCorrectMode = false;
  String _correctInput = '';

  // Rounding & Decimal selectors
  RoundingMode _roundingMode = RoundingMode.halfUp;
  DecimalSetting _decimalSetting = DecimalSetting.f;

  // Error state
  bool _isError = false;
  String _errorMessage = '';

  CalculatorEngine({
    CalculatorConfig? config,
    double initialTaxRate = 5.0,
    RoundingMode initialRounding = RoundingMode.halfUp,
    DecimalSetting initialDecimal = DecimalSetting.f,
  })  : _config = config ?? CalculatorConfig.mj120d,
        _taxRate = initialTaxRate,
        _roundingMode = initialRounding,
        _decimalSetting = initialDecimal;

  // --- Getters ---
  CalculatorConfig get config => _config;
  bool get hasTaxKeys => _config.hasTaxKeys;
  bool get hasMarkUp => _config.hasMarkUp;
  int get maxSteps => _config.maxSteps;
  int get maxDigits => _config.maxDigits;

  double get memory => _memory;
  bool get hasMemory => _memory.abs() > 1e-9;

  double get grandTotal => _grandTotal;
  bool get hasGrandTotal => _grandTotal.abs() > 1e-9;

  double get taxRate => _taxRate;
  bool get isTaxRateSetMode => _isTaxRateSetMode;

  bool get isConstantActive => _isConstantActive;
  String? get pendingOperator => _pendingOperator;

  bool get isReviewMode => _isReviewMode;
  int get currentReviewIndex => _currentReviewIndex;
  int get totalSteps => _steps.length;
  bool get isCorrectMode => _isCorrectMode;
  List<CalculationStep> get steps => List.unmodifiable(_steps);

  RoundingMode get roundingMode => _roundingMode;
  DecimalSetting get decimalSetting => _decimalSetting;

  double? get muMargin => _muMargin;
  double? get muSellingPrice => _muSellingPrice;
  double? get muProfit => _muProfit;

  bool get isError => _isError;
  String get errorMessage => _errorMessage;

  CalculationStep? get currentStep {
    if (_isReviewMode && _currentReviewIndex >= 0 && _currentReviewIndex < _steps.length) {
      return _steps[_currentReviewIndex];
    }
    return null;
  }

  // --- Display String Calculation ---
  String get displayValue {
    if (_isError) {
      return _errorMessage.isNotEmpty ? _errorMessage : 'E';
    }
    if (_isTaxRateSetMode) {
      return _taxRateInput.isEmpty ? formatNumber(_taxRate) : _taxRateInput;
    }
    if (_isCorrectMode) {
      return _correctInput.isEmpty ? '0' : _correctInput;
    }
    if (_isReviewMode) {
      final step = currentStep;
      if (step != null) {
        return step.inputDisplay;
      }
    }
    return _currentInput;
  }

  double get currentNumericValue {
    if (_isError) return 0.0;
    return double.tryParse(_currentInput.replaceAll(',', '')) ?? 0.0;
  }

  // --- Configuration & Selectors ---
  void setConfig(CalculatorConfig newConfig) {
    _config = newConfig;
  }

  void setRoundingMode(RoundingMode mode) {
    _roundingMode = mode;
  }

  void setDecimalSetting(DecimalSetting setting) {
    _decimalSetting = setting;
  }

  void setTaxRate(double rate) {
    if (rate >= 0 && rate <= 100) {
      _taxRate = rate;
    }
  }

  // --- Digit & Input Handling ---
  void inputDigit(String digit) {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;
    _isTaxResultActive = false;

    if (_isError) return;

    if (_isTaxRateSetMode) {
      if (_taxRateInput.length < 5) {
        if (_taxRateInput == '0' && digit != '.') {
          _taxRateInput = digit;
        } else {
          _taxRateInput += digit;
        }
      }
      return;
    }

    if (_isCorrectMode) {
      if (_correctInput == '0' && digit != '00') {
        _correctInput = digit;
      } else if (_correctInput != '0' || digit != '00') {
        if (_digitCount(_correctInput) < maxDigits) {
          _correctInput += digit;
        }
      }
      return;
    }

    if (_isReviewMode) {
      // Exit review mode on new input
      exitReview();
    }

    if (!_isEnteringNumber) {
      _currentInput = digit == '00' ? '0' : digit;
      _isEnteringNumber = true;
    } else {
      if (_currentInput == '0') {
        if (digit == '00') return; // ignore multiple leading 0s
        _currentInput = digit;
      } else {
        if (_digitCount(_currentInput) < maxDigits) {
          _currentInput += digit;
        }
      }
    }
  }

  void inputDecimal() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;
    _isTaxResultActive = false;

    if (_isError) return;

    if (_isTaxRateSetMode) {
      if (!_taxRateInput.contains('.')) {
        _taxRateInput = _taxRateInput.isEmpty ? '0.' : '$_taxRateInput.';
      }
      return;
    }

    if (_isCorrectMode) {
      if (!_correctInput.contains('.')) {
        _correctInput = _correctInput.isEmpty ? '0.' : '$_correctInput.';
      }
      return;
    }

    if (_isReviewMode) {
      exitReview();
    }

    if (!_isEnteringNumber) {
      _currentInput = '0.';
      _isEnteringNumber = true;
    } else if (!_currentInput.contains('.')) {
      _currentInput = '$_currentInput.';
    }
  }

  void backspace() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    if (_isTaxRateSetMode) {
      if (_taxRateInput.isNotEmpty) {
        _taxRateInput = _taxRateInput.substring(0, _taxRateInput.length - 1);
      }
      return;
    }

    if (_isCorrectMode) {
      if (_correctInput.length > 1) {
        _correctInput = _correctInput.substring(0, _correctInput.length - 1);
      } else {
        _correctInput = '0';
      }
      return;
    }

    if (_isReviewMode) return;

    if (!_isEnteringNumber) return;

    if (_currentInput.length > 1) {
      if (_currentInput.length == 2 && _currentInput.startsWith('-')) {
        _currentInput = '0';
      } else {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    } else {
      _currentInput = '0';
    }
  }

  void changeSign() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    if (_isCorrectMode) {
      if (_correctInput != '0' && _correctInput != '0.') {
        if (_correctInput.startsWith('-')) {
          _correctInput = _correctInput.substring(1);
        } else {
          _correctInput = '-$_correctInput';
        }
      }
      return;
    }

    if (_isReviewMode) return;

    if (_currentInput != '0' && _currentInput != '0.') {
      if (_currentInput.startsWith('-')) {
        _currentInput = _currentInput.substring(1);
      } else {
        _currentInput = '-$_currentInput';
      }
    }
  }

  // --- Operator Handling (+, -, ×, ÷) ---
  void setOperator(String op) {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;
    _isTaxResultActive = false;

    if (_isError) return;
    if (_isReviewMode) exitReview();

    final inputVal = currentNumericValue;

    // Check for Constant Calculation (K):
    // Casio activates constant calculation when the operator key is pressed twice
    if (_pendingOperator == op && !_isEnteringNumber) {
      _isConstantActive = true;
      _constantValue = inputVal;
      _constantOperator = op;
      return;
    }

    if (_pendingOperator != null && _isEnteringNumber) {
      // Complete previous intermediate operation
      _calculateIntermediate();
    } else {
      _accumulator = inputVal;
    }

    // Record step in buffer if this is the start or intermediate
    _recordStep(
      operator: op,
      inputValue: inputVal,
      resultAfterStep: _accumulator,
    );

    _pendingOperator = op;
    _isEnteringNumber = false;
  }

  void _calculateIntermediate() {
    if (_pendingOperator == null) return;

    final secondVal = currentNumericValue;
    double result = _accumulator;

    switch (_pendingOperator) {
      case '+':
        result = _accumulator + secondVal;
        break;
      case '-':
        result = _accumulator - secondVal;
        break;
      case '×':
        result = _accumulator * secondVal;
        break;
      case '÷':
        if (secondVal == 0) {
          _setError('E 0');
          return;
        }
        result = _accumulator / secondVal;
        break;
    }

    result = _applyRounding(result);
    if (_checkOverflow(result)) return;

    _accumulator = result;
    _currentInput = formatNumber(result);
  }

  // --- Equals (=) & Evaluation ---
  void equals() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;
    if (_isReviewMode) {
      exitReview();
      return;
    }

    // Handle MU profit display if '=' is pressed after MU %
    if (_isMuActive && _muProfit != null) {
      if (!_isShowingMuProfit) {
        _isShowingMuProfit = true;
        _currentInput = formatNumber(_muProfit!);
        return;
      } else {
        _isMuActive = false;
        _isShowingMuProfit = false;
      }
    }

    final inputVal = currentNumericValue;
    double result = _accumulator;

    if (_isConstantActive && _constantOperator != null && _constantValue != null) {
      // Apply constant calculation:
      // For addition/subtraction: inputVal [op] constant
      // For multiplication/division: constant [op] inputVal (or inputVal [op] constant)
      switch (_constantOperator) {
        case '+':
          result = inputVal + _constantValue!;
          break;
        case '-':
          result = inputVal - _constantValue!;
          break;
        case '×':
          result = inputVal * _constantValue!;
          break;
        case '÷':
          if (_constantValue! == 0) {
            _setError('E 0');
            return;
          }
          result = inputVal / _constantValue!;
          break;
      }
      result = _applyRounding(result);
      if (_checkOverflow(result)) return;

      _recordStep(
        operator: '=',
        inputValue: inputVal,
        resultAfterStep: result,
        isConstant: true,
      );

      _accumulator = result;
      _currentInput = formatNumber(result);
      _grandTotal += result;
      _isEnteringNumber = false;
      return;
    }

    if (_pendingOperator != null) {
      final op = _pendingOperator!;
      switch (op) {
        case '+':
          result = _accumulator + inputVal;
          break;
        case '-':
          result = _accumulator - inputVal;
          break;
        case '×':
          result = _accumulator * inputVal;
          break;
        case '÷':
          if (inputVal == 0) {
            _setError('E 0');
            return;
          }
          result = _accumulator / inputVal;
          break;
      }

      result = _applyRounding(result);
      if (_checkOverflow(result)) return;

      // Enable repeated '=' constant calculation
      _constantValue = inputVal;
      _constantOperator = op;

      _recordStep(
        operator: '=',
        inputValue: inputVal,
        resultAfterStep: result,
      );

      _accumulator = result;
      _currentInput = formatNumber(result);
      _grandTotal += result;
      _pendingOperator = null;
      _isEnteringNumber = false;
    } else if (_constantOperator != null && _constantValue != null) {
      // Repeating '=' after a previous '='
      _isConstantActive = true;
      switch (_constantOperator) {
        case '+':
          result = _accumulator + _constantValue!;
          break;
        case '-':
          result = _accumulator - _constantValue!;
          break;
        case '×':
          result = _accumulator * _constantValue!;
          break;
        case '÷':
          if (_constantValue! == 0) {
            _setError('E 0');
            return;
          }
          result = _accumulator / _constantValue!;
          break;
      }
      result = _applyRounding(result);
      if (_checkOverflow(result)) return;

      _recordStep(
        operator: '=',
        inputValue: _constantValue!,
        resultAfterStep: result,
        isConstant: true,
      );

      _accumulator = result;
      _currentInput = formatNumber(result);
      _grandTotal += result;
      _isEnteringNumber = false;
    }
  }

  // --- Percent (%) Key ---
  void percent() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    // If MU was pressed: [Cost] [MU] [Rate] [%]
    if (_pendingOperator == 'MU') {
      _executeMarkUp();
      return;
    }

    final inputVal = currentNumericValue;
    double result = 0.0;

    if (_pendingOperator != null) {
      final op = _pendingOperator!;
      final base = _accumulator;

      switch (op) {
        case '×':
          // Standard percentage: e.g. 100 × 5 % = 5
          result = base * (inputVal / 100.0);
          break;
        case '÷':
          // Ratio: e.g. 30 ÷ 60 % = 50 (%)
          if (inputVal == 0) {
            _setError('E 0');
            return;
          }
          result = (base / inputVal) * 100.0;
          break;
        case '+':
          // Percentage add-on: 100 + 5 % = 105
          final percentVal = base * (inputVal / 100.0);
          result = base + percentVal;
          break;
        case '-':
          // Percentage discount: 100 - 5 % = 95
          final percentVal = base * (inputVal / 100.0);
          result = base - percentVal;
          break;
      }

      result = _applyRounding(result);
      if (_checkOverflow(result)) return;

      _recordStep(
        operator: '%',
        inputValue: inputVal,
        resultAfterStep: result,
      );

      _accumulator = result;
      _currentInput = formatNumber(result);
      _grandTotal += result;
      _pendingOperator = null;
      _isEnteringNumber = false;
    } else {
      // Just pressing % on a single number
      result = inputVal / 100.0;
      result = _applyRounding(result);
      _currentInput = formatNumber(result);
      _accumulator = result;
      _isEnteringNumber = false;
    }
  }

  // --- Mark Up (MU) ---
  void markUp() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (!hasMarkUp || _isError) return;

    final inputVal = currentNumericValue;
    _muCost = inputVal;
    _pendingOperator = 'MU';
    _isMuActive = true;
    _isShowingMuProfit = false;
    _isEnteringNumber = false;

    _recordStep(
      operator: 'MU',
      inputValue: inputVal,
      resultAfterStep: inputVal,
    );
  }

  void _executeMarkUp() {
    final marginRate = currentNumericValue; // percentage
    final cost = _muCost ?? _accumulator;

    // Selling price = Cost / (1 - (marginRate / 100))
    final marginFraction = marginRate / 100.0;
    if ((1.0 - marginFraction).abs() < 1e-9) {
      _setError('E 0');
      return;
    }

    double sellingPrice = cost / (1.0 - marginFraction);
    sellingPrice = _applyRounding(sellingPrice);
    if (_checkOverflow(sellingPrice)) return;

    final profit = sellingPrice - cost;

    _muMargin = marginRate;
    _muSellingPrice = sellingPrice;
    _muProfit = profit;

    _recordStep(
      operator: 'MU %',
      inputValue: marginRate,
      resultAfterStep: sellingPrice,
    );

    _accumulator = sellingPrice;
    _currentInput = formatNumber(sellingPrice);
    _grandTotal += sellingPrice;
    _pendingOperator = null;
    _isEnteringNumber = false;
  }

  // --- Square Root (√) ---
  void squareRoot() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    final val = currentNumericValue;
    if (val < 0) {
      _setError('E');
      return;
    }

    double result = math.sqrt(val);
    result = _applyRounding(result);

    _recordStep(
      operator: '√',
      inputValue: val,
      resultAfterStep: result,
    );

    _currentInput = formatNumber(result);
    _accumulator = result;
    _isEnteringNumber = false;
  }

  // --- Tax Operations (TAX+ / TAX-) ---
  void taxPlus() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (!hasTaxKeys || _isError) return;

    if (_isTaxRateSetMode) {
      saveTaxRate();
      return;
    }

    // Consecutive press toggle between total and tax amount
    if (_isTaxResultActive && _lastTaxWasPlus && !_isEnteringNumber) {
      _isShowingTaxAmount = !_isShowingTaxAmount;
      if (_isShowingTaxAmount) {
        _currentInput = formatNumber(_lastTaxAmount);
      } else {
        _currentInput = formatNumber(_lastTaxTotal);
      }
      return;
    }

    final inputVal = currentNumericValue;
    _lastTaxBeforePrice = inputVal;
    _lastTaxAmount = _applyRounding(_cleanFloat(inputVal * (_taxRate / 100.0)));
    final total = _applyRounding(_cleanFloat(inputVal + _lastTaxAmount));

    if (_checkOverflow(total)) return;

    _lastTaxTotal = total;
    _lastTaxWasPlus = true;
    _isTaxResultActive = true;
    _isShowingTaxAmount = false;

    _recordStep(
      operator: 'TAX+',
      inputValue: inputVal,
      resultAfterStep: total,
    );

    _accumulator = total;
    _currentInput = formatNumber(total);
    _grandTotal += total;
    _isEnteringNumber = false;
  }

  void taxMinus() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (!hasTaxKeys || _isError) return;

    if (_isTaxRateSetMode) return;

    // Consecutive press toggle between price before tax and tax amount
    if (_isTaxResultActive && !_lastTaxWasPlus && !_isEnteringNumber) {
      _isShowingTaxAmount = !_isShowingTaxAmount;
      if (_isShowingTaxAmount) {
        _currentInput = formatNumber(_lastTaxAmount);
      } else {
        _currentInput = formatNumber(_lastTaxBeforePrice);
      }
      return;
    }

    final inputVal = currentNumericValue;
    final priceBefore = _applyRounding(_cleanFloat(inputVal / (1.0 + _taxRate / 100.0)));
    final taxAmt = _applyRounding(_cleanFloat(inputVal - priceBefore));

    if (_checkOverflow(priceBefore)) return;

    _lastTaxTotal = inputVal;
    _lastTaxBeforePrice = priceBefore;
    _lastTaxAmount = taxAmt;
    _lastTaxWasPlus = false;
    _isTaxResultActive = true;
    _isShowingTaxAmount = false;

    _recordStep(
      operator: 'TAX-',
      inputValue: inputVal,
      resultAfterStep: priceBefore,
    );

    _accumulator = priceBefore;
    _currentInput = formatNumber(priceBefore);
    _isEnteringNumber = false;
  }

  void startTaxRateSet() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    _isTaxRateSetMode = true;
    _taxRateInput = '';
  }

  void saveTaxRate() {
    if (!_isTaxRateSetMode) return;

    if (_taxRateInput.isNotEmpty) {
      final newRate = double.tryParse(_taxRateInput);
      if (newRate != null && newRate >= 0 && newRate <= 100) {
        _taxRate = newRate;
      }
    }
    _isTaxRateSetMode = false;
    _taxRateInput = '';
    _currentInput = formatNumber(_taxRate);
    _isEnteringNumber = false;
  }

  void cancelTaxRateSet() {
    _isTaxRateSetMode = false;
    _taxRateInput = '';
  }

  // --- Independent Memory (M+, M-, MRC) ---
  void memoryAdd() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    if (_pendingOperator != null) {
      equals();
    }

    final val = currentNumericValue;
    _memory += val;
    _memory = _applyRounding(_memory);
    _isEnteringNumber = false;
  }

  void memorySubtract() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) return;

    if (_pendingOperator != null) {
      equals();
    }

    final val = currentNumericValue;
    _memory -= val;
    _memory = _applyRounding(_memory);
    _isEnteringNumber = false;
  }

  void memoryRecallClear() {
    _consecutiveGtPresses = 0;

    if (_isError) return;

    _consecutiveMrcPresses++;
    if (_consecutiveMrcPresses == 1) {
      // Memory Recall
      _currentInput = formatNumber(_memory);
      _accumulator = _memory;
      _isEnteringNumber = false;
    } else {
      // Memory Clear
      _memory = 0.0;
      _consecutiveMrcPresses = 0;
    }
  }

  // --- Grand Total (GT) ---
  void grandTotalRecallClear() {
    _consecutiveMrcPresses = 0;

    if (_isError) return;

    _consecutiveGtPresses++;
    if (_consecutiveGtPresses == 1) {
      // Recall GT
      _currentInput = formatNumber(_grandTotal);
      _accumulator = _grandTotal;
      _isEnteringNumber = false;
    } else {
      // Clear GT
      _grandTotal = 0.0;
      _consecutiveGtPresses = 0;
    }
  }

  // --- Clear Operations (C & AC) ---
  void clearEntry() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    if (_isError) {
      _clearError();
      return;
    }

    if (_isTaxRateSetMode) {
      _taxRateInput = '';
      return;
    }

    if (_isCorrectMode) {
      _correctInput = '0';
      return;
    }

    if (_isReviewMode) {
      exitReview();
      return;
    }

    _currentInput = '0';
    _isEnteringNumber = true;
  }

  void allClear() {
    _consecutiveMrcPresses = 0;
    _consecutiveGtPresses = 0;

    _clearError();
    _accumulator = 0.0;
    _currentInput = '0';
    _isEnteringNumber = true;
    _pendingOperator = null;
    _isConstantActive = false;
    _constantValue = null;
    _constantOperator = null;
    _isTaxRateSetMode = false;
    _taxRateInput = '';
    _isTaxResultActive = false;
    _lastTaxBeforePrice = 0.0;
    _lastTaxTotal = 0.0;
    _lastTaxAmount = 0.0;
    _isShowingTaxAmount = false;
    _isMuActive = false;
    _isShowingMuProfit = false;
    exitReview();
  }

  void clearAllWithMemoryAndGt() {
    allClear();
    _memory = 0.0;
    _grandTotal = 0.0;
    _steps.clear();
  }

  void _clearError() {
    _isError = false;
    _errorMessage = '';
  }

  // --- 150-Step Check & Correct Buffer ---
  void _recordStep({
    required String operator,
    required double inputValue,
    required double resultAfterStep,
    bool isConstant = false,
  }) {
    if (_steps.length >= maxSteps) {
      _steps.removeAt(0);
      // Renumber
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = _steps[i].copyWith(stepNumber: i + 1);
      }
    }

    final newStep = CalculationStep(
      stepNumber: _steps.length + 1,
      operator: operator,
      inputValue: inputValue,
      inputDisplay: formatNumber(inputValue),
      resultAfterStep: resultAfterStep,
      resultDisplay: formatNumber(resultAfterStep),
      isConstant: isConstant,
    );

    _steps.add(newStep);
  }

  void stepBack() {
    if (_steps.isEmpty) return;

    if (!_isReviewMode) {
      _isReviewMode = true;
      _currentReviewIndex = _steps.length - 1;
    } else {
      if (_currentReviewIndex > 0) {
        _currentReviewIndex--;
      }
    }
  }

  void stepForward() {
    if (_steps.isEmpty) return;

    if (!_isReviewMode) {
      _isReviewMode = true;
      _currentReviewIndex = 0;
    } else {
      if (_currentReviewIndex < _steps.length - 1) {
        _currentReviewIndex++;
      }
    }
  }

  void jumpToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _steps.length) {
      _isReviewMode = true;
      _currentReviewIndex = stepIndex;
    }
  }

  void exitReview() {
    _isReviewMode = false;
    _currentReviewIndex = -1;
    _isCorrectMode = false;
    _correctInput = '';
  }

  void startCorrect() {
    if (!_isReviewMode || currentStep == null) return;
    _isCorrectMode = true;
    _correctInput = currentStep!.inputDisplay;
  }

  void cancelCorrect() {
    _isCorrectMode = false;
    _correctInput = '';
  }

  void commitCorrect({String? newOperator}) {
    if (!_isCorrectMode || currentStep == null) return;

    final newVal = double.tryParse(_correctInput.replaceAll(',', '')) ?? currentStep!.inputValue;
    final op = newOperator ?? currentStep!.operator;

    // Update the step at currentReviewIndex
    _steps[_currentReviewIndex] = _steps[_currentReviewIndex].copyWith(
      inputValue: newVal,
      inputDisplay: formatNumber(newVal),
      operator: op,
    );

    _isCorrectMode = false;
    _correctInput = '';

    // Replay and recalculate the entire buffer from step 0
    _recalculateSteps();

    // After commit, display the newly re-evaluated total
    _isReviewMode = false;
    _currentReviewIndex = -1;
  }

  void _recalculateSteps() {
    if (_steps.isEmpty) return;

    double runningTotal = 0.0;
    String? lastOp;

    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final val = step.inputValue;
      final op = step.operator;

      if (i == 0) {
        runningTotal = val;
        lastOp = op;
      } else {
        final effectiveOp = lastOp ?? op;
        switch (effectiveOp) {
          case '+':
            runningTotal = runningTotal + val;
            break;
          case '-':
            runningTotal = runningTotal - val;
            break;
          case '×':
            runningTotal = runningTotal * val;
            break;
          case '÷':
            if (val != 0) {
              runningTotal = runningTotal / val;
            }
            break;
          case 'TAX+':
            runningTotal = _cleanFloat(val * (1.0 + _taxRate / 100.0));
            break;
          case 'TAX-':
            runningTotal = _cleanFloat(val / (1.0 + _taxRate / 100.0));
            break;
          default:
            runningTotal = val;
            break;
        }
        lastOp = op;
      }

      runningTotal = _applyRounding(runningTotal);
      _steps[i] = _steps[i].copyWith(
        resultAfterStep: runningTotal,
        resultDisplay: formatNumber(runningTotal),
      );
    }

    _accumulator = runningTotal;
    _currentInput = formatNumber(runningTotal);
  }

  // --- Rounding & Decimal Formatting ---
  double _cleanFloat(double val) {
    if (val.isNaN || val.isInfinite) return val;
    // Fix floating point imprecisions like 99.99999999999999 -> 100.0
    return double.parse(val.toStringAsPrecision(12));
  }

  double _applyRounding(double value) {
    if (_decimalSetting == DecimalSetting.f) {
      return value;
    }

    final places = _decimalSetting.decimalPlaces ?? 2;
    final multiplier = math.pow(10, places).toDouble();

    switch (_roundingMode) {
      case RoundingMode.cut:
        // Truncate toward zero
        if (value >= 0) {
          return (value * multiplier).floorToDouble() / multiplier;
        } else {
          return (value * multiplier).ceilToDouble() / multiplier;
        }
      case RoundingMode.up:
        // Round away from zero
        if (value >= 0) {
          return (value * multiplier).ceilToDouble() / multiplier;
        } else {
          return (value * multiplier).floorToDouble() / multiplier;
        }
      case RoundingMode.halfUp:
        // Standard round 5/4
        return (value * multiplier).roundToDouble() / multiplier;
    }
  }

  String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'E';

    // Check fixed decimal place formatting
    if (_decimalSetting != DecimalSetting.f) {
      final places = _decimalSetting.decimalPlaces ?? 2;
      return value.toStringAsFixed(places);
    }

    // Floating format: avoid scientific notation if within 12 digits
    if (value.abs() >= 1e12) {
      return value.toStringAsExponential(6);
    }

    // Remove unnecessary trailing zeroes
    String str = value.toString();
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      if (str.endsWith('.')) {
        str = str.substring(0, str.length - 1);
      }
    }
    return str;
  }

  int _digitCount(String str) {
    return str.replaceAll(RegExp(r'[^0-9]'), '').length;
  }

  bool _checkOverflow(double value) {
    if (value.abs() >= math.pow(10, maxDigits)) {
      _setError('E');
      return true;
    }
    return false;
  }

  void _setError(String msg) {
    _isError = true;
    _errorMessage = msg;
    _isEnteringNumber = false;
  }
}
