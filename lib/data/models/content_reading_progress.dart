class ContentReadingProgress {
  ContentReadingProgress({
    required this.contentId,
    required this.lastPage,
    required this.updatedAt,
    this.extraJson,
  });

  final int contentId;
  final int lastPage;
  final DateTime updatedAt;
  final String? extraJson;

  factory ContentReadingProgress.fromMap(Map<String, Object?> map) {
    return ContentReadingProgress(
      contentId: map['icerik_id'] as int,
      lastPage: map['son_sayfa'] as int? ?? 1,
      updatedAt: DateTime.parse(map['guncelleme_tarihi'] as String),
      extraJson: map['ekstra_json'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'icerik_id': contentId,
      'son_sayfa': lastPage,
      'guncelleme_tarihi': updatedAt.toIso8601String(),
      'ekstra_json': extraJson,
    };
  }
}
