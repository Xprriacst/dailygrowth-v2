/// Note model for Google Keep-style notes functionality
/// 
/// Represents a user note with title, content, color, and pinned status
class Note {
  final String id;
  final String userId;
  final String? title;
  final String content;
  final String color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.color = 'default',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Note from JSON (Supabase response)
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      color: json['color'] as String? ?? 'default',
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Note to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'color': color,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Note with updated fields
  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: ${content.length} chars, color: $color, isPinned: $isPinned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Note &&
      other.id == id &&
      other.userId == userId &&
      other.title == title &&
      other.content == content &&
      other.color == color &&
      other.isPinned == isPinned &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      content.hashCode ^
      color.hashCode ^
      isPinned.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}

/// Available note colors for Google Keep-style UI
enum NoteColor {
  defaultColor('default', 'Défaut'),
  red('red', 'Rouge'),
  orange('orange', 'Orange'),
  yellow('yellow', 'Jaune'),
  green('green', 'Vert'),
  blue('blue', 'Bleu'),
  purple('purple', 'Violet'),
  pink('pink', 'Rose'),
  gray('gray', 'Gris');

  final String value;
  final String displayName;

  const NoteColor(this.value, this.displayName);

  static NoteColor fromString(String value) {
    return NoteColor.values.firstWhere(
      (color) => color.value == value,
      orElse: () => NoteColor.defaultColor,
    );
  }
}
