class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String problematique; // Référence à la problématique (title de ChallengeProblematique)
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.problematique,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON (Supabase response)
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      problematique: json['problematique'] as String,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'problematique': problematique,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with modified fields
  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? problematique,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      problematique: problematique ?? this.problematique,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, problematique: $problematique, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
