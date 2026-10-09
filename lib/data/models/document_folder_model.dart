import 'content_item.dart';

class FolderPickerContent {
  FolderPickerContent({
    required this.item,
    this.lessonName,
    this.topicName,
  });

  final ContentItem item;
  final String? lessonName;
  final String? topicName;
}

class DocumentFolder {
  DocumentFolder({
    required this.id,
    required this.name,
    required this.order,
    this.parentId,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int order;
  final int? parentId;
  final DateTime createdAt;

  factory DocumentFolder.fromMap(Map<String, Object?> map) {
    return DocumentFolder(
      id: map['id'] as int,
      name: map['ad'] as String,
      order: map['sira'] as int? ?? 0,
      parentId: map['parent_id'] as int?,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
    );
  }
}
