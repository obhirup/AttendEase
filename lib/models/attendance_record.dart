import 'absence_reason.dart';

enum AttendanceStatus {
  notMarked('Not Marked', 'Pending verification'),
  present('Present', 'Attended on time'),
  late('Late', 'Attended late'),
  absent('Absent', 'Did not attend');

  final String label;
  final String description;

  const AttendanceStatus(this.label, this.description);

  static AttendanceStatus fromString(String? val) {
    if (val == null) return AttendanceStatus.notMarked;
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AttendanceStatus.notMarked,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String timetableId;
  final String classSessionId;
  final String date; // YYYY-MM-DD
  final String subject;
  final AttendanceStatus status;
  final double points; // 1.0 to 5.0
  final double lateWeight; // e.g. 0.5
  final AbsenceReason? absenceReason;
  final String note;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.timetableId,
    required this.classSessionId,
    required this.date,
    required this.subject,
    this.status = AttendanceStatus.notMarked,
    this.points = 1.0,
    this.lateWeight = 0.5,
    this.absenceReason,
    this.note = '',
    required this.updatedAt,
  });

  /// Attended points earned
  double get earnedPoints {
    switch (status) {
      case AttendanceStatus.present:
        return points;
      case AttendanceStatus.late:
        return points * lateWeight;
      case AttendanceStatus.absent:
      case AttendanceStatus.notMarked:
        return 0.0;
    }
  }

  /// Total points possible for conducted session
  double get maxPoints {
    if (status == AttendanceStatus.notMarked) return 0.0;
    return points;
  }

  bool get isConducted => status != AttendanceStatus.notMarked;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timetableId': timetableId,
    'classSessionId': classSessionId,
    'date': date,
    'subject': subject,
    'status': status.name,
    'points': points,
    'lateWeight': lateWeight,
    'absenceReason': absenceReason?.name,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id'] as String,
    timetableId: json['timetableId'] as String? ?? '',
    classSessionId: json['classSessionId'] as String? ?? '',
    date: json['date'] as String,
    subject: json['subject'] as String? ?? '',
    status: AttendanceStatus.fromString(json['status'] as String?),
    points: (json['points'] as num?)?.toDouble() ?? 1.0,
    lateWeight: (json['lateWeight'] as num?)?.toDouble() ?? 0.5,
    absenceReason: json['absenceReason'] != null
        ? AbsenceReason.fromString(json['absenceReason'] as String)
        : null,
    note: json['note'] as String? ?? '',
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  AttendanceRecord copyWith({
    String? id,
    String? timetableId,
    String? classSessionId,
    String? date,
    String? subject,
    AttendanceStatus? status,
    double? points,
    double? lateWeight,
    AbsenceReason? absenceReason,
    bool clearAbsenceReason = false,
    String? note,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      timetableId: timetableId ?? this.timetableId,
      classSessionId: classSessionId ?? this.classSessionId,
      date: date ?? this.date,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      points: points ?? this.points,
      lateWeight: lateWeight ?? this.lateWeight,
      absenceReason: clearAbsenceReason ? null : (absenceReason ?? this.absenceReason),
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
