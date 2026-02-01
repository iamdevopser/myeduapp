class TopicModel {
  TopicModel({
    required this.id,
    required this.lessonId,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  final int id;
  final int lessonId;
  final String name;
  final int order;
  final DateTime createdAt;

  factory TopicModel.fromMap(Map<String, Object?> map) {
    return TopicModel(
      id: map['id'] as int,
      lessonId: map['ders_id'] as int,
      name: map['ad'] as String,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
    );
  }
}



