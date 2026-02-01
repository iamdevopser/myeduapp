class LessonModel {
  LessonModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  final int id;
  final int classId;
  final String name;
  final int order;
  final DateTime createdAt;

  factory LessonModel.fromMap(Map<String, Object?> map) {
    return LessonModel(
      id: map['id'] as int,
      classId: map['sinif_id'] as int,
      name: map['ad'] as String,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
    );
  }
}



