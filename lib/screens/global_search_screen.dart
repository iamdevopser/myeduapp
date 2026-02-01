import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/class_model.dart';
import '../data/models/content_item.dart';
import '../data/models/content_with_tags.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
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
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
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
    await state.selectClass(ClassModel.fromMap(classRow));
    await state.selectLesson(LessonModel.fromMap(lessonRow));
    if (topicId != null) {
      final topicRow = await state.db.getTopicById(topicId);
      if (topicRow != null) {
        state.selectTopic(TopicModel.fromMap(topicRow));
      }
    }
    final content = ContentItem.fromMap(contentRow);
    state.selectContent(ContentWithTags(content: content, tags: const []));
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AppViewerScreen()),
      );
    }
  }
}

