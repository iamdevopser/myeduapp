import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/class_model.dart';
import '../data/models/content_with_tags.dart' as cwt;
import '../data/models/exam_question.dart';
import '../data/models/lesson_builder_models.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../data/models/unit_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/teacher_activity.dart';
import '../utils/app_navigation.dart';
import '../utils/course_form_options.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import '../widgets/content_preview.dart';
import 'settings_screen.dart';

const _kCourseNameOptions = <String>[
  'Matematik',
  'Fizik',
  'Kimya',
  'Biyoloji',
  'Bilgisayar',
  'İngilizce',
  'Türkçe',
];

class LinkDialogResult {
  LinkDialogResult(this.title, this.url);
  final String title;
  final String url;
}

/// Block-based Lesson Builder:
/// Left: Block palette (incl. Ödev, Soru, Sınav)
/// Center: Ders/Kurs/Ünite/Konu dropdowns + Content drag-drop area
/// Right: Ders/Kurs/Ünite/Konu Ayarları with Ekle buttons
class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({super.key});

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  Object? _selectedNode;
  List<cwt.ContentWithTags> _topicContents = [];
  bool _previewMode = false;
  int _previewEpoch = 0;
  String? _selectedSubjectName;
  List<SubjectSummary> _subjects = [];
  List<LessonModel> _courses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubjects());
  }

  Future<void> _loadSubjects() async {
    final state = context.read<AppState>();
    final subjects = await state.db.getSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      if (_selectedSubjectName != null &&
          !subjects.any((s) => s.name == _selectedSubjectName)) {
        _selectedSubjectName = null;
        _courses = [];
      }
    });
  }

  Future<void> _loadCourses() async {
    if (_selectedSubjectName == null) {
      setState(() => _courses = []);
      return;
    }
    final courses = await context
        .read<AppState>()
        .db
        .getCoursesForSubject(_selectedSubjectName!);
    if (!mounted) return;
    setState(() => _courses = courses);
  }

  Future<void> _selectSubject(String? name) async {
    final state = context.read<AppState>();
    _selectedSubjectName = name;
    state.selectedClass = null;
    state.selectedLesson = null;
    state.selectedUnit = null;
    state.selectedTopic = null;
    state.selectedContent = null;
    await _loadCourses();
    if (!mounted) return;
    setState(() {
      _topicContents = [];
      _selectedNode = null;
    });
  }

  Future<void> _selectCourse(LessonModel? course) async {
    if (course == null) return;
    final state = context.read<AppState>();
    await state.openCourse(course);
    if (!mounted) return;
    setState(() {
      _topicContents = [];
      _selectedNode = null;
    });
  }

  String _courseLabel(LessonModel course) {
    final classLabel = course.className?.trim() ?? '';
    final year = course.academicYear.trim();
    if (classLabel.isNotEmpty && year.isNotEmpty) {
      return '$classLabel · $year';
    }
    if (classLabel.isNotEmpty) return classLabel;
    if (year.isNotEmpty) return year;
    return course.name;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, _) {
        return AppShell(
          constrainContent: false,
          teacherSection: TeacherNavSection.lessonPlatform,
          title: strings.t('lessonBuilder'),
          subtitle: strings.t('builderDragHint'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onBackPressed(context),
            tooltip: strings.t('goHome'),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                  style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.brandPrimary;
                    }
                    return AppColors.textSecondary;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.brandPrimary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                  side: WidgetStatePropertyAll(
                    const BorderSide(color: AppColors.border),
                  ),
                ),
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(strings.t('editMode')),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(strings.t('preview')),
                  ),
                ],
                selected: {_previewMode},
                onSelectionChanged: (selected) {
                  setState(() {
                    _previewMode = selected.first;
                    if (_previewMode) _previewEpoch++;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: strings.t('settings'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(SettingsScreen.routeName),
            ),
          ],
          child: _previewMode
              ? _buildPreview(context, state, strings)
              : _buildEditorLayout(context, state, strings),
        );
      },
    );
  }

  Widget _buildEditorLayout(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) {
    final content = _ContentSection(
      state: state,
      subjects: _subjects,
      courses: _courses,
      selectedSubjectName: _selectedSubjectName,
      courseLabel: _courseLabel,
      selectedNode: _selectedNode,
      topicContents: _topicContents,
      onSelect: (node) => setState(() => _selectedNode = node),
      onBlockDropped: (type) => _handleBlockDropped(type, state),
      onContentsLoaded: (contents) => setState(() => _topicContents = contents),
      onRefresh: () => setState(() {}),
      onDeleteBlock: (c) => _deleteBlock(c, state),
      onEditBlock: (c) => _editBlock(context, c, state),
      onSubjectChanged: _selectSubject,
      onCourseChanged: _selectCourse,
    );
    final settings = _SettingsPanel(
      selectedNode: _selectedNode,
      state: state,
      selectedSubjectName: _selectedSubjectName,
      onChanged: () => setState(() {}),
      strings: strings,
      onAddSubject: () => _addSubject(context, state),
      onAddCourse: () => _addCourse(context, state),
      onAddUnit: () => _addUnit(context, state),
      onAddTopic: () => _addTopic(context, state),
      onEditSubject: () => _editSubject(context, state),
      onEditCourse: () => _editCourse(context, state),
      onEditUnit: () => _editUnit(context, state),
      onEditTopic: () => _editTopic(context, state),
      onDeleteSubject: () => _deleteSubject(context, state),
      onDeleteCourse: () => _deleteCourse(context, state),
      onDeleteUnit: () => _deleteUnit(context, state),
      onDeleteTopic: () => _deleteTopic(context, state),
    );
    final width = MediaQuery.sizeOf(context).width;

    if (AppSpacing.isMobile(width)) {
      return DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              tabs: [
                Tab(text: strings.t('blockTypes')),
                Tab(text: strings.t('lessonBuilder')),
                Tab(text: strings.t('settings')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _BlockPalette(),
                  content,
                  settings,
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (AppSpacing.isTablet(width)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 168, child: _BlockPalette()),
          const VerticalDivider(width: 1),
          Expanded(flex: 3, child: content),
          const VerticalDivider(width: 1),
          SizedBox(width: 280, child: settings),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(width: 200, child: _BlockPalette()),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: content),
        const VerticalDivider(width: 1),
        SizedBox(width: 320, child: settings),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) {
    final topic = state.selectedTopic as TopicModel?;
    if (topic == null) {
      return Center(child: Text(strings.t('selectTopicForPreview')));
    }
    final course = state.selectedLesson as LessonModel?;
    final className = course?.className ?? (state.selectedClass as ClassModel?)?.name ?? '';
    final lessonName = course?.name ?? '';
    return FutureBuilder<List<cwt.ContentWithTags>>(
      key: ValueKey('preview-${topic.id}-$_previewEpoch'),
      future: state.db.getContentsWithTagsByTopic(topic.id),
      builder: (context, snapshot) {
        final contents = snapshot.data ?? _topicContents;
        if (snapshot.connectionState == ConnectionState.waiting &&
            contents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return TopicStudentPreview(
          contents: contents,
          className: className,
          lessonName: lessonName,
          topicName: topic.name,
          onBackToEditor: () => setState(() => _previewMode = false),
        );
      },
    );
  }

  Future<void> _onBackPressed(BuildContext context) async {
    final confirmed = await confirmLeavePage(context);
    if (confirmed && context.mounted) {
      popToPreviousOrLogin(context);
    }
  }

  Future<void> _addSubject(BuildContext context, AppState state) async {
    final strings = AppLocalizations.of(context);
    final result = await _showSubjectDialog(context);
    if (result == null) return;
    if (result.imagePath != null && result.imagePath!.isNotEmpty) {
      final imagePath = await state.ensureMediaInAppData(
        result.imagePath,
        'DersGorselleri',
      );
      await state.db.setSubjectImage(result.name, imagePath);
      await _loadSubjects();
    }
    final exists = _subjects.any((s) => s.name == result.name);
    if (exists) {
      await _selectSubject(result.name);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('subjectSelectFirstCourse'))),
      );
    }
    setState(() {});
  }

  Future<void> _addCourse(BuildContext context, AppState state) async {
    final strings = AppLocalizations.of(context);
    final result = await _showCourseDialog(
      context,
      subjectName: _selectedSubjectName,
    );
    if (result == null) return;
    final classId = await state.db.getOrCreateClassForGrade(result.grade);
    final existing = await state.db.findCourseByKeys(
      name: result.subjectName,
      classId: classId,
      academicYear: result.year,
    );
    if (existing != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('courseDuplicate'))),
        );
      }
      return;
    }
    final order = await state.db.getNextLessonOrder(classId);
    final lessonImage = await state.ensureMediaInAppData(
      result.imagePath,
      'Dersler',
    );
    final lessonId = await state.db.insertLesson(
      classId,
      result.subjectName,
      order,
      academicYear: result.year,
      imagePath: lessonImage,
    );
    await _loadSubjects();
    await _selectSubject(result.subjectName);
    await _loadCourses();
    final course = _courses.where((c) => c.id == lessonId).firstOrNull;
    if (course != null) {
      await _selectCourse(course);
    } else {
      final rows = await state.db.getCoursesForSubject(result.subjectName);
      final created = rows.where((c) => c.id == lessonId).firstOrNull;
      if (created != null) {
        setState(() => _courses = rows);
        await _selectCourse(created);
      }
    }
    setState(() {});
  }

  Future<void> _addUnit(BuildContext context, AppState state) async {
    if (state.selectedLesson == null) return;
    final strings = AppLocalizations.of(context);
    final l = state.selectedLesson as LessonModel;
    final defaultNumber = await state.db.getNextUnitNumber(l.id);
    final result = await _showUnitDialog(
      context,
      title: strings.t('addUnit'),
      initialName: '',
      initialNumber: defaultNumber,
    );
    if (result != null && result.name.isNotEmpty) {
      final order = await state.db.getNextUnitOrder(l.id);
      final unitImage = await state.ensureMediaInAppData(
        result.imagePath,
        'Uniteler',
      );
      await state.db.insertUnit(
        lessonId: l.id,
        name: result.name,
        number: result.number,
        order: order,
        imagePath: unitImage,
      );
      await state.refreshAll();
      setState(() {});
    }
  }

  Future<void> _addTopic(BuildContext context, AppState state) async {
    if (state.selectedLesson == null || state.selectedUnit == null) return;
    final result = await _showTopicDialog(
      context,
      title: 'Konu Ekle',
      initialName: '',
    );
    if (result != null && result.name.isNotEmpty) {
      final l = state.selectedLesson as LessonModel;
      final unitId = (state.selectedUnit as UnitModel?)?.id;
      final order = await state.db.getNextTopicOrder(l.id, unitId: unitId);
      final topicImage = await state.ensureMediaInAppData(
        result.imagePath,
        'Konular',
      );
      await state.db.insertTopic(
        l.id,
        result.name,
        order,
        unitId: unitId,
        imagePath: topicImage,
      );
      await state.refreshAll();
      setState(() {});
    }
  }

  Future<void> _editSubject(BuildContext context, AppState state) async {
    if (_selectedSubjectName == null) return;
    final currentImage =
        await state.db.getSubjectImage(_selectedSubjectName!);
    final result = await _showSubjectEditDialog(
      context,
      initialName: _selectedSubjectName!,
      imagePath: currentImage,
    );
    if (result == null) return;
    if (result.name.isEmpty) return;
    if (result.name != _selectedSubjectName) {
      await state.db.renameSubject(_selectedSubjectName!, result.name);
      _selectedSubjectName = result.name;
    }
    final imagePath = await state.ensureMediaInAppData(
      result.imagePath,
      'DersGorselleri',
    );
    await state.db.setSubjectImage(result.name, imagePath);
    await _loadSubjects();
    await _loadCourses();
    setState(() {});
  }

  Future<void> _editCourse(BuildContext context, AppState state) async {
    final l = state.selectedLesson as LessonModel?;
    if (l == null) return;
    final strings = AppLocalizations.of(context);
    final grade = await state.db.getClassGrade(l.classId) ?? 7;
    final result = await _showCourseDialog(
      context,
      subjectName: l.name,
      grade: grade,
      year: l.academicYear,
      imagePath: l.imagePath,
      editing: true,
    );
    if (result != null) {
      final classId = await state.db.getOrCreateClassForGrade(result.grade);
      final existing = await state.db.findCourseByKeys(
        name: result.subjectName,
        classId: classId,
        academicYear: result.year,
      );
      if (existing != null && existing.id != l.id) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('courseDuplicate'))),
          );
        }
        return;
      }
      final lessonImage = await state.ensureMediaInAppData(
        result.imagePath,
        'Dersler',
      );
      await state.db.updateLesson(
        l.id,
        result.subjectName,
        academicYear: result.year,
        imagePath: lessonImage,
        classId: classId,
      );
      await state.refreshAll();
      if (_selectedSubjectName != result.subjectName) {
        _selectedSubjectName = result.subjectName;
        await _loadSubjects();
      }
      await _loadCourses();
      setState(() {});
    }
  }

  Future<void> _editUnit(BuildContext context, AppState state) async {
    final unit = state.selectedUnit as UnitModel?;
    if (unit == null) return;
    final result = await _showUnitDialog(
      context,
      title: AppLocalizations.of(context).t('editUnit'),
      initialName: unit.name,
      initialNumber: unit.number,
      imagePath: unit.imagePath,
    );
    if (result != null && result.name.isNotEmpty) {
      await state.updateUnit(
        unit,
        result.name,
        number: result.number,
        imagePath: result.imagePath,
        clearImage: result.clearImage,
      );
      setState(() {});
    }
  }

  Future<void> _editTopic(BuildContext context, AppState state) async {
    final t = state.selectedTopic as TopicModel?;
    if (t == null) return;
    final result = await _showTopicDialog(
      context,
      title: 'Konuyu Düzenle',
      initialName: t.name,
      imagePath: t.imagePath,
    );
    if (result != null && result.name.isNotEmpty) {
      await state.updateTopic(
        t,
        result.name,
        result.imagePath,
        result.clearImage,
      );
      setState(() {});
    }
  }

  Future<void> _deleteSubject(BuildContext context, AppState state) async {
    if (_selectedSubjectName == null) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(strings.t('subjectDeleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.db.deleteLessonsBySubjectName(_selectedSubjectName!);
      _selectedSubjectName = null;
      _courses = [];
      state.selectedLesson = null;
      state.selectedUnit = null;
      state.selectedTopic = null;
      await _loadSubjects();
      setState(() {});
    }
  }

  Future<void> _deleteCourse(BuildContext context, AppState state) async {
    final l = state.selectedLesson as LessonModel?;
    if (l == null) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(strings.t('lessonDeleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteLesson(l);
      await _loadCourses();
      setState(() {});
    }
  }

  Future<void> _deleteUnit(BuildContext context, AppState state) async {
    final unit = state.selectedUnit as UnitModel?;
    if (unit == null) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(strings.t('unitDeleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteUnit(unit);
      setState(() {});
    }
  }

  Future<void> _deleteTopic(BuildContext context, AppState state) async {
    final t = state.selectedTopic as TopicModel?;
    if (t == null) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(strings.t('topicDeleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteTopic(t);
      setState(() {});
    }
  }

  Future<void> _deleteBlock(cwt.ContentWithTags c, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('delete')),
        content: Text(
            '${c.content.name} silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final model = ContentModel(
        id: c.content.id,
        title: c.content.name,
        contentItem: c.content,
        tags: c.tags,
      );
      await state.deleteContent(model);
      setState(() {});
    }
  }

  Future<void> _editBlock(
    BuildContext context,
    cwt.ContentWithTags c,
    AppState state,
  ) async {
    final type = c.content.type;
    if (type == 'link') {
      final result = await _showLinkDialogWithTitle(
        context,
        initialTitle: c.content.name,
        initialUrl: c.content.path,
      );
      if (result != null) {
        await state.updateContentNameAndPath(
          c.content.id,
          result.title,
          result.url,
        );
        setState(() {});
      }
    } else if (type == 'text') {
      final newText = await _showTextBlockDialog(
        context,
        initialText: c.content.path,
      );
      if (newText != null) {
        await state.updateContentNameAndPath(
          c.content.id,
          c.content.name,
          newText,
        );
        setState(() {});
      }
    } else {
      final strings = AppLocalizations.of(context);
      final newName = await _showNameDialog(
        context,
        title: strings.t('edit'),
        initialValue: c.content.name,
        label: 'Başlık',
      );
      if (newName != null) {
        await state.updateContentNameAndPath(
          c.content.id,
          newName,
          c.content.path,
        );
        setState(() {});
      }
    }
  }

  Future<void> _handleBlockDropped(BlockType type, AppState state) async {
    if (state.selectedLesson == null ||
        state.selectedUnit == null ||
        state.selectedTopic == null) {
      return;
    }
    final l = state.selectedLesson as LessonModel;
    final t = state.selectedTopic as TopicModel;
    final className = l.className ??
        (state.selectedClass as ClassModel?)?.name ??
        '';

    String path = '';
    String name = '';
    String contentType = type.code;
    final isHomeworkBlock = type == BlockType.homework;

    if (type == BlockType.homework) {
      final choice = await _showHomeworkChoiceDialog(context);
      if (choice == null) return;
      if (choice == 'text') {
        if (!mounted) return;
        final text = await _showTextBlockDialog(context);
        if (text == null) return;
        path = text;
        name = 'Ödev';
        contentType = 'text';
      } else {
        final result = await _pickFileForType(BlockType.word);
        if (result == null) return;
        path = result;
        name = path.split(RegExp(r'[/\\]')).last;
        contentType = _fileTypeForPath(path);
      }
    } else if (type == BlockType.question) {
      final q = await _showQuestionDialog(context);
      if (q == null) return;
      await _addQuestionToTopic(state, t, q);
      setState(() {});
      return;
    } else if (type == BlockType.exam) {
      final result = await _pickFileForType(BlockType.pdf);
      if (result == null) return;
      path = result;
      name = path.split(RegExp(r'[/\\]')).last;
      contentType = 'pdf';
    } else if (type == BlockType.text) {
      final text = await _showTextBlockDialog(context);
      if (text == null) return;
      path = text;
      name = 'Metin bloğu';
    } else if (type == BlockType.webLink) {
      final result = await _showLinkDialogWithTitle(context);
      if (result == null) return;
      name = result.title;
      path = result.url;
    } else {
      final result = await _pickFileForType(type);
      if (result == null) return;
      path = result;
      name = path.split(RegExp(r'[/\\]')).last;
      contentType = type.code;
    }

    final contentId = await state.addBlockToStep(
      lessonId: l.id,
      topicId: t.id,
      type: contentType,
      name: name,
      path: path,
      className: className,
      lessonName: l.name,
      topicName: t.name,
    );
    if (isHomeworkBlock) {
      final strings = AppLocalizations.of(context);
      await state.recordTeacherActivity(
        type: TeacherActivityTypes.homeworkCreated,
        title: strings
            .t('activityHomeworkCreated')
            .replaceAll('{name}', name),
        targetType: TeacherActivityTargets.content,
        targetId: contentId,
      );
    }
    setState(() {});
  }

  Future<void> _addQuestionToTopic(
    AppState state,
    TopicModel topic,
    ExamQuestion q,
  ) async {
    if (state.selectedLesson == null ||
        state.selectedTopic == null) {
      return;
    }
    final l = state.selectedLesson as LessonModel;
    final className = l.className ??
        (state.selectedClass as ClassModel?)?.name ??
        '';
    final examId = await state.db.insertExam(
      lessonId: l.id,
      topicId: topic.id,
      name: 'Soru',
    );
    await state.db.insertExamQuestion(
      examId: examId,
      question: q.value,
      type: q.typeCode,
      optionsJson: q.toOptionsJson(),
      correctOption: q.correctOptionIndex,
      audioPath: q.audioPath,
      order: 0,
    );
    await state.addBlockToStep(
      lessonId: l.id,
      topicId: topic.id,
      type: 'question',
      name: q.value.length > 30 ? '${q.value.substring(0, 30)}...' : q.value,
      path: examId.toString(),
      className: className,
      lessonName: l.name,
      topicName: topic.name,
    );
  }

  String _fileTypeForPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['pdf'].contains(ext)) return 'pdf';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['doc', 'docx'].contains(ext)) return 'word';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'image';
    if (['mp4', 'avi', 'webm'].contains(ext)) return 'video';
    if (['mp3', 'wav'].contains(ext)) return 'audio';
    return 'file';
  }

  Future<String?> _showHomeworkChoiceDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ödev Bloğu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Metin olarak oluştur'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Dosya olarak oluştur'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ExamQuestion?> _showQuestionDialog(BuildContext context) async {
    return showDialog<ExamQuestion>(
      context: context,
      builder: (_) => _QuestionDialog(),
    );
  }

  Future<String?> _showTextBlockDialog(
    BuildContext context, {
    String? initialText,
  }) async {
    final ctrl = TextEditingController(text: initialText ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Metin Bloğu'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Metin içeriği',
            hintText: 'Metninizi girin...',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  Future<LinkDialogResult?> _showLinkDialogWithTitle(
    BuildContext context, {
    String? initialTitle,
    String? initialUrl,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final urlCtrl = TextEditingController(text: initialUrl ?? '');
    return showDialog<LinkDialogResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('addLink')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL', hintText: 'https://'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context,
                LinkDialogResult(titleCtrl.text.trim(), urlCtrl.text.trim())),
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickFileForType(BlockType type) async {
    final extensions = <BlockType, List<String>>{
      BlockType.pdf: ['pdf'],
      BlockType.ppt: ['ppt', 'pptx'],
      BlockType.word: ['doc', 'docx'],
      BlockType.image: ['jpg', 'jpeg', 'png', 'gif'],
      BlockType.video: ['mp4', 'avi', 'webm'],
      BlockType.audio: ['mp3', 'wav'],
    };
    final exts = extensions[type] ?? ['*'];
    final result = await FilePicker.platform.pickFiles(
      type: exts.contains('*') ? FileType.any : FileType.custom,
      allowedExtensions: exts.contains('*') ? null : exts,
    );
    return result?.files.single.path;
  }

  Future<_SubjectDialogResult?> _showSubjectDialog(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    var selectedName = _kCourseNameOptions.first;
    String? selectedImage;
    return showDialog<_SubjectDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.t('addSubject')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedName,
                      decoration: InputDecoration(
                        labelText: strings.t('subjectName'),
                      ),
                      items: _kCourseNameOptions
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedName = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _imagePickerRow(
                      context,
                      strings,
                      selectedImage,
                      (path) => setDialogState(() => selectedImage = path),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _SubjectDialogResult(
                      name: selectedName,
                      imagePath: selectedImage,
                    ),
                  ),
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_SubjectDialogResult?> _showSubjectEditDialog(
    BuildContext context, {
    required String initialName,
    String? imagePath,
  }) async {
    final strings = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: initialName);
    var selectedImage = imagePath;
    var clearImage = false;
    return showDialog<_SubjectDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.t('editSubject')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('subjectName'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _imagePickerRow(
                      context,
                      strings,
                      clearImage ? null : selectedImage,
                      (path) => setDialogState(() {
                        selectedImage = path;
                        clearImage = false;
                      }),
                      onClear: () => setDialogState(() {
                        selectedImage = null;
                        clearImage = true;
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _SubjectDialogResult(
                      name: nameCtrl.text.trim(),
                      imagePath: clearImage ? null : selectedImage,
                    ),
                  ),
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_UnitDialogResult?> _showUnitDialog(
    BuildContext context, {
    required String title,
    required String initialName,
    required int initialNumber,
    String? imagePath,
  }) async {
    final strings = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: initialName);
    final numberCtrl = TextEditingController(text: '$initialNumber');
    var selectedImage = imagePath;
    var clearImage = false;
    return showDialog<_UnitDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('unitName'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: numberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ünite numarası',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    _imagePickerRow(
                      context,
                      strings,
                      clearImage ? null : selectedImage,
                      (path) => setDialogState(() {
                        selectedImage = path;
                        clearImage = false;
                      }),
                      onClear: imagePath != null
                          ? () => setDialogState(() {
                                selectedImage = null;
                                clearImage = true;
                              })
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () {
                    final number = int.tryParse(numberCtrl.text.trim());
                    if (number == null) return;
                    Navigator.pop(
                      dialogContext,
                      _UnitDialogResult(
                        name: nameCtrl.text.trim(),
                        number: number,
                        imagePath: clearImage ? null : selectedImage,
                        clearImage: clearImage,
                      ),
                    );
                  },
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_TopicDialogResult?> _showTopicDialog(
    BuildContext context, {
    required String title,
    required String initialName,
    String? imagePath,
  }) async {
    final strings = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: initialName);
    var selectedImage = imagePath;
    var clearImage = false;
    return showDialog<_TopicDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Konu adı'),
                    ),
                    const SizedBox(height: 8),
                    _imagePickerRow(
                      context,
                      strings,
                      clearImage ? null : selectedImage,
                      (path) => setDialogState(() {
                        selectedImage = path;
                        clearImage = false;
                      }),
                      onClear: imagePath != null
                          ? () => setDialogState(() {
                                selectedImage = null;
                                clearImage = true;
                              })
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _TopicDialogResult(
                      name: nameCtrl.text.trim(),
                      imagePath: clearImage ? null : selectedImage,
                      clearImage: clearImage,
                    ),
                  ),
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _imagePickerRow(
    BuildContext context,
    AppLocalizations strings,
    String? imagePath,
    ValueChanged<String?> onImagePicked, {
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            imagePath == null || imagePath.isEmpty
                ? strings.t('noCoverImage')
                : imagePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onClear != null && imagePath != null && imagePath.isNotEmpty)
          TextButton(
            onPressed: onClear,
            child: const Text('Temizle'),
          ),
        TextButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (result?.files.single.path != null) {
              onImagePicked(result!.files.single.path);
            }
          },
          child: Text(strings.t('chooseImage')),
        ),
      ],
    );
  }

  Future<_CourseDialogResult?> _showCourseDialog(
    BuildContext context, {
    String? subjectName,
    int grade = 7,
    String year = '',
    String? imagePath,
    bool editing = false,
  }) async {
    final strings = AppLocalizations.of(context);
    final years = CourseFormOptions.academicYearOptions();
    var selectedName = subjectName != null &&
            _kCourseNameOptions.contains(subjectName)
        ? subjectName
        : _kCourseNameOptions.first;
    var selectedGrade = grade.clamp(1, 12);
    var selectedYear =
        year.isNotEmpty && years.contains(year) ? year : years.first;
    var selectedImage = imagePath;
    return showDialog<_CourseDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editing ? strings.t('editCourse') : strings.t('addCourse'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedName,
                      decoration: InputDecoration(
                        labelText: strings.t('courseName'),
                      ),
                      items: _kCourseNameOptions
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedName = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedGrade,
                      decoration: InputDecoration(
                        labelText: strings.t('gradeLabel'),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(CourseFormOptions.gradeLabel(i + 1)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedGrade = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedYear,
                      decoration: InputDecoration(
                        labelText: strings.t('academicYear'),
                      ),
                      items: years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(y),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedYear = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _imagePickerRow(
                      context,
                      strings,
                      selectedImage,
                      (path) => setDialogState(() => selectedImage = path),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      _CourseDialogResult(
                        subjectName: selectedName,
                        grade: selectedGrade,
                        year: selectedYear,
                        imagePath: selectedImage,
                      ),
                    );
                  },
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
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
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }
}

class _SubjectDialogResult {
  _SubjectDialogResult({required this.name, this.imagePath});

  final String name;
  final String? imagePath;
}

class _UnitDialogResult {
  _UnitDialogResult({
    required this.name,
    required this.number,
    this.imagePath,
    this.clearImage = false,
  });

  final String name;
  final int number;
  final String? imagePath;
  final bool clearImage;
}

class _TopicDialogResult {
  _TopicDialogResult({
    required this.name,
    this.imagePath,
    this.clearImage = false,
  });

  final String name;
  final String? imagePath;
  final bool clearImage;
}

class _CourseDialogResult {
  _CourseDialogResult({
    required this.subjectName,
    required this.grade,
    required this.year,
    this.imagePath,
  });

  final String subjectName;
  final int grade;
  final String year;
  final String? imagePath;
}

class _QuestionDialog extends StatefulWidget {
  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  var _type = ExamQuestionType.text;
  final _textCtrl = TextEditingController();
  final _optionCtrl = TextEditingController();
  final _options = <String>[];
  int? _correctIndex;

  @override
  void dispose() {
    _textCtrl.dispose();
    _optionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: const Text('Soru Ekle'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<ExamQuestionType>(
              value: _type,
              items: [
                DropdownMenuItem(
                    value: ExamQuestionType.text,
                    child: Text(strings.t('textQuestion'))),
                DropdownMenuItem(
                    value: ExamQuestionType.image,
                    child: Text(strings.t('imageQuestion'))),
                DropdownMenuItem(
                    value: ExamQuestionType.multipleChoice,
                    child: Text(strings.t('multipleChoice'))),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            if (_type == ExamQuestionType.text || _type == ExamQuestionType.multipleChoice)
              TextField(
                controller: _textCtrl,
                decoration: InputDecoration(labelText: strings.t('questionText')),
                maxLines: 3,
              ),
            if (_type == ExamQuestionType.multipleChoice) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _optionCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('addOption'),
                        hintText: 'Şık girin ve Enter',
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          setState(() {
                            _options.add(v.trim());
                            _optionCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_optionCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _options.add(_optionCtrl.text.trim());
                          _optionCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              ...List.generate(_options.length, (i) => ListTile(
                    dense: true,
                    title: Text(_options[i]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check,
                              color: _correctIndex == i ? Colors.green : null),
                          onPressed: () =>
                              setState(() => _correctIndex = i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () =>
                              setState(() => _options.removeAt(i)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancelSimple')),
        ),
        FilledButton(
          onPressed: () {
            final q = ExamQuestion(
              type: _type,
              value: _textCtrl.text,
              options: _options,
              correctOptionIndex: _correctIndex,
            );
            Navigator.pop(context, q);
          },
          child: Text(strings.t('save')),
        ),
      ],
    );
  }
}

class _BlockPalette extends StatelessWidget {
  const _BlockPalette();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context).t('blockTypes'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: BlockType.values.map((type) {
                return Draggable<BlockType>(
                  data: type,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(type.icon, color: AppColors.brandPrimary),
                          const SizedBox(width: 12),
                          Text(type.displayName),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: _BlockPaletteItem(type: type),
                  ),
                  child: _BlockPaletteItem(type: type),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockPaletteItem extends StatelessWidget {
  const _BlockPaletteItem({required this.type});
  final BlockType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(type.icon, size: 20, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(type.displayName, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.state,
    required this.subjects,
    required this.courses,
    required this.selectedSubjectName,
    required this.courseLabel,
    required this.selectedNode,
    required this.topicContents,
    required this.onSelect,
    required this.onBlockDropped,
    required this.onContentsLoaded,
    required this.onRefresh,
    required this.onDeleteBlock,
    required this.onEditBlock,
    required this.onSubjectChanged,
    required this.onCourseChanged,
  });

  final AppState state;
  final List<SubjectSummary> subjects;
  final List<LessonModel> courses;
  final String? selectedSubjectName;
  final String Function(LessonModel) courseLabel;
  final Object? selectedNode;
  final List<cwt.ContentWithTags> topicContents;
  final void Function(Object?) onSelect;
  final void Function(BlockType type) onBlockDropped;
  final void Function(List<cwt.ContentWithTags>) onContentsLoaded;
  final VoidCallback onRefresh;
  final void Function(cwt.ContentWithTags) onDeleteBlock;
  final void Function(cwt.ContentWithTags) onEditBlock;
  final Future<void> Function(String?) onSubjectChanged;
  final Future<void> Function(LessonModel?) onCourseChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final uniqueTopics = _uniqueById(state.topics, (t) => t.id);
    final uniqueUnits = _uniqueById(state.units, (u) => u.id);
    final selectedCourse = state.selectedLesson == null
        ? null
        : courses.where((c) => c.id == state.selectedLesson!.id).firstOrNull ??
            state.selectedLesson as LessonModel?;
    final selectedUnit = _matchById(
      uniqueUnits,
      state.selectedUnit as UnitModel?,
      (u) => u.id,
    );
    final unitTopics = selectedUnit == null
        ? <TopicModel>[]
        : uniqueTopics
            .where((t) => t.unitId == selectedUnit.id)
            .toList();
    final selectedTopic = _matchById(
      unitTopics,
      state.selectedTopic as TopicModel?,
      (t) => t.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            strings.t('courseStructure'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSubjectName,
                      hint: Text(strings.t('selectSubject')),
                      items: subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        await onSubjectChanged(value);
                        onContentsLoaded([]);
                        onRefresh();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<LessonModel>(
                      isExpanded: true,
                      value: selectedCourse,
                      hint: Text(strings.t('selectCourse')),
                      items: courses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(courseLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: selectedSubjectName == null
                          ? null
                          : (value) async {
                              await onCourseChanged(value);
                              onContentsLoaded([]);
                              onRefresh();
                            },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<UnitModel>(
                      isExpanded: true,
                      value: selectedUnit,
                      hint: Text(strings.t('selectUnit')),
                      items: uniqueUnits
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text('${u.number}. ${u.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: selectedCourse == null
                          ? null
                          : (v) {
                              state.selectUnit(v);
                              onContentsLoaded([]);
                              onRefresh();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<TopicModel>(
                      isExpanded: true,
                      value: selectedTopic,
                      hint: Text(strings.t('selectTopic')),
                      items: unitTopics
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: selectedUnit == null
                          ? null
                          : (v) {
                              state.selectTopic(v);
                              if (v != null) {
                                state.db
                                    .getContentsWithTagsByTopic(v.id)
                                    .then(onContentsLoaded);
                              } else {
                                onContentsLoaded([]);
                              }
                              onRefresh();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: state.selectedTopic == null
              ? Center(child: Text(strings.t('selectTopicForPreview')))
              : DragTarget<BlockType>(
                  onAcceptWithDetails: (d) => onBlockDropped(d.data),
                  builder: (context, candidateData, rejectedData) {
                    return FutureBuilder<List<cwt.ContentWithTags>>(
                      future: state.selectedTopic != null
                          ? state.db.getContentsWithTagsByTopic(
                              (state.selectedTopic as TopicModel).id)
                          : Future.value([]),
                      builder: (context, snapshot) {
                        final contents = snapshot.data ?? [];
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: candidateData.isNotEmpty
                                ? Colors.blue.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: candidateData.isNotEmpty
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: candidateData.isNotEmpty ? 2 : 1,
                            ),
                          ),
                          child: contents.isEmpty
                              ? Center(
                                  child: Text(
                                    strings.t('noContents'),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : Material(
                                  color: Colors.transparent,
                                  child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: contents.length,
                                  itemBuilder: (context, i) {
                                    final c = contents[i];
                                    final type =
                                        BlockTypeX.fromCode(c.content.type);
                                    final strings =
                                        AppLocalizations.of(context);
                                    return ListTile(
                                      leading: Icon(type.icon),
                                      title: Text(c.content.name),
                                      onTap: () => onEditBlock(c),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                            tooltip: strings.t('edit'),
                                            onPressed: () => onEditBlock(c),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 20, color: Colors.red),
                                            tooltip: strings.t('delete'),
                                            onPressed: () => onDeleteBlock(c),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.selectedNode,
    required this.state,
    required this.selectedSubjectName,
    required this.onChanged,
    required this.strings,
    required this.onAddSubject,
    required this.onAddCourse,
    required this.onAddUnit,
    required this.onAddTopic,
    required this.onEditSubject,
    required this.onEditCourse,
    required this.onEditUnit,
    required this.onEditTopic,
    required this.onDeleteSubject,
    required this.onDeleteCourse,
    required this.onDeleteUnit,
    required this.onDeleteTopic,
  });

  final Object? selectedNode;
  final AppState state;
  final String? selectedSubjectName;
  final VoidCallback onChanged;
  final AppLocalizations strings;
  final VoidCallback onAddSubject;
  final VoidCallback onAddCourse;
  final VoidCallback onAddUnit;
  final VoidCallback onAddTopic;
  final VoidCallback onEditSubject;
  final VoidCallback onEditCourse;
  final VoidCallback onEditUnit;
  final VoidCallback onEditTopic;
  final VoidCallback onDeleteSubject;
  final VoidCallback onDeleteCourse;
  final VoidCallback onDeleteUnit;
  final VoidCallback onDeleteTopic;

  @override
  Widget build(BuildContext context) {
    final primaryBtn = FilledButton.styleFrom(
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: Colors.white,
    );
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: AppColors.brandPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.t('builderStructureSettings'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: primaryBtn,
                    onPressed: onAddSubject,
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addSubject')),
                  ),
                  if (selectedSubjectName != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEditSubject,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(strings.t('editSubject')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.accentRed),
                          tooltip: strings.t('delete'),
                          onPressed: onDeleteSubject,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAddCourse,
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addCourse')),
                  ),
                  if (state.selectedLesson != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEditCourse,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(strings.t('editCourse')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.accentRed),
                          tooltip: strings.t('delete'),
                          onPressed: onDeleteCourse,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        state.selectedLesson == null ? null : onAddUnit,
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addUnit')),
                  ),
                  if (state.selectedUnit != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEditUnit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(strings.t('editUnit')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.accentRed),
                          tooltip: strings.t('delete'),
                          onPressed: onDeleteUnit,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.selectedUnit == null ? null : onAddTopic,
                    icon: const Icon(Icons.add),
                    label: Text(strings.t('addTopic')),
                  ),
                  if (state.selectedTopic != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEditTopic,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(strings.t('editTopic')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.accentRed),
                          tooltip: strings.t('delete'),
                          onPressed: onDeleteTopic,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    strings.t('builderDragHint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<T> _uniqueById<T>(List<T> items, int Function(T) idOf) {
  final unique = <int, T>{};
  for (final item in items) {
    unique[idOf(item)] = item;
  }
  return unique.values.toList();
}

T? _matchById<T>(List<T> items, T? selected, int Function(T) idOf) {
  if (selected == null) return null;
  final selectedId = idOf(selected);
  for (final item in items) {
    if (idOf(item) == selectedId) return item;
  }
  return null;
}


