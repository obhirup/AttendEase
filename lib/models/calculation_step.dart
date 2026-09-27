class CalculationStep {
  final int stepNumber;
  final String operator; // '', '+', '-', '×', '÷', '=', '%', 'MU', 'TAX+', 'TAX-', '√', etc.
  final double inputValue;
  final String inputDisplay;
  final double resultAfterStep;
  final String resultDisplay;
  final bool isConstant;
  final String notes;

  const CalculationStep({
    required this.stepNumber,
    required this.operator,
    required this.inputValue,
    required this.inputDisplay,
    required this.resultAfterStep,
    required this.resultDisplay,
    this.isConstant = false,
    this.notes = '',
  });

  CalculationStep copyWith({
    int? stepNumber,
    String? operator,
    double? inputValue,
    String? inputDisplay,
    double? resultAfterStep,
    String? resultDisplay,
    bool? isConstant,
    String? notes,
  }) {
    return CalculationStep(
      stepNumber: stepNumber ?? this.stepNumber,
      operator: operator ?? this.operator,
      inputValue: inputValue ?? this.inputValue,
      inputDisplay: inputDisplay ?? this.inputDisplay,
      resultAfterStep: resultAfterStep ?? this.resultAfterStep,
      resultDisplay: resultDisplay ?? this.resultDisplay,
      isConstant: isConstant ?? this.isConstant,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'operator': operator,
    'inputValue': inputValue,
    'inputDisplay': inputDisplay,
    'resultAfterStep': resultAfterStep,
    'resultDisplay': resultDisplay,
    'isConstant': isConstant,
    'notes': notes,
  };

  factory CalculationStep.fromJson(Map<String, dynamic> json) {
    return CalculationStep(
      stepNumber: json['stepNumber'] as int? ?? 1,
      operator: json['operator'] as String? ?? '',
      inputValue: (json['inputValue'] as num?)?.toDouble() ?? 0.0,
      inputDisplay: json['inputDisplay'] as String? ?? '0',
      resultAfterStep: (json['resultAfterStep'] as num?)?.toDouble() ?? 0.0,
      resultDisplay: json['resultDisplay'] as String? ?? '0',
      isConstant: json['isConstant'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Step $stepNumber: $operator $inputDisplay = $resultDisplay';
  }
}
