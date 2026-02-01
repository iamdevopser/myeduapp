import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'global_search_screen.dart';
import 'question_bank_screen.dart';
import 'user_guide_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('settings')),
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.t('language'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButton<Locale>(
                value: state.locale,
                items: const [
                  DropdownMenuItem(
                    value: Locale('tr'),
                    child: Text('Türkçe'),
                  ),
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    state.setLocale(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(strings.t('theme'),
                  style: Theme.of(context).textTheme.titleMedium),
              DropdownButton<ThemeMode>(
                value: state.themeMode,
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(strings.t('themeSystem')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(strings.t('themeLight')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(strings.t('themeDark')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    state.setThemeMode(value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(strings.t('security'),
                  style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                title: Text(strings.t('enableLock')),
                value: state.lockEnabled,
                onChanged: (value) async {
                  if (value) {
                    final success = await _showPasswordDialog(
                      context,
                      isChange: false,
                    );
                    if (success != null) {
                      await state.setPassword(success);
                      await state.setLockEnabled(true);
                    }
                  } else {
                    final confirmed = await _showConfirmDialog(
                      context,
                      strings.t('disableLock'),
                    );
                    if (confirmed) {
                      await state.setLockEnabled(false);
                    }
                  }
                },
              ),
              if (state.lockEnabled)
                ListTile(
                  title: Text(strings.t('changePassword')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result =
                        await _showPasswordDialog(context, isChange: true);
                    if (result != null) {
                      await state.setPassword(result);
                    }
                  },
                ),
              const SizedBox(height: 16),
              Text(strings.t('autoBackup'),
                  style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                title: Text(strings.t('autoBackup')),
                value: state.autoBackupEnabled,
                onChanged: (value) => state.setAutoBackupEnabled(value),
              ),
              const SizedBox(height: 24),
              Text(strings.t('userGuide'),
                  style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                title: Text(strings.t('openUserGuide')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(UserGuideScreen.routeName);
                },
              ),
              if (state.autoBackupEnabled)
                TextField(
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: strings.t('backupInterval')),
                  onSubmitted: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes > 0) {
                      state.setAutoBackupMinutes(minutes);
                    }
                  },
                ),
              const SizedBox(height: 16),
              Text(strings.t('tags'),
                  style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                title: Text(strings.t('manageTags')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showManageTagsDialog(context, state),
              ),
              const SizedBox(height: 16),
              Text(strings.t('questionBank'),
                  style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                title: Text(strings.t('questionBank')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(QuestionBankScreen.routeName);
                },
              ),
              const SizedBox(height: 16),
              Text(strings.t('search'),
                  style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                title: Text(strings.t('search')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(GlobalSearchScreen.routeName);
                },
              ),
              const SizedBox(height: 24),
              Text(strings.t('backup'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final path = await FilePicker.platform.saveFile(
                    dialogTitle: strings.t('pickBackupLocation'),
                    fileName:
                        'myeduapp_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
                    allowedExtensions: ['zip'],
                    type: FileType.custom,
                  );
                  if (path != null) {
                    try {
                      await state.backupTo(path);
                      _showSnack(context, strings.t('backupSuccess'));
                    } catch (_) {
                      _showSnack(context, strings.t('backupFailed'));
                    }
                  }
                },
                icon: const Icon(Icons.archive),
                label: Text(strings.t('backup')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final file = await FilePicker.platform.pickFiles(
                    dialogTitle: strings.t('pickRestoreFile'),
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                  );
                  if (file != null && file.files.single.path != null) {
                    final confirm = await _showConfirmDialog(
                      context,
                      strings.t('restoreWarning'),
                    );
                    if (confirm) {
                      try {
                        await state.restoreFrom(file.files.single.path!);
                        _showSnack(context, strings.t('restoreSuccess'));
                      } catch (_) {
                        _showSnack(context, strings.t('restoreFailed'));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.restore),
                label: Text(strings.t('restore')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showManageTagsDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('manageTags')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: state.tags.length,
                  itemBuilder: (context, index) {
                    final tag = state.tags[index];
                    return ListTile(
                      title: Text(tag.name),
                      leading: CircleAvatar(
                        backgroundColor: tag.color == null
                            ? Colors.grey.shade300
                            : Color(tag.color!),
                        radius: 10,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.color_lens),
                            onPressed: () async {
                              final color = await _showColorPicker(context);
                              if (color != null) {
                                await state.updateTagColor(tag, color.value);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final updated = await _showTagNameDialog(
                                context,
                                initial: tag.name,
                              );
                              if (updated != null) {
                                await state.updateTag(tag, updated);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await state.deleteTag(tag);
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
                  final name = await _showTagNameDialog(context, initial: '');
                  if (name != null) {
                    await state.addTag(name);
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
      ),
    );
  }

  Future<Color?> _showColorPicker(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    const colors = [
      Color(0xFFEF5350),
      Color(0xFFAB47BC),
      Color(0xFF5C6BC0),
      Color(0xFF29B6F6),
      Color(0xFF26A69A),
      Color(0xFF9CCC65),
      Color(0xFFFFCA28),
      Color(0xFFFFA726),
      Color(0xFF8D6E63),
    ];
    return showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('selectColor')),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () => Navigator.of(context).pop(color),
                  child: CircleAvatar(backgroundColor: color),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<String?> _showTagNameDialog(
    BuildContext context, {
    required String initial,
  }) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('addTag')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.t('addTag')),
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

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required bool isChange,
  }) async {
    final strings = AppLocalizations.of(context);
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isChange ? strings.t('changePassword') : strings.t('setPassword')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('newPassword')),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('confirmPassword')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              if (password.length < 4) {
                _showSnack(context, strings.t('passwordTooShort'));
                return;
              }
              if (password != confirm) {
                _showSnack(context, strings.t('passwordMismatch'));
                return;
              }
              Navigator.of(context).pop(password);
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final strings = AppLocalizations.of(context);
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.t('confirm')),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

