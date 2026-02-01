class ContentItem {
  ContentItem({
    required this.id,
    required this.lessonId,
    required this.topicId,
    required this.name,
    required this.type,
    required this.path,
    required this.order,
    required this.createdAt,
    required this.archived,
  });

  final int id;
  final int lessonId;
  final int? topicId;
  final String name;
  final String type;
  final String path;
  final int order;
  final DateTime createdAt;
  final bool archived;

  factory ContentItem.fromMap(Map<String, Object?> map) {
    return ContentItem(
      id: map['id'] as int,
      lessonId: map['ders_id'] as int,
      topicId: map['konu_id'] as int?,
      name: map['ad'] as String,
      type: map['tur'] as String,
      path: map['dosya_yolu'] as String,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      archived: (map['arsiv'] as int? ?? 0) == 1,
    );
  }
}

