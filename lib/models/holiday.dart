class Holiday {
  final String id;
  final String date; // YYYY-MM-DD
  final String title;
  final bool isPublic;
  final bool isCustom;

  const Holiday({
    required this.id,
    required this.date,
    required this.title,
    this.isPublic = false,
    this.isCustom = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'title': title,
    'isPublic': isPublic,
    'isCustom': isCustom,
  };

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    id: json['id'] as String,
    date: json['date'] as String,
    title: json['title'] as String? ?? 'Holiday',
    isPublic: json['isPublic'] as bool? ?? false,
    isCustom: json['isCustom'] as bool? ?? true,
  );
}
