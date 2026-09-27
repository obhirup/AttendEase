enum RoundingMode {
  cut('CUT', 'Truncate'),
  up('UP', 'Round Up'),
  halfUp('5/4', 'Round 5/4');

  final String label;
  final String description;

  const RoundingMode(this.label, this.description);

  static RoundingMode fromString(String? name) {
    if (name == null) return RoundingMode.halfUp;
    return RoundingMode.values.firstWhere(
      (e) => e.name == name || e.label == name,
      orElse: () => RoundingMode.halfUp,
    );
  }
}

enum DecimalSetting {
  f('F', null),
  d4('4', 4),
  d3('3', 3),
  d2('2', 2),
  d1('1', 1),
  d0('0', 0),
  add2('ADD2', 2);

  final String label;
  final int? decimalPlaces;

  const DecimalSetting(this.label, this.decimalPlaces);

  static DecimalSetting fromString(String? name) {
    if (name == null) return DecimalSetting.f;
    return DecimalSetting.values.firstWhere(
      (e) => e.name == name || e.label == name,
      orElse: () => DecimalSetting.f,
    );
  }
}
