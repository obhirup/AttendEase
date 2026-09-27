enum CalculatorModel {
  mj120d('Casio MJ-120D', '12-Digit Desktop with Tax, MU, & 150-Step Check'),
  mj12d('Casio MJ-12D', '12-Digit Desktop with MU & 150-Step Check');

  final String displayName;
  final String description;

  const CalculatorModel(this.displayName, this.description);

  static CalculatorModel fromString(String? val) {
    if (val == null) return CalculatorModel.mj120d;
    return CalculatorModel.values.firstWhere(
      (e) => e.name == val || e.displayName == val,
      orElse: () => CalculatorModel.mj120d,
    );
  }
}

class CalculatorConfig {
  final CalculatorModel model;
  final String name;
  final String subtitle;
  final bool hasTaxKeys;
  final bool hasMarkUp;
  final int maxSteps;
  final int maxDigits;

  const CalculatorConfig({
    required this.model,
    required this.name,
    required this.subtitle,
    required this.hasTaxKeys,
    required this.hasMarkUp,
    this.maxSteps = 150,
    this.maxDigits = 12,
  });

  static const CalculatorConfig mj120d = CalculatorConfig(
    model: CalculatorModel.mj120d,
    name: 'Casio MJ-120D',
    subtitle: '12-Digit Desktop with Tax, MU, & 150-Step Check',
    hasTaxKeys: true,
    hasMarkUp: true,
    maxSteps: 150,
    maxDigits: 12,
  );

  static const CalculatorConfig mj12d = CalculatorConfig(
    model: CalculatorModel.mj12d,
    name: 'Casio MJ-12D',
    subtitle: '12-Digit Desktop with MU & 150-Step Check',
    hasTaxKeys: false,
    hasMarkUp: true,
    maxSteps: 150,
    maxDigits: 12,
  );

  static CalculatorConfig forModel(CalculatorModel model) {
    switch (model) {
      case CalculatorModel.mj120d:
        return mj120d;
      case CalculatorModel.mj12d:
        return mj12d;
    }
  }
}
