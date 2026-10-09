/// Sabit davranış tanımları (sınıf bağımsız katalog).
class StudentBehaviorDefinition {
  const StudentBehaviorDefinition({
    required this.code,
    required this.nameTr,
    required this.nameEn,
    required this.kind,
    required this.order,
  });

  static const String kindPositive = 'positive';
  static const String kindNeedsImprovement = 'needs_improvement';

  final String code;
  final String nameTr;
  final String nameEn;
  final String kind;
  final int order;

  String localizedName(String languageCode) {
    return languageCode == 'tr' ? nameTr : nameEn;
  }

  factory StudentBehaviorDefinition.fromMap(Map<String, Object?> map) {
    return StudentBehaviorDefinition(
      code: map['kod'] as String,
      nameTr: map['ad'] as String,
      nameEn: map['ad'] as String,
      kind: map['tur'] as String,
      order: map['sira'] as int,
    );
  }

  Map<String, Object> toDbRow() {
    return {
      'kod': code,
      'ad': nameTr,
      'tur': kind,
      'sira': order,
    };
  }
}

/// Başlangıç davranış listesi (DB seed ile senkron).
class StudentBehaviorCatalog {
  StudentBehaviorCatalog._();

  static const List<StudentBehaviorDefinition> defaults = [
    StudentBehaviorDefinition(
      code: 'active_participation',
      nameTr: 'Aktif katılım',
      nameEn: 'Active participation',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 1,
    ),
    StudentBehaviorDefinition(
      code: 'taking_responsibility',
      nameTr: 'Sorumluluk alma',
      nameEn: 'Taking responsibility',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 2,
    ),
    StudentBehaviorDefinition(
      code: 'cooperation',
      nameTr: 'İş birliği',
      nameEn: 'Cooperation',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 3,
    ),
    StudentBehaviorDefinition(
      code: 'helping_peer',
      nameTr: 'Arkadaşına yardımcı olma',
      nameEn: 'Helping a peer',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 4,
    ),
    StudentBehaviorDefinition(
      code: 'respectful_communication',
      nameTr: 'Saygılı iletişim',
      nameEn: 'Respectful communication',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 5,
    ),
    StudentBehaviorDefinition(
      code: 'following_rules',
      nameTr: 'Kurallara uyma',
      nameEn: 'Following rules',
      kind: StudentBehaviorDefinition.kindPositive,
      order: 6,
    ),
    StudentBehaviorDefinition(
      code: 'talking_in_class',
      nameTr: 'Derste konuşma',
      nameEn: 'Talking in class',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 7,
    ),
    StudentBehaviorDefinition(
      code: 'disrupting_lesson',
      nameTr: 'Dersi bölme',
      nameEn: 'Disrupting the lesson',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 8,
    ),
    StudentBehaviorDefinition(
      code: 'being_late',
      nameTr: 'Geç kalma',
      nameEn: 'Being late',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 9,
    ),
    StudentBehaviorDefinition(
      code: 'distracting',
      nameTr: 'Dikkat dağıtma',
      nameEn: 'Distracting others',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 10,
    ),
    StudentBehaviorDefinition(
      code: 'not_doing_homework',
      nameTr: 'Ödevini yapmama',
      nameEn: 'Not doing homework',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 11,
    ),
    StudentBehaviorDefinition(
      code: 'breaking_rules',
      nameTr: 'Kurallara uymama',
      nameEn: 'Breaking rules',
      kind: StudentBehaviorDefinition.kindNeedsImprovement,
      order: 12,
    ),
  ];
}
