class TagModel {
  TagModel({
    required this.id,
    required this.name,
    this.color,
  });

  final int id;
  final String name;
  final int? color;

  factory TagModel.fromMap(Map<String, Object?> map) {
    return TagModel(
      id: map['id'] as int,
      name: map['ad'] as String,
      color: map['renk'] as int?,
    );
  }
}


