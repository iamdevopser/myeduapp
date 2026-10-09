class LessonModel {
  LessonModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.order,
    required this.createdAt,
    this.academicYear = '',
    this.imagePath,
    this.className,
    this.unitCount = 0,
    this.topicCount = 0,
  });

  final int id;
  final int classId;
  final String name;
  final int order;
  final DateTime createdAt;
  final String academicYear;
  final String? imagePath;
  final String? className;
  final int unitCount;
  final int topicCount;

  factory LessonModel.fromMap(Map<String, Object?> map) {
    return LessonModel(
      id: map['id'] as int,
      classId: map['sinif_id'] as int,
      name: map['ad'] as String,
      order: map['sira'] as int,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      academicYear: map['akademik_yil'] as String? ?? '',
      imagePath: map['resim_yolu'] as String?,
      className: map['sinif_ad'] as String?,
      unitCount: (map['unite_sayisi'] as num?)?.toInt() ?? 0,
      topicCount: (map['konu_sayisi'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LessonModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class SubjectSummary {
  SubjectSummary({
    required this.name,
    this.imagePath,
    this.courseCount = 0,
    this.unitCount = 0,
    this.topicCount = 0,
  });

  final String name;
  final String? imagePath;
  final int courseCount;
  final int unitCount;
  final int topicCount;
}



