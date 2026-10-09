class ClassModel {
  ClassModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;

  factory ClassModel.fromMap(Map<String, Object?> map) {
    return ClassModel(
      id: map['id'] as int,
      name: map['ad'] as String,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClassModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}



