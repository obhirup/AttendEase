class ClassSession {
  final String id;
  final String subject;
  final String room;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double defaultPoints; // 1.0 to 5.0
  final int colorValue;

  const ClassSession({
    required this.id,
    required this.subject,
    this.room = '',
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.defaultPoints = 1.0,
    this.colorValue = 0xFF818CF8, // Iris pastel purple default
  });

  String get timeFormatted {
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final sH = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
    final sM = startMinute.toString().padLeft(2, '0');

    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final eH = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
    final eM = endMinute.toString().padLeft(2, '0');

    return '$sH:$sM $startPeriod - $eH:$eM $endPeriod';
  }

  String get startTimeFormatted {
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final sH = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
    final sM = startMinute.toString().padLeft(2, '0');
    return '$sH:$sM $startPeriod';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'room': room,
    'dayOfWeek': dayOfWeek,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'defaultPoints': defaultPoints,
    'colorValue': colorValue,
  };

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: json['id'] as String,
    subject: json['subject'] as String? ?? 'Untitled Class',
    room: json['room'] as String? ?? '',
    dayOfWeek: json['dayOfWeek'] as int? ?? 1,
    startHour: json['startHour'] as int? ?? 9,
    startMinute: json['startMinute'] as int? ?? 0,
    endHour: json['endHour'] as int? ?? 10,
    endMinute: json['endMinute'] as int? ?? 0,
    defaultPoints: (json['defaultPoints'] as num?)?.toDouble() ?? 1.0,
    colorValue: json['colorValue'] as int? ?? 0xFFCC5A27,
  );

  ClassSession copyWith({
    String? id,
    String? subject,
    String? room,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    double? defaultPoints,
    int? colorValue,
  }) {
    return ClassSession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
