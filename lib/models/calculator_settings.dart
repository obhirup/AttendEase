import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'calculator_config.dart';
import 'calculator_enums.dart';

class CalculatorSettings {
  final double taxRate;
  final CalculatorModel activeModel;
  final RoundingMode roundingMode;
  final DecimalSetting decimalSetting;
  final ThemeMode themeMode;
  final AppColorOption activeColor;

  const CalculatorSettings({
    this.taxRate = 5.0,
    this.activeModel = CalculatorModel.mj120d,
    this.roundingMode = RoundingMode.halfUp,
    this.decimalSetting = DecimalSetting.f,
    this.themeMode = ThemeMode.system,
    this.activeColor = AppColorOption.irisPastel,
  });

  Map<String, dynamic> toJson() => {
    'taxRate': taxRate,
    'activeModel': activeModel.name,
    'roundingMode': roundingMode.name,
    'decimalSetting': decimalSetting.name,
    'themeMode': themeMode.name,
    'activeColor': activeColor.name,
  };

  factory CalculatorSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode mode = ThemeMode.system;
    if (json['themeMode'] == 'light') mode = ThemeMode.light;
    if (json['themeMode'] == 'dark') mode = ThemeMode.dark;

    return CalculatorSettings(
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 5.0,
      activeModel: CalculatorModel.fromString(json['activeModel'] as String?),
      roundingMode: RoundingMode.fromString(json['roundingMode'] as String?),
      decimalSetting: DecimalSetting.fromString(json['decimalSetting'] as String?),
      themeMode: mode,
      activeColor: AppColorOption.fromName(json['activeColor'] as String?),
    );
  }

  CalculatorSettings copyWith({
    double? taxRate,
    CalculatorModel? activeModel,
    RoundingMode? roundingMode,
    DecimalSetting? decimalSetting,
    ThemeMode? themeMode,
    AppColorOption? activeColor,
  }) {
    return CalculatorSettings(
      taxRate: taxRate ?? this.taxRate,
      activeModel: activeModel ?? this.activeModel,
      roundingMode: roundingMode ?? this.roundingMode,
      decimalSetting: decimalSetting ?? this.decimalSetting,
      themeMode: themeMode ?? this.themeMode,
      activeColor: activeColor ?? this.activeColor,
    );
  }
}
