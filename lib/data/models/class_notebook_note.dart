class ClassNotebookNote {
  ClassNotebookNote({
    required this.id,
    required this.classId,
    required this.text,
    required this.noteDate,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int classId;
  final String text;
  /// Calendar date `YYYY-MM-DD`.
  final String noteDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ClassNotebookNote.fromMap(Map<String, Object?> map) {
    final updated = map['guncelleme_tarihi'] as String?;
    return ClassNotebookNote(
      id: map['id'] as int,
      classId: map['sinif_id'] as int,
      text: map['metin'] as String,
      noteDate: map['not_tarihi'] as String,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      updatedAt: updated == null ? null : DateTime.parse(updated),
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'sinif_id': classId,
      'metin': text,
      'not_tarihi': noteDate,
      'olusturma_tarihi': createdAt.toIso8601String(),
      'guncelleme_tarihi': updatedAt?.toIso8601String(),
    };
  }
}
