class TopicModel {
  TopicModel({
    required this.id,
    required this.lessonId,
    required this.name,
    required this.order,
    required this.createdAt,
    this.unitId,
    this.imagePath,
  });

  final int id;
  final int lessonId;
  final int? unitId;
  final String name;
  final int order;
  final DateTime createdAt;
  final String? imagePath;

  factory TopicModel.fromMap(Map<String, Object?> map) {
    return TopicModel(
      id: map['id'] as int,
      lessonId: map['ders_id'] as int,
      unitId: map['unite_id'] as int?,
      name: map['ad'] as String,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      imagePath: map['resim_yolu'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TopicModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}



