import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_document_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/app_card.dart';

class SecretaryDocumentAddScreen extends StatefulWidget {
  const SecretaryDocumentAddScreen({super.key});

  @override
  State<SecretaryDocumentAddScreen> createState() =>
      _SecretaryDocumentAddScreenState();
}

class _SecretaryDocumentAddScreenState
    extends State<SecretaryDocumentAddScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _scopeController = TextEditingController();
  String? _pickedPath;
  String? _pickedName;
  bool _loading = true;
  bool _saving = false;
  int? _editId;

  SecretaryDocumentService _service(AppState state) =>
      SecretaryDocumentService(state.db, state.fileService);

  @override
  void initState() {
    super.initState();
    _editId = context.read<AppState>().secretaryFocusDocumentId;
    _load();
  }

  Future<void> _load() async {
    if (_editId == null) {
      setState(() => _loading = false);
      return;
    }
    final doc = await _service(context.read<AppState>()).getById(_editId!);
    if (doc != null && mounted) {
      _titleController.text = doc.name;
      _descriptionController.text = doc.description ?? '';
      _categoryController.text = doc.category ?? '';
      _scopeController.text = doc.scope ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;
    setState(() {
      _pickedPath = file.path;
      _pickedName = file.name;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name;
      }
    });
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('documentTitleRequired'))),
      );
      return;
    }
    if (_editId == null && _pickedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('documentFileRequired'))),
      );
      return;
    }

    setState(() => _saving = true);
    final service = _service(context.read<AppState>());
    try {
      if (_editId == null) {
        await service.createFromFile(
          title: title,
          sourcePath: _pickedPath!,
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          scope: _scopeController.text.trim(),
        );
      } else {
        await service.updateMetadata(
          id: _editId!,
          title: title,
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          scope: _scopeController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t('documentSaved'))));
        navigateSecretarySection(context, SecretaryNavSection.documentList);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canCreateDocument) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final width = MediaQuery.sizeOf(context).width;
    final isEdit = _editId != null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding(width),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit
                  ? strings.t('secretaryDocumentEdit')
                  : strings.t('secretaryDocumentAdd'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...[
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(strings.t('documentPickFile')),
              ),
              if (_pickedName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_pickedName!),
                ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: strings.t('teacherAnnouncementsTitle'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: strings.t('documentDescriptionLabel'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: strings.t('documentCategoryLabel'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scopeController,
              decoration: InputDecoration(
                labelText: strings.t('documentScopeLabel'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
