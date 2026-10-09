import 'package:flutter/material.dart';

/// Block-based Lesson Builder data models.
/// Maps to: Course=Class, Section=Lesson, Step=Topic, Block=Content

enum BlockType {
  text,
  pdf,
  ppt,
  word,
  image,
  video,
  audio,
  webLink,
  homework,
  question,
  exam,
}

extension BlockTypeX on BlockType {
  String get code {
    switch (this) {
      case BlockType.text:
        return 'text';
      case BlockType.pdf:
        return 'pdf';
      case BlockType.ppt:
        return 'ppt';
      case BlockType.word:
        return 'word';
      case BlockType.image:
        return 'image';
      case BlockType.video:
        return 'video';
      case BlockType.audio:
        return 'audio';
      case BlockType.webLink:
        return 'link';
      case BlockType.homework:
        return 'homework';
      case BlockType.question:
        return 'question';
      case BlockType.exam:
        return 'exam';
    }
  }

  String get displayName {
    switch (this) {
      case BlockType.text:
        return 'Metin';
      case BlockType.pdf:
        return 'PDF';
      case BlockType.ppt:
        return 'Sunum';
      case BlockType.word:
        return 'Word';
      case BlockType.image:
        return 'Görsel';
      case BlockType.video:
        return 'Video';
      case BlockType.audio:
        return 'Ses';
      case BlockType.webLink:
        return 'Web Link';
      case BlockType.homework:
        return 'Ödev';
      case BlockType.question:
        return 'Soru';
      case BlockType.exam:
        return 'Sınav';
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.text:
        return Icons.text_fields;
      case BlockType.pdf:
        return Icons.picture_as_pdf;
      case BlockType.ppt:
        return Icons.slideshow;
      case BlockType.word:
        return Icons.description;
      case BlockType.image:
        return Icons.image;
      case BlockType.video:
        return Icons.video_library;
      case BlockType.audio:
        return Icons.audiotrack;
      case BlockType.webLink:
        return Icons.link;
      case BlockType.homework:
        return Icons.assignment;
      case BlockType.question:
        return Icons.quiz;
      case BlockType.exam:
        return Icons.assignment_turned_in;
    }
  }

  static BlockType fromCode(String code) {
    return BlockType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BlockType.text,
    );
  }
}

/// Represents a block in the lesson builder (maps to ContentItem)
class LessonBlock {
  LessonBlock({
    required this.id,
    required this.type,
    required this.path,
    this.title,
    this.description,
    required this.order,
  });

  final int id;
  final BlockType type;
  final String path; // For text: content; for files: path; for link: URL
  final String? title;
  final String? description;
  final int order;

  LessonBlock copyWith({
    int? id,
    BlockType? type,
    String? path,
    String? title,
    String? description,
    int? order,
  }) {
    return LessonBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}
