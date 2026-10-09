class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.recipientRole,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
    this.readAt,
    required this.isRead,
    required this.dedupKey,
  });

  final int id;
  final String recipientRole;
  final int recipientId;
  final String title;
  final String body;
  final String type;
  final String? referenceType;
  final int? referenceId;
  final String createdAt;
  final String? readAt;
  final bool isRead;
  final String dedupKey;

  static InAppNotification fromMap(Map<String, Object?> row) {
    final status = row['durum'] as String? ?? 'okunmadi';
    return InAppNotification(
      id: row['id'] as int,
      recipientRole: row['alici_rol'] as String,
      recipientId: row['alici_id'] as int,
      title: row['baslik'] as String,
      body: row['icerik'] as String? ?? '',
      type: row['tur'] as String,
      referenceType: row['referans_tur'] as String?,
      referenceId: row['referans_id'] as int?,
      createdAt: row['olusturma_tarihi'] as String,
      readAt: row['okunma_tarihi'] as String?,
      isRead: status == 'okundu',
      dedupKey: row['dedup_anahtar'] as String,
    );
  }
}
