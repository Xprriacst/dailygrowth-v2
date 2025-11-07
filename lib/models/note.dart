class Note {
  final String? id;
  final String userId;
  final String? challengeId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? challengeTitle;

  Note({
    this.id,
    required this.userId,
    this.challengeId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.challengeTitle,
  });

  // Create from JSON (Supabase response)
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      challengeTitle: json['challenge_title'] as String?,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (challengeId != null) 'challenge_id': challengeId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (challengeTitle != null) 'challenge_title': challengeTitle,
    };
  }

  // Copy with method for updates
  Note copyWith({
    String? id,
    String? userId,
    String? challengeId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? challengeTitle,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      challengeTitle: challengeTitle ?? this.challengeTitle,
    );
  }
}
