import 'dart:convert';

enum ExamQuestionType { text, image, multipleChoice }

class ExamQuestion {
  ExamQuestion({
    required this.type,
    required this.value,
    this.options = const [],
    this.correctOptionIndex,
    this.audioPath,
    this.tagIds = const [],
  });

  final ExamQuestionType type;
  final String value;
  final List<String> options;
  final int? correctOptionIndex;
  final String? audioPath;
  final List<int> tagIds;

  String get typeCode {
    switch (type) {
      case ExamQuestionType.text:
        return 'text';
      case ExamQuestionType.image:
        return 'image';
      case ExamQuestionType.multipleChoice:
        return 'mcq';
    }
  }

  String? toOptionsJson() {
    if (type != ExamQuestionType.multipleChoice || options.isEmpty) {
      return null;
    }
    return jsonEncode(options);
  }
}

