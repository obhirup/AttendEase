enum AbsenceReason {
  medical('Medical Leave', 'Doctor visit, illness, or health rest'),
  officialDuty('Extracurricular / Duty', 'College festival, sports team, official events'),
  personal('Personal', 'Family commitment, travel, or personal task'),
  other('Other', 'Unforeseen circumstances');

  final String label;
  final String description;

  const AbsenceReason(this.label, this.description);

  static AbsenceReason fromString(String? val) {
    if (val == null) return AbsenceReason.other;
    return AbsenceReason.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AbsenceReason.other,
    );
  }
}
