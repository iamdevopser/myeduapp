class TeacherRecentActivity {
  TeacherRecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.targetType,
    this.targetId,
    this.extraData,
  });

  final int id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? targetType;
  final int? targetId;
  final String? extraData;

  factory TeacherRecentActivity.fromMap(Map<String, Object?> map) {
    return TeacherRecentActivity(
      id: map['id'] as int,
      type: map['tur'] as String,
      title: map['baslik'] as String,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      targetType: map['hedef_tur'] as String?,
      targetId: map['hedef_id'] as int?,
      extraData: map['ek_veri'] as String?,
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'tur': type,
      'baslik': title,
      'hedef_tur': targetType,
      'hedef_id': targetId,
      'ek_veri': extraData,
      'olusturma_tarihi': createdAt.toIso8601String(),
    };
  }
}
