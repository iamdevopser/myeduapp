import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/authorization_service.dart';
import '../services/backup_package_service.dart';
import '../utils/teacher_display_name.dart';
import '../theme/app_spacing.dart';
import '../utils/teacher_nav_section.dart';
import '../utils/workspace_app_shell.dart';
import '../widgets/design_settings_profile_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/smtp_settings_section.dart';
import 'design_access_denied_screen.dart';
import 'global_search_screen.dart';
import 'question_bank_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Consumer<AppState>(
      builder: (context, state, _) {
        final auth = AuthorizationService(state);
        final width = MediaQuery.sizeOf(context).width;
        final padding = AppSpacing.pagePadding(width);

        if (!auth.canManageLocaleAndTheme) {
          return WorkspaceAppShell(
            title: strings.t('settings'),
            teacherNavSection: TeacherNavSection.settings,
            child: const DesignAccessDeniedScreen(embedded: true),
          );
        }

        final children = <Widget>[
          ..._generalSettingsSections(context, state, strings),
          if (!auth.canManageTeacherWorkspaceSettings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                strings.t('settingsGeneralHint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (auth.canManageTeacherWorkspaceSettings) ...[
            const _TeacherDisplayNameSection(),
            const SmtpSettingsSection(),
            SettingsSection(
              title: strings.t('security'),
              icon: Icons.lock_outline,
              children: [
                SettingsRow(
                  title: strings.t('changeTeacherPassword'),
                  subtitle: strings.t('teacherPasswordHint'),
                  onTap: () async {
                    final result = await _showPasswordDialog(
                      context,
                      isChange: true,
                      isTeacher: true,
                    );
                    if (result != null) {
                      await state.setTeacherPassword(result);
                    }
                  },
                ),
                SettingsRow(
                  title: strings.t('changeStudentPassword'),
                  subtitle: strings.t('studentPasswordHint'),
                  onTap: () async {
                    final result = await _showPasswordDialog(
                      context,
                      isChange: true,
                    );
                    if (result != null) {
                      await state.setStudentPassword(result);
                    }
                  },
                ),
                SettingsRow(
                  title: strings.t('changeSecretaryPassword'),
                  subtitle: strings.t('secretaryPasswordHint'),
                  onTap: () async {
                    final result = await _showPasswordDialog(
                      context,
                      isChange: true,
                    );
                    if (result != null) {
                      await state.setSecretaryPassword(result);
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: strings.t('autoBackup'),
              icon: Icons.backup_outlined,
              children: [
                SwitchListTile(
                  title: Text(strings.t('autoBackup')),
                  value: state.autoBackupEnabled,
                  onChanged: state.setAutoBackupEnabled,
                ),
                if (state.autoBackupEnabled)
                  _AutoBackupIntervalField(
                    initialMinutes: state.autoBackupMinutes,
                    onSave: state.setAutoBackupMinutes,
                  ),
              ],
            ),
            SettingsSection(
              title: strings.t('tags'),
              icon: Icons.label_outline,
              children: [
                SettingsRow(
                  title: strings.t('manageTags'),
                  onTap: () => _showManageTagsDialog(context, state),
                ),
              ],
            ),
            SettingsSection(
              title: strings.t('questionBank'),
              icon: Icons.quiz_outlined,
              children: [
                SettingsRow(
                  title: strings.t('questionBank'),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(QuestionBankScreen.routeName);
                  },
                ),
              ],
            ),
            SettingsSection(
              title: strings.t('search'),
              icon: Icons.search,
              children: [
                SettingsRow(
                  title: strings.t('search'),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(GlobalSearchScreen.routeName);
                  },
                ),
              ],
            ),
            SettingsSection(
              title: strings.t('backup'),
              icon: Icons.archive_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.archive),
                        label: Text(strings.t('backup')),
                        onPressed: () async {
                          final fileName =
                              'myeduapp_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
                          try {
                            if (Platform.isAndroid || Platform.isIOS) {
                              final zipBytes = await state.buildBackupBytes();
                              final saved = await FilePicker.platform.saveFile(
                                dialogTitle: strings.t('pickBackupLocation'),
                                fileName: fileName,
                                allowedExtensions: ['zip'],
                                type: FileType.custom,
                                bytes: zipBytes,
                              );
                              if (saved == null) return;
                            } else {
                              final path = await FilePicker.platform.saveFile(
                                dialogTitle: strings.t('pickBackupLocation'),
                                fileName: fileName,
                                allowedExtensions: ['zip'],
                                type: FileType.custom,
                              );
                              if (path == null) return;
                              await state.backupTo(path);
                            }
                            if (!context.mounted) return;
                            _showSnack(context, strings.t('backupSuccess'));
                          } catch (_) {
                            if (!context.mounted) return;
                            _showSnack(context, strings.t('backupFailed'));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restore),
                        label: Text(strings.t('restore')),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['zip'],
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) {
                            return;
                          }
                          final picked = result.files.single;
                          var restorePath = picked.path;
                          if (restorePath == null && picked.bytes != null) {
                            final tempFile = File(
                              '${Directory.systemTemp.path}'
                              '${Platform.pathSeparator}'
                              'myeduapp_restore_'
                              '${DateTime.now().millisecondsSinceEpoch}.zip',
                            );
                            await tempFile.writeAsBytes(picked.bytes!);
                            restorePath = tempFile.path;
                          }
                          if (restorePath == null) {
                            return;
                          }
                          final confirm = await _showConfirmDialog(
                            context,
                            strings.t('restoreWarning'),
                          );
                          if (!confirm) return;
                          try {
                            final result = await state.restoreFrom(restorePath);
                            if (!context.mounted) return;
                            _showSnack(context, strings.t('restoreSuccess'));
                            if (result.missingFileCount > 0) {
                              _showSnack(
                                context,
                                strings
                                    .t('restoreMissingFilesWarning')
                                    .replaceAll(
                                      '{count}',
                                      '${result.missingFileCount}',
                                    ),
                              );
                            }
                          } on BackupIntegrityException catch (e) {
                            debugPrint('===== RESTORE BUTUNLUK HATASI =====');
                            debugPrint('Hata: $e');
                            if (!context.mounted) return;
                            _showSnack(
                              context,
                              strings.t('restoreCorruptedBackup'),
                            );
                          } catch (e, stackTrace) {
                            debugPrint('===== RESTORE HATASI =====');
                            debugPrint('Hata: $e');
                            debugPrint('StackTrace:');
                            debugPrint('$stackTrace');
                            debugPrint('===== RESTORE HATASI SON =====');
                            if (!context.mounted) return;
                            _showSnack(context, strings.t('restoreFailed'));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ];

        final compact = width < 600;
        final listChild = ListView(
          padding: padding,
          children: [
            if (compact)
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DesignSettingsProfileHeader(),
                    const Divider(height: 1),
                    ...children,
                  ],
                ),
              )
            else ...[
              const DesignSettingsProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ],
        );

        return WorkspaceAppShell(
          title: strings.t('settings'),
          teacherNavSection: TeacherNavSection.settings,
          child: listChild,
        );
      },
    );
  }

  static List<Widget> _generalSettingsSections(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) {
    return [
      SettingsSection(
        title: strings.t('language'),
        icon: Icons.language,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<Locale>(
              isExpanded: true,
              value: state.locale,
              items: [
                for (final locale in AppLocalizations.supportedLocales)
                  DropdownMenuItem(
                    value: locale,
                    child: Text(
                      AppLocalizations.languageNames[locale.languageCode] ??
                          locale.languageCode,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) state.setLocale(value);
              },
            ),
          ),
        ],
      ),
      SettingsSection(
        title: strings.t('theme'),
        icon: Icons.palette_outlined,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<ThemeMode>(
              isExpanded: true,
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
                if (value != null) state.setThemeMode(value);
              },
            ),
          ),
        ],
      ),
    ];
  }

  // ================== DIALOGS ==================

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
          height: 260,
          child: ListView.builder(
            itemCount: state.tags.length,
            itemBuilder: (context, index) {
              final tag = state.tags[index];
              return ListTile(
                title: Text(tag.name),
                leading: CircleAvatar(
                  radius: 10,
                  backgroundColor: tag.color == null
                      ? Colors.grey.shade300
                      : Color(tag.color!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    state.deleteTag(tag);
                  },
                ),
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
      ),
    );
  }

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required bool isChange,
    bool isTeacher = false,
  }) async {
    final strings = AppLocalizations.of(context);
    final pass = TextEditingController();
    final confirm = TextEditingController();
    final title = isTeacher
        ? (isChange
              ? strings.t('changeTeacherPassword')
              : strings.t('setTeacherPassword'))
        : (isChange ? strings.t('changePassword') : strings.t('setPassword'));

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pass,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('newPassword')),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('confirmPassword'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (pass.text != confirm.text || pass.text.length < 4) return;
              Navigator.of(context).pop(pass.text);
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

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _AutoBackupIntervalField extends StatefulWidget {
  const _AutoBackupIntervalField({
    required this.initialMinutes,
    required this.onSave,
  });

  final int initialMinutes;
  final Future<void> Function(int) onSave;

  @override
  State<_AutoBackupIntervalField> createState() =>
      _AutoBackupIntervalFieldState();
}

class _AutoBackupIntervalFieldState extends State<_AutoBackupIntervalField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialMinutes}');
  }

  @override
  void didUpdateWidget(covariant _AutoBackupIntervalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes) {
      _controller.text = '${widget.initialMinutes}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: strings.t('backupInterval')),
        onSubmitted: (value) {
          final minutes = int.tryParse(value);
          if (minutes != null && minutes > 0) {
            widget.onSave(minutes);
          }
        },
      ),
    );
  }
}

class _TeacherDisplayNameSection extends StatefulWidget {
  const _TeacherDisplayNameSection();

  @override
  State<_TeacherDisplayNameSection> createState() =>
      _TeacherDisplayNameSectionState();
}

class _TeacherDisplayNameSectionState
    extends State<_TeacherDisplayNameSection> {
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(AppState state) async {
    final value =
        await state.db.getSetting(TeacherDisplayName.settingKey) ?? '';
    if (!mounted) return;
    _controller.text = value;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    if (!_loaded) {
      _load(state);
      return const SizedBox.shrink();
    }
    return SettingsSection(
      title: strings.t('teacherDisplayNameSection'),
      icon: Icons.person_outline,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: strings.t('teacherDisplayNameLabel'),
              helperText: strings.t('teacherDisplayNameHint'),
            ),
            onSubmitted: (_) => _save(state, strings),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: TextButton(
              onPressed: () => _save(state, strings),
              child: Text(strings.t('save')),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppState state, AppLocalizations strings) async {
    try {
      await state.setTeacherDisplayName(_controller.text.trim());
    } on TeacherSettingsAccessDeniedException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('settingsAccessDenied'))),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('teacherDisplayNameSaved'))),
    );
  }
}
