import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/exam_question.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';

class QuestionBankScreen extends StatelessWidget {
  const QuestionBankScreen({super.key});

  static const routeName = '/question-bank';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('questionBank')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: strings.t('goHome'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          return FutureBuilder<List<Map<String, Object?>>>(
            future: state.db.getBankQuestions(),
            builder: (context, snapshot) {
              final questions = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final question =
                          await _showBankQuestionDialog(context, state);
                      if (question != null) {
                        final tagIdsJson = jsonEncode(question.tagIds);
                        await state.db.insertBankQuestion(
                          question: question.value,
                          type: question.typeCode,
                          optionsJson: question.toOptionsJson(),
                          correctOption: question.correctOptionIndex,
                          imagePath: question.type == ExamQuestionType.image
                              ? question.value
                              : null,
                          audioPath: question.audioPath,
                          tagIdsJson: tagIdsJson,
                        );
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addQuestion')),
                  ),
                  const SizedBox(height: 12),
                  if (questions.isEmpty)
                    Text(strings.t('noQuestions'))
                  else
                    ...questions.map((row) {
                      final id = row['id'] as int;
                      final text = row['soru'] as String? ?? '';
                      final type = row['tur'] as String? ?? 'text';
                      return Card(
                        child: ListTile(
                          title: Text('[$type] $text'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await state.db.deleteBankQuestion(id);
                              if (context.mounted) {
                                (context as Element).markNeedsBuild();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<ExamQuestion?> _showBankQuestionDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final questionController = TextEditingController();
    final optionController = TextEditingController();
    final options = <String>[];
    int? correctOptionIndex;
    var type = ExamQuestionType.text;
    String? imagePath;
    String? audioPath;
    final selectedTagIds = <int>{};
    return showDialog<ExamQuestion>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(strings.t('addQuestion')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ExamQuestionType>(
                  isExpanded: true,
                  value: type,
                  items: [
                    DropdownMenuItem(
                      value: ExamQuestionType.text,
                      child: Text(strings.t('textQuestion')),
                    ),
                    DropdownMenuItem(
                      value: ExamQuestionType.image,
                      child: Text(strings.t('imageQuestion')),
                    ),
                    DropdownMenuItem(
                      value: ExamQuestionType.multipleChoice,
                      child: Text(strings.t('multipleChoice')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      type = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (type != ExamQuestionType.image)
                  TextField(
                    controller: questionController,
                    decoration:
                        InputDecoration(labelText: strings.t('questionText')),
                  ),
                if (type == ExamQuestionType.image)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          imagePath ?? strings.t('questionImage'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png'],
                          );
                          final path = result?.files.single.path;
                          if (path != null) {
                            final copied = await state.copyToQuestionBank(path);
                            setState(() {
                              imagePath = copied;
                            });
                          }
                        },
                        child: Text(strings.t('questionImage')),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(strings.t('tags')),
                ),
                Wrap(
                  spacing: 8,
                  children: state.tags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag.name),
                          selected: selectedTagIds.contains(tag.id),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                selectedTagIds.add(tag.id);
                              } else {
                                selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['mp3', 'wav'],
                      );
                      final path = result?.files.single.path;
                      if (path != null) {
                        final copied = await state.copyToQuestionBank(path);
                        setState(() {
                          audioPath = copied;
                        });
                      }
                    },
                    child: Text('Audio'),
                  ),
                ),
                if (type == ExamQuestionType.multipleChoice) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(strings.t('options')),
                  ),
                  const SizedBox(height: 6),
                  if (options.isEmpty)
                    Text(strings.t('noQuestions'))
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            leading: Radio<int>(
                              value: index,
                              groupValue: correctOptionIndex,
                              onChanged: (value) {
                                setState(() {
                                  correctOptionIndex = value;
                                });
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  options.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  TextField(
                    controller: optionController,
                    decoration: InputDecoration(
                      labelText: strings.t('addOption'),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final value = optionController.text.trim();
                          if (value.isEmpty) return;
                          setState(() {
                            options.add(value);
                            optionController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('cancelSimple')),
            ),
            FilledButton(
              onPressed: () {
                final text = questionController.text.trim();
                if (type == ExamQuestionType.image && imagePath == null) {
                  return;
                }
                if (type != ExamQuestionType.image && text.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  ExamQuestion(
                    type: type,
                    value: type == ExamQuestionType.image ? imagePath! : text,
                    options: options,
                    correctOptionIndex: correctOptionIndex,
                    audioPath: audioPath,
                    tagIds: selectedTagIds.toList(),
                  ),
                );
              },
              child: Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}

