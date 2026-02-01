import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/class_model.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'lesson_screen.dart';
import 'settings_screen.dart';
import 'app_viewer_screen.dart';

class AppBuilderScreen extends StatelessWidget {
  const AppBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        final selectedClass = state.selectedClass == null
            ? null
            : state.classes
                .where((item) => item.id == state.selectedClass!.id)
                .cast<ClassModel?>()
                .firstWhere((item) => item != null, orElse: () => null);
        final selectedLesson = state.selectedLesson == null
            ? null
            : state.lessons
                .where((item) => item.id == state.selectedLesson!.id)
                .cast<LessonModel?>()
                .firstWhere((item) => item != null, orElse: () => null);
        final selectedTopic = state.selectedTopic == null
            ? null
            : state.topics
                .where((item) => item.id == state.selectedTopic!.id)
                .cast<TopicModel?>()
                .firstWhere((item) => item != null, orElse: () => null);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('appBuilderTitle')),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: strings.t('goHome'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AppViewerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.apps, color: Colors.white),
                label: Text(
                  strings.t('goToApp'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(SettingsScreen.routeName);
                },
                icon: const Icon(Icons.settings),
                tooltip: strings.t('settings'),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.build, color: Color(0xFF1E2A5A)),
                            const SizedBox(width: 12),
                            Text(
                              strings.t('appBuilderTitle'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: strings.t('selectClass'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<ClassModel>(
                            isExpanded: true,
                            value: selectedClass,
                            hint: Text(strings.t('selectClass')),
                            items: state.classes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              state.selectClass(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showManageClassesDialog(context, state),
                              child: Text(strings.t('manageClasses')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: strings.t('selectLesson'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<LessonModel>(
                            isExpanded: true,
                            value: selectedLesson,
                            hint: Text(strings.t('selectLesson')),
                            items: state.lessons
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: state.selectedClass == null
                                ? null
                                : (value) {
                                    state.selectLesson(value);
                                  },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: state.selectedClass == null
                                  ? null
                                  : () => _showManageLessonsDialog(
                                      context, state),
                              child: Text(strings.t('manageLessons')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: strings.t('selectTopic'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<TopicModel>(
                            isExpanded: true,
                            value: selectedTopic,
                            hint: Text(strings.t('selectTopic')),
                            items: state.topics
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: state.selectedLesson == null
                                ? null
                                : (value) => state.selectTopic(value),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: state.selectedLesson == null
                                  ? null
                                  : () => _showManageTopicsDialog(
                                      context, state),
                              child: Text(strings.t('manageTopics')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        if (state.selectedClass == null) {
                          _showSnack(context, strings.t('classRequired'));
                          return;
                        }
                        if (state.selectedLesson == null) {
                          _showSnack(context, strings.t('lessonRequired'));
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LessonScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(strings.t('openLesson')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showManageClassesDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(strings.t('manageClasses')),
          content: SizedBox(
            width: 400,
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        itemCount: appState.classes.length,
                        itemBuilder: (context, index) {
                          final item = appState.classes[index];
                          return ListTile(
                            title: Text(item.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await _showNameDialog(
                                      context,
                                      title: strings.t('edit'),
                                      initialValue: item.name,
                                      label: strings.t('className'),
                                    );
                                    if (result != null) {
                                      await appState.updateClass(item, result);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirmed = await _showConfirmDialog(
                                      context,
                                      strings.t('classDeleteWarning'),
                                      confirmText: strings.t('yesDeleteAll'),
                                      cancelText: strings.t('cancel'),
                                    );
                                    if (confirmed) {
                                      await appState.deleteClass(item);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await _showNameDialog(
                          context,
                          title: strings.t('add'),
                          initialValue: '',
                          label: strings.t('className'),
                        );
                        if (result != null) {
                          await appState.addClass(result);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(strings.t('add')),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showManageLessonsDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(strings.t('manageLessons')),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    itemCount: state.lessons.length,
                    itemBuilder: (context, index) {
                      final item = state.lessons[index];
                      return ListTile(
                        title: Text(item.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await _showNameDialog(
                                  context,
                                  title: strings.t('edit'),
                                  initialValue: item.name,
                                  label: strings.t('lessonName'),
                                );
                                if (result != null) {
                                  await state.updateLesson(item, result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirmed = await _showConfirmDialog(
                                  context,
                                  strings.t('lessonDeleteWarning'),
                                  confirmText: strings.t('yesDeleteContents'),
                                  cancelText: strings.t('cancel'),
                                );
                                if (confirmed) {
                                  await state.deleteLesson(item);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await _showNameDialog(
                      context,
                      title: strings.t('add'),
                      initialValue: '',
                      label: strings.t('lessonName'),
                    );
                    if (result != null) {
                      await state.addLesson(result);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(strings.t('add')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showManageTopicsDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(strings.t('manageTopics')),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 240,
                  child: ReorderableListView.builder(
                    itemCount: state.topics.length,
                    onReorder: state.reorderTopics,
                    itemBuilder: (context, index) {
                      final item = state.topics[index];
                      return ListTile(
                        key: ValueKey(item.id),
                        title: Text(item.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await _showNameDialog(
                                  context,
                                  title: strings.t('edit'),
                                  initialValue: item.name,
                                  label: strings.t('topicName'),
                                );
                                if (result != null) {
                                  await state.updateTopic(item, result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await state.deleteTopic(item);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await _showNameDialog(
                      context,
                      title: strings.t('add'),
                      initialValue: '',
                      label: strings.t('topicName'),
                    );
                    if (result != null) {
                      await state.addTopic(result);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(strings.t('add')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('close')),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showNameDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String label,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final strings = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                _showSnack(context, strings.t('invalidName'));
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String message, {
    required String confirmText,
    required String cancelText,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
        )) ??
        false;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

