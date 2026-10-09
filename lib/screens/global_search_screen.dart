import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/class_model.dart';
import '../data/models/content_item.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/app_navigation.dart';
import 'app_viewer_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  static const routeName = '/global-search';

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, Object?>> _results = [];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('search')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: strings.t('goHome'),
            onPressed: () async {
              final confirmed = await confirmLeavePage(context);
              if (confirmed && context.mounted) {
                popToSessionHome(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: strings.t('search')),
              onSubmitted: (_) => _runSearch(context),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _runSearch(context),
              child: Text(strings.t('search')),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final row = _results[index];
                  final name = row['ad'] as String? ?? '';
                  final lessonName = row['ders_ad'] as String? ?? '';
                  final className = row['sinif_ad'] as String? ?? '';
                  final id = row['id'] as int;
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('$className / $lessonName'),
                    onTap: () => _openResult(context, id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSearch(BuildContext context) async {
    final state = context.read<AppState>();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    final rows = await state.db.searchContents(query);
    setState(() {
      _results = rows;
    });
  }

  Future<void> _openResult(BuildContext context, int contentId) async {
    final state = context.read<AppState>();
    final contentRow = await state.db.getContentById(contentId);
    if (contentRow == null) {
      return;
    }
    final lessonId = contentRow['ders_id'] as int;
    final topicId = contentRow['konu_id'] as int?;
    final lessonRow = await state.db.getLessonById(lessonId);
    if (lessonRow == null) {
      return;
    }
    final classId = lessonRow['sinif_id'] as int;
    final classRow = await state.db.getClassById(classId);
    if (classRow == null) {
      return;
    }
    state.selectClass(ClassModel.fromMap(Map<String, Object?>.from(classRow)));
    state.selectLesson(
      LessonModel.fromMap(Map<String, Object?>.from(lessonRow)),
      autoSelectFirstUnit: true,
    );
    if (topicId != null) {
      final topicRow = await state.db.getTopicById(topicId);
      if (topicRow != null) {
        state.selectTopic(TopicModel.fromMap(
          Map<String, Object?>.from(topicRow),
        ));
      }
    }
    final content = ContentItem.fromMap(Map<String, Object?>.from(contentRow));
    state.selectContent(ContentModel(
      id: content.id,
      title: content.name,
      contentItem: content,
      tags: const [],
    ));
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AppViewerScreen()),
      );
    }
  }
}

