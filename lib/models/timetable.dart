import 'class_session.dart';

class Timetable {
  final String id;
  final String name;
  final bool isArchived;
  final DateTime createdAt;
  final List<ClassSession> sessions;

  const Timetable({
    required this.id,
    required this.name,
    this.isArchived = false,
    required this.createdAt,
    this.sessions = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  factory Timetable.fromJson(Map<String, dynamic> json) => Timetable(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'College Routine',
    isArchived: json['isArchived'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    sessions: (json['sessions'] as List<dynamic>?)
            ?.map((e) => ClassSession.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Timetable copyWith({
    String? id,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    List<ClassSession>? sessions,
  }) {
    return Timetable(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      sessions: sessions ?? this.sessions,
    );
  }
}
