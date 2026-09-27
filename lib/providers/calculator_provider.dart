import 'dart:async';
import 'package:flutter/material.dart';
import '../engine/calculator_engine.dart';
import '../models/app_settings.dart';
import '../models/calculation_step.dart';
import '../models/calculator_config.dart';
import '../models/calculator_enums.dart';
import '../models/calculator_settings.dart';
import '../services/storage_service.dart';

class CalculatorProvider extends ChangeNotifier {
  final StorageService _storageService;
  late CalculatorEngine _engine;
  late CalculatorSettings _settings;

  Timer? _autoReviewTimer;
  bool _isAutoReviewing = false;

  CalculatorProvider(this._storageService) {
    _settings = _storageService.loadCalculatorSettings();
    _engine = CalculatorEngine(
      config: CalculatorConfig.forModel(_settings.activeModel),
      initialTaxRate: _settings.taxRate,
      initialRounding: _settings.roundingMode,
      initialDecimal: _settings.decimalSetting,
    );
  }

  // --- Engine & Settings Access ---
  CalculatorEngine get engine => _engine;
  CalculatorSettings get settings => _settings;
  CalculatorModel get activeModel => _settings.activeModel;
  CalculatorConfig get config => _engine.config;

  String get displayValue => _engine.displayValue;
  double get currentNumericValue => _engine.currentNumericValue;
  bool get hasMemory => _engine.hasMemory;
  double get memory => _engine.memory;
  bool get hasGrandTotal => _engine.hasGrandTotal;
  double get grandTotal => _engine.grandTotal;
  bool get isConstantActive => _engine.isConstantActive;
  String? get pendingOperator => _engine.pendingOperator;
  bool get isReviewMode => _engine.isReviewMode;
  int get currentReviewIndex => _engine.currentReviewIndex;
  int get totalSteps => _engine.totalSteps;
  CalculationStep? get currentStep => _engine.currentStep;
  List<CalculationStep> get steps => _engine.steps;
  bool get isCorrectMode => _engine.isCorrectMode;
  bool get isTaxRateSetMode => _engine.isTaxRateSetMode;
  double get taxRate => _engine.taxRate;
  bool get isError => _engine.isError;
  String get errorMessage => _engine.errorMessage;
  bool get isAutoReviewing => _isAutoReviewing;

  RoundingMode get roundingMode => _settings.roundingMode;
  DecimalSetting get decimalSetting => _settings.decimalSetting;
  ThemeMode get themeMode => _settings.themeMode;
  AppColorOption get activeColor => _settings.activeColor;

  // --- Model Switching (MJ-120D vs MJ-12D) ---
  void switchModel(CalculatorModel newModel) {
    if (_settings.activeModel == newModel) return;

    stopAutoReview();
    _settings = _settings.copyWith(activeModel: newModel);
    _engine.setConfig(CalculatorConfig.forModel(newModel));
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  // --- Selectors & Settings ---
  void setRoundingMode(RoundingMode mode) {
    _settings = _settings.copyWith(roundingMode: mode);
    _engine.setRoundingMode(mode);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  void setDecimalSetting(DecimalSetting setting) {
    _settings = _settings.copyWith(decimalSetting: setting);
    _engine.setDecimalSetting(setting);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _settings = _settings.copyWith(taxRate: rate);
    _engine.setTaxRate(rate);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  void setActiveColor(AppColorOption color) {
    _settings = _settings.copyWith(activeColor: color);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  // --- Calculator Operations ---
  void inputDigit(String digit) {
    stopAutoReview();
    _engine.inputDigit(digit);
    notifyListeners();
  }

  void inputDecimal() {
    stopAutoReview();
    _engine.inputDecimal();
    notifyListeners();
  }

  void backspace() {
    stopAutoReview();
    _engine.backspace();
    notifyListeners();
  }

  void changeSign() {
    stopAutoReview();
    _engine.changeSign();
    notifyListeners();
  }

  void setOperator(String op) {
    stopAutoReview();
    _engine.setOperator(op);
    notifyListeners();
  }

  void equals() {
    stopAutoReview();
    _engine.equals();
    notifyListeners();
  }

  void percent() {
    stopAutoReview();
    _engine.percent();
    notifyListeners();
  }

  void squareRoot() {
    stopAutoReview();
    _engine.squareRoot();
    notifyListeners();
  }

  void markUp() {
    stopAutoReview();
    _engine.markUp();
    notifyListeners();
  }

  void taxPlus() {
    stopAutoReview();
    _engine.taxPlus();
    notifyListeners();
  }

  void taxMinus() {
    stopAutoReview();
    _engine.taxMinus();
    notifyListeners();
  }

  void startTaxRateSet() {
    stopAutoReview();
    _engine.startTaxRateSet();
    notifyListeners();
  }

  void saveTaxRate() {
    _engine.saveTaxRate();
    _settings = _settings.copyWith(taxRate: _engine.taxRate);
    _storageService.saveCalculatorSettings(_settings);
    notifyListeners();
  }

  void cancelTaxRateSet() {
    _engine.cancelTaxRateSet();
    notifyListeners();
  }

  void memoryAdd() {
    stopAutoReview();
    _engine.memoryAdd();
    notifyListeners();
  }

  void memorySubtract() {
    stopAutoReview();
    _engine.memorySubtract();
    notifyListeners();
  }

  void memoryRecallClear() {
    stopAutoReview();
    _engine.memoryRecallClear();
    notifyListeners();
  }

  void grandTotalRecallClear() {
    stopAutoReview();
    _engine.grandTotalRecallClear();
    notifyListeners();
  }

  void clearEntry() {
    stopAutoReview();
    _engine.clearEntry();
    notifyListeners();
  }

  void allClear() {
    stopAutoReview();
    _engine.allClear();
    notifyListeners();
  }

  // --- Check & Correct Operations ---
  void stepBack() {
    stopAutoReview();
    _engine.stepBack();
    notifyListeners();
  }

  void stepForward() {
    stopAutoReview();
    _engine.stepForward();
    notifyListeners();
  }

  void jumpToStep(int index) {
    stopAutoReview();
    _engine.jumpToStep(index);
    notifyListeners();
  }

  void exitReview() {
    stopAutoReview();
    _engine.exitReview();
    notifyListeners();
  }

  void startCorrect() {
    stopAutoReview();
    _engine.startCorrect();
    notifyListeners();
  }

  void cancelCorrect() {
    _engine.cancelCorrect();
    notifyListeners();
  }

  void commitCorrect({String? newOperator}) {
    _engine.commitCorrect(newOperator: newOperator);
    notifyListeners();
  }

  // --- Auto Review Playback ---
  void toggleAutoReview() {
    if (_isAutoReviewing) {
      stopAutoReview();
    } else {
      startAutoReview();
    }
  }

  void startAutoReview() {
    if (_engine.steps.isEmpty) return;

    _isAutoReviewing = true;
    _engine.jumpToStep(0);
    notifyListeners();

    _autoReviewTimer?.cancel();
    _autoReviewTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_engine.currentReviewIndex < _engine.steps.length - 1) {
        _engine.stepForward();
        notifyListeners();
      } else {
        stopAutoReview();
      }
    });
  }

  void stopAutoReview() {
    if (_isAutoReviewing) {
      _autoReviewTimer?.cancel();
      _autoReviewTimer = null;
      _isAutoReviewing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoReviewTimer?.cancel();
    super.dispose();
  }
}
