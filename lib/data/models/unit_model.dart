class UnitModel {
  UnitModel({
    required this.id,
    required this.lessonId,
    required this.name,
    required this.number,
    required this.order,
    required this.createdAt,
    this.imagePath,
  });

  final int id;
  final int lessonId;
  final String name;
  final int number;
  final int order;
  final DateTime createdAt;
  final String? imagePath;

  factory UnitModel.fromMap(Map<String, Object?> map) {
    return UnitModel(
      id: map['id'] as int,
      lessonId: map['ders_id'] as int,
      name: map['ad'] as String,
      number: map['numara'] as int? ?? 1,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      imagePath: map['resim_yolu'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnitModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
