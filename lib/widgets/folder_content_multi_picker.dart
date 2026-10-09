import 'package:flutter/material.dart';

import '../data/models/document_folder_model.dart';
import '../data/models/topic_model.dart';
import '../data/models/unit_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';

/// Multi-select dialog for adding existing content to a document folder.
class FolderContentMultiPicker extends StatefulWidget {
  const FolderContentMultiPicker({
    super.key,
    required this.state,
    required this.homeworkOnly,
  });

  final AppState state;
  final bool homeworkOnly;

  static Future<List<int>?> show(
    BuildContext context, {
    required AppState state,
    required bool homeworkOnly,
  }) {
    return showDialog<List<int>>(
      context: context,
      builder: (ctx) => FolderContentMultiPicker(
        state: state,
        homeworkOnly: homeworkOnly,
      ),
    );
  }

  @override
  State<FolderContentMultiPicker> createState() =>
      _FolderContentMultiPickerState();
}

class _FolderContentMultiPickerState extends State<FolderContentMultiPicker> {
  String _query = '';
  int? _lessonId;
  int? _unitId;
  int? _topicId;
  final Set<int> _selected = {};
  List<FolderPickerContent> _rows = [];
  List<Map<String, Object?>> _lessonOptions = [];
  List<UnitModel> _units = [];
  List<TopicModel> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _lessonOptions = await widget.state.db.listLessonOptionsForContentPicker(
      homeworkOnly: widget.homeworkOnly,
    );
    if (_lessonId != null) {
      _units = await widget.state.db.getUnits(_lessonId!);
    } else {
      _units = [];
      _unitId = null;
      _topicId = null;
      _topics = [];
    }
    if (_lessonId != null && _unitId != null) {
      final topicRows = await widget.state.db.getTopicsRaw(
        _lessonId!,
        unitId: _unitId,
      );
      _topics = topicRows.map(TopicModel.fromMap).toList();
    } else {
      _topics = [];
      if (_unitId == null) {
        _topicId = null;
      }
    }
    _rows = await widget.state.db.listContentsForFolderPicker(
      query: _query,
      homeworkOnly: widget.homeworkOnly,
      lessonId: _lessonId,
      unitId: _unitId,
      topicId: _topicId,
    );
    _selected.removeWhere(
      (id) => !_rows.any((row) => row.item.id == id),
    );
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _selectAllVisible() {
    setState(() {
      for (final row in _rows) {
        _selected.add(row.item.id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  String _contextLabel(FolderPickerContent row) {
    return [
      row.lessonName,
      row.topicName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      title: Text(
        widget.homeworkOnly
            ? strings.t('pickExistingHomework')
            : strings.t('pickExistingDocument'),
      ),
      content: SizedBox(
        width: isPhone ? double.maxFinite : 480,
        height: isPhone ? 420 : 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: strings.t('searchContent'),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (value) {
                _query = value;
                _reload();
              },
            ),
            const SizedBox(height: 8),
            _FilterDropdown<int?>(
              label: strings.t('courses'),
              value: _lessonId,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(strings.t('filterAll')),
                ),
                for (final row in _lessonOptions)
                  DropdownMenuItem<int?>(
                    value: row['id'] as int,
                    child: Text(row['ad'] as String),
                  ),
              ],
              onChanged: (value) {
                _lessonId = value;
                _unitId = null;
                _topicId = null;
                _reload();
              },
            ),
            if (_lessonId != null && _units.isNotEmpty)
              _FilterDropdown<int?>(
                label: strings.t('units'),
                value: _unitId,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(strings.t('filterAll')),
                  ),
                  for (final unit in _units)
                    DropdownMenuItem<int?>(
                      value: unit.id,
                      child: Text('${unit.number}. ${unit.name}'),
                    ),
                ],
                onChanged: (value) {
                  _unitId = value;
                  _topicId = null;
                  _reload();
                },
              ),
            if (_lessonId != null && _topics.isNotEmpty)
              _FilterDropdown<int?>(
                label: strings.t('topics'),
                value: _topicId,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(strings.t('filterAll')),
                  ),
                  for (final topic in _topics)
                    DropdownMenuItem<int?>(
                      value: topic.id,
                      child: Text(topic.name),
                    ),
                ],
                onChanged: (value) {
                  _topicId = value;
                  _reload();
                },
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    strings.t('selectedContentCount')
                        .replaceAll('{count}', '${_selected.length}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _rows.isEmpty ? null : _selectAllVisible,
                    child: Text(strings.t('selectAllStudents')),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty ? null : _clearSelection,
                    child: Text(strings.t('clearSelection')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? Center(
                          child: Text(
                            widget.homeworkOnly
                                ? strings.t('pickExistingHomework')
                                : strings.t('noDocuments'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            final item = row.item;
                            final checked = _selected.contains(item.id);
                            final contextLabel = _contextLabel(row);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selected.add(item.id);
                                  } else {
                                    _selected.remove(item.id);
                                  }
                                });
                              },
                              secondary: Icon(
                                widget.homeworkOnly
                                    ? Icons.assignment_outlined
                                    : Icons.insert_drive_file_outlined,
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                contextLabel.isEmpty
                                    ? item.type
                                    : '$contextLabel · ${item.type}',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancel')),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: Text(
            strings.t('addSelectedToFolder')
                .replaceAll('{count}', '${_selected.length}'),
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
