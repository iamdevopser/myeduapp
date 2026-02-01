import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart';

import '../data/models/content_with_tags.dart';
import '../data/models/exam_question.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/pdf_service.dart';
import '../data/models/topic_model.dart';
import 'app_viewer_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                const _FocusSearchIntent(),
          },
          child: Actions(
            actions: {
              _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
                onInvoke: (intent) {
                  _searchFocus.requestFocus();
                  return null;
                },
              ),
            },
            child: Scaffold(
          appBar: AppBar(
            title: Text(strings.t('contents')),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: strings.t('goHome'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              IconButton(
                icon: const Icon(Icons.apps),
                tooltip: strings.t('goToApp'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AppViewerScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: strings.t('exportPdf'),
                onPressed: () async {
                  final filePath = await FilePicker.platform.saveFile(
                    dialogTitle: strings.t('exportPdf'),
                    fileName: 'lesson_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    allowedExtensions: ['pdf'],
                    type: FileType.custom,
                  );
                  if (filePath != null) {
                    try {
                      await state.exportPdf(
                        filePath,
                        PdfLabels(
                          classLabel: strings.t('selectClass'),
                          lessonLabel: strings.t('selectLesson'),
                          contentsTitle: strings.t('contents'),
                          emptyMessage: strings.t('noContents'),
                        ),
                      );
                      _showSnack(context, strings.t('pdfSaved'));
                    } catch (_) {
                      _showSnack(context, strings.t('exportPdfFailed'));
                    }
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.selectedClass?.name ?? ''} / ${state.selectedLesson?.name ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButton<TopicModel>(
                  isExpanded: true,
                  value: state.selectedTopic,
                  hint: Text(strings.t('selectTopic')),
                  items: state.topics
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => state.selectTopic(value),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _showMoveAllDialog(context, state);
                        },
                        icon: const Icon(Icons.drive_file_move),
                        label: Text(strings.t('moveAll')),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await _confirmBulkDelete(context);
                          if (confirmed != true) return;
                          await state.deleteFilteredContents();
                        },
                        icon: const Icon(Icons.delete_sweep),
                        label: Text(strings.t('bulkDelete')),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _showAddContentSheet(context, state),
                        icon: const Icon(Icons.add),
                        label: Text(strings.t('add')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(strings.t('showArchived')),
                  value: state.showArchived,
                  onChanged: (value) => state.toggleShowArchived(value),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: strings.t('search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  focusNode: _searchFocus,
                  onChanged: state.setSearchQuery,
                ),
                const SizedBox(height: 12),
                if (state.tags.isNotEmpty) ...[
                  Text(strings.t('filterByTag')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: state.tags
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag.name),
                            selected: state.filterTagIds.contains(tag.id),
                            backgroundColor: tag.color == null
                                ? null
                                : Color(tag.color!),
                            onSelected: (_) => state.toggleFilterTag(tag.id),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: state.filteredContents.isEmpty
                      ? Center(child: Text(strings.t('noContents')))
                      : _buildContentList(context, state),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmBulkDelete(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('bulkDelete')),
        content: Text(strings.t('bulkDeleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(BuildContext context, AppState state) {
    final isFiltering =
        state.searchQuery.trim().isNotEmpty || state.filterTagIds.isNotEmpty;
    if (isFiltering) {
      return ListView.builder(
        itemCount: state.filteredContents.length,
        itemBuilder: (context, index) {
          final item = state.filteredContents[index];
          return _ContentTile(
            key: ValueKey(item.content.id),
            item: item,
            onEditTags: () => _showTagEditor(context, state, item),
            onDelete: () => state.deleteContent(item),
            onOpen: () => state.openContent(item),
            isFavorite: state.favoriteContentIds.contains(item.content.id),
            onToggleFavorite: () => state.toggleFavorite(item),
            onMove: () => _showMoveDialog(context, state, item),
            onArchive: () => state.toggleArchive(item),
          );
        },
      );
    }
    return ReorderableListView.builder(
      itemCount: state.filteredContents.length,
      onReorder: state.reorderContents,
      itemBuilder: (context, index) {
        final item = state.filteredContents[index];
        return _ContentTile(
          key: ValueKey(item.content.id),
          item: item,
          onEditTags: () => _showTagEditor(context, state, item),
          onDelete: () => state.deleteContent(item),
          onOpen: () => state.openContent(item),
          isFavorite: state.favoriteContentIds.contains(item.content.id),
          onToggleFavorite: () => state.toggleFavorite(item),
          onMove: () => _showMoveDialog(context, state, item),
          onArchive: () => state.toggleArchive(item),
        );
      },
    );
  }

  Future<void> _showAddContentSheet(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(strings.t('addFolder')),
              onTap: () async {
                Navigator.of(context).pop();
                final folder = await FilePicker.platform.getDirectoryPath();
                if (folder != null) {
                  await state.addContentFromFolder(folder);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(strings.t('addFile')),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf',
                    'doc',
                    'docx',
                    'jpg',
                    'jpeg',
                    'png',
                  ],
                );
                if (result != null) {
                  final paths = result.files
                      .map((file) => file.path)
                      .whereType<String>()
                      .toList();
                  if (paths.isNotEmpty) {
                    try {
                      await state.addContentFiles(paths);
                    } catch (_) {
                      _showSnack(context, strings.t('fileImportFailed'));
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: Text(strings.t('addVideo')),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['mp4', 'avi'],
                );
                if (result != null) {
                  final paths = result.files
                      .map((file) => file.path)
                      .whereType<String>()
                      .toList();
                  if (paths.isNotEmpty) {
                    try {
                      await state.addContentFiles(paths);
                    } catch (_) {
                      _showSnack(context, strings.t('fileImportFailed'));
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(strings.t('addAudio')),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['mp3', 'wav'],
                );
                if (result != null) {
                  final paths = result.files
                      .map((file) => file.path)
                      .whereType<String>()
                      .toList();
                  if (paths.isNotEmpty) {
                    try {
                      await state.addContentFiles(paths);
                    } catch (_) {
                      _showSnack(context, strings.t('fileImportFailed'));
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(strings.t('addLink')),
              onTap: () async {
                Navigator.of(context).pop();
                await _showAddLinkDialog(context, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(strings.t('addExam')),
              onTap: () async {
                Navigator.of(context).pop();
                await _showAddExamDialog(context, state);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddExamDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final questions = <ExamQuestion>[];
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(strings.t('addExam')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: strings.t('examTitle')),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(strings.t('questions')),
                ),
                const SizedBox(height: 8),
                if (questions.isEmpty)
                  Text(strings.t('noQuestions'))
                else
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final item = questions[index];
                        return ListTile(
                          dense: true,
                          title: Text(_questionLabel(strings, item)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated =
                                      await _showAddQuestionDialog(
                                    context,
                                    state: state,
                                    title: strings.t('editQuestion'),
                                    initial: item,
                                  );
                                  if (updated != null) {
                                    setState(() {
                                      questions[index] = updated;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    questions.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final question = await _showAddQuestionDialog(
                        context,
                        state: state,
                        title: strings.t('addQuestion'),
                      );
                      if (question != null) {
                        setState(() {
                          questions.add(question);
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addQuestion')),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bulk = await _showBulkQuestionDialog(context);
                      if (bulk.isNotEmpty) {
                        setState(() {
                          questions.addAll(
                            bulk.map(
                              (text) => ExamQuestion(
                                type: ExamQuestionType.text,
                                value: text,
                              ),
                            ),
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: Text(strings.t('addQuestionsBulk')),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected =
                          await _showPickFromBankDialog(context, state);
                      if (selected.isNotEmpty) {
                        setState(() {
                          questions.addAll(selected);
                        });
                      }
                    },
                    icon: const Icon(Icons.library_add),
                    label: Text(strings.t('addFromBank')),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('cancelSimple')),
            ),
            FilledButton(
              onPressed: () async {
                final title = nameController.text.trim();
                if (title.isEmpty) {
                  _showSnack(context, strings.t('invalidName'));
                  return;
                }
                if (questions.isEmpty) {
                  _showSnack(context, strings.t('noQuestions'));
                  return;
                }
                await state.addExamWithQuestions(
                  title: title,
                  questions: questions,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<ExamQuestion?> _showAddQuestionDialog(
    BuildContext context, {
    required String title,
    ExamQuestion? initial,
    required AppState state,
  }) async {
    final strings = AppLocalizations.of(context);
    final questionController =
        TextEditingController(text: initial?.value ?? '');
    final optionController = TextEditingController();
    final options = <String>[...(initial?.options ?? [])];
    int? correctOptionIndex = initial?.correctOptionIndex;
    var type = initial?.type ?? ExamQuestionType.text;
    String? imagePath = initial?.type == ExamQuestionType.image
        ? initial?.value
        : null;
    String? audioPath = initial?.audioPath;
    return showDialog<ExamQuestion>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
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
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      type = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (type == ExamQuestionType.text ||
                    type == ExamQuestionType.multipleChoice)
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
                            final copied = await state.copyExamImage(path);
                            if (copied != null) {
                              setState(() {
                                imagePath = copied;
                              });
                            }
                          }
                        },
                        child: Text(strings.t('questionImage')),
                      ),
                    ],
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
                        final copied = await state.copyExamImage(path);
                        if (copied != null) {
                          setState(() {
                            audioPath = copied;
                          });
                        }
                      }
                    },
                    child: const Text('Audio'),
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
                                  if (correctOptionIndex == index) {
                                    correctOptionIndex = null;
                                  } else if (correctOptionIndex != null &&
                                      correctOptionIndex! > index) {
                                    correctOptionIndex =
                                        correctOptionIndex! - 1;
                                  }
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
                          if (value.isEmpty) {
                            return;
                          }
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
                if (type == ExamQuestionType.image && imagePath == null) {
                  _showSnack(context, strings.t('questionImage'));
                  return;
                }
                if (type != ExamQuestionType.image &&
                    questionController.text.trim().isEmpty) {
                  _showSnack(context, strings.t('invalidName'));
                  return;
                }
                if (type == ExamQuestionType.multipleChoice &&
                    options.length < 2) {
                  _showSnack(context, strings.t('addOption'));
                  return;
                }
                if (type == ExamQuestionType.multipleChoice &&
                    correctOptionIndex == null) {
                  _showSnack(context, strings.t('addOption'));
                  return;
                }
                final value = type == ExamQuestionType.image
                    ? imagePath!
                    : questionController.text.trim();
                Navigator.of(context).pop(
                  ExamQuestion(
                    type: type,
                    value: value,
                    options: options,
                    correctOptionIndex: correctOptionIndex,
                    audioPath: audioPath,
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

  String _questionLabel(AppLocalizations strings, ExamQuestion question) {
    switch (question.type) {
      case ExamQuestionType.text:
        return '[${strings.t('textQuestion')}] ${question.value}';
      case ExamQuestionType.image:
        return '[${strings.t('imageQuestion')}] ${question.value}';
      case ExamQuestionType.multipleChoice:
        return '[${strings.t('multipleChoice')}] ${question.value}';
    }
  }

  Future<List<String>> _showBulkQuestionDialog(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('addQuestionsBulk')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: strings.t('questions')),
          minLines: 5,
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final pick = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['txt', 'csv', 'docx', 'pdf'],
              );
              final path = pick?.files.single.path;
              if (path == null) {
                return;
              }
              final lines = await _readQuestionsFromFile(path);
              if (context.mounted) {
                Navigator.of(context).pop(lines);
              }
            },
            child: Text(strings.t('addQuestionsFromFile')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(<String>[]),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final lines = controller.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.of(context).pop(lines);
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    return result ?? [];
  }

  Future<List<ExamQuestion>> _showPickFromBankDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final selected = <int>{};
    return (await showDialog<List<ExamQuestion>>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(strings.t('questionBank')),
            content: SizedBox(
              width: 420,
              height: 300,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: state.db.getBankQuestions(),
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return Text(strings.t('noQuestions'));
                  }
                  return StatefulBuilder(
                    builder: (context, setState) => ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final id = row['id'] as int;
                        final text = row['soru'] as String? ?? '';
                        final type = row['tur'] as String? ?? 'text';
                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            });
                          },
                          title: Text('[$type] $text'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(<ExamQuestion>[]),
                child: Text(strings.t('cancelSimple')),
              ),
              FilledButton(
                onPressed: () async {
                  final rows = await state.db.getBankQuestions();
                  final picked = rows
                      .where((row) => selected.contains(row['id'] as int))
                      .toList();
                  final result = <ExamQuestion>[];
                  for (final row in picked) {
                    final text = row['soru'] as String? ?? '';
                    final typeCode = row['tur'] as String? ?? 'text';
                    final optionsJson = row['secenekler'] as String?;
                    final correct = row['dogru_secenek'] as int?;
                    final options = optionsJson == null
                        ? <String>[]
                        : (jsonDecode(optionsJson) as List)
                            .map((e) => e.toString())
                            .toList();
                    final type = typeCode == 'mcq'
                        ? ExamQuestionType.multipleChoice
                        : ExamQuestionType.text;
                    result.add(
                      ExamQuestion(
                        type: type,
                        value: text,
                        options: options,
                        correctOptionIndex: correct,
                      ),
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(result);
                  }
                },
                child: Text(strings.t('save')),
              ),
            ],
          ),
        )) ??
        [];
  }

  Future<List<String>> _readQuestionsFromFile(String path) async {
    final extension = path.split('.').last.toLowerCase();
    if (extension == 'txt') {
      return _splitQuestions(await File(path).readAsString());
    }
    if (extension == 'csv') {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter().convert(content);
      return rows
          .map((row) => row.map((e) => e.toString()).join(' ').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (extension == 'docx') {
      return _extractQuestionsFromDocx(path);
    }
    if (extension == 'pdf') {
      return _extractQuestionsFromPdf(path);
    }
    return [];
  }

  Future<List<String>> _extractQuestionsFromDocx(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.files.firstWhere(
      (element) => element.name == 'word/document.xml',
      orElse: () => ArchiveFile('word/document.xml', 0, []),
    );
    if (file.isFile && file.content is List<int>) {
      final xmlString = String.fromCharCodes(file.content as List<int>);
      final document = XmlDocument.parse(xmlString);
      final textNodes = document.findAllElements('w:t');
      final text = textNodes.map((e) => e.text).join('\n');
      return _splitQuestions(text);
    }
    return [];
  }

  Future<List<String>> _extractQuestionsFromPdf(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    for (var i = 0; i < document.pages.count; i += 1) {
      buffer.writeln(extractor.extractText(startPageIndex: i));
    }
    document.dispose();
    return _splitQuestions(buffer.toString());
  }

  List<String> _splitQuestions(String text) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _showAddLinkDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('addLink')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: strings.t('linkTitle')),
            ),
            TextField(
              controller: urlController,
              decoration: InputDecoration(labelText: strings.t('linkUrl')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () async {
              await state.addWebLink(
                title: titleController.text,
                url: urlController.text,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showTagEditor(
    BuildContext context,
    AppState state,
    ContentWithTags item,
  ) async {
    final strings = AppLocalizations.of(context);
    final selectedIds = item.tags.map((e) => e.id).toSet();
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(strings.t('editTags')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: state.tags
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag.name),
                            selected: selectedIds.contains(tag.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedIds.add(tag.id);
                                } else {
                                  selectedIds.remove(tag.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: strings.t('addTag'),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          return;
                        }
                        await state.addTag(value);
                        controller.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('cancelSimple')),
            ),
            FilledButton(
              onPressed: () async {
                await state.updateContentTags(
                  item.content.id,
                  selectedIds.toList(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showMoveDialog(
    BuildContext context,
    AppState state,
    ContentWithTags item,
  ) async {
    final strings = AppLocalizations.of(context);
    TopicModel? selected = state.selectedTopic;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('move')),
        content: DropdownButton<TopicModel?>(
          isExpanded: true,
          value: selected,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(strings.t('selectTopic')),
            ),
            ...state.topics.map(
              (topic) => DropdownMenuItem(
                value: topic,
                child: Text(topic.name),
              ),
            ),
          ],
          onChanged: (value) {
            selected = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () async {
              await state.moveContentToTopic(item, selected);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showMoveAllDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    TopicModel? selected = state.selectedTopic;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('moveAll')),
        content: DropdownButton<TopicModel?>(
          isExpanded: true,
          value: selected,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(strings.t('selectTopic')),
            ),
            ...state.topics.map(
              (topic) => DropdownMenuItem(
                value: topic,
                child: Text(topic.name),
              ),
            ),
          ],
          onChanged: (value) {
            selected = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () async {
              await state.moveAllFilteredContentsToTopic(selected);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    super.key,
    required this.item,
    required this.onEditTags,
    required this.onDelete,
    required this.onOpen,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onMove,
    required this.onArchive,
  });

  final ContentWithTags item;
  final VoidCallback onEditTags;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMove;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListTile(
      key: key,
      title: Text(item.content.name),
      subtitle: Text(item.tags.map((e) => e.name).join(', ')),
      leading: const Icon(Icons.insert_drive_file),
      onTap: onOpen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            onPressed: onToggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: strings.t('archive'),
            onPressed: onArchive,
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            onPressed: onMove,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: strings.t('openFile'),
            onPressed: onOpen,
          ),
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: strings.t('editTags'),
            onPressed: onEditTags,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: strings.t('delete'),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

