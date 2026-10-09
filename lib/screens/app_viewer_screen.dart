import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/content_item.dart';
import '../data/models/document_folder_model.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../data/models/unit_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/app_navigation.dart';
import '../utils/teacher_nav_section.dart';
import '../utils/student_navigation.dart';
import '../utils/teacher_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_card.dart';
import '../widgets/content_preview.dart';
import '../widgets/folder_content_multi_picker.dart';
import '../widgets/lesson_platform_content_nav.dart';
import '../widgets/lesson_platform_page.dart';
import '../utils/teacher_activity.dart';
import 'settings_screen.dart';

enum _ViewerLevel {
  subjects,
  subjectDetail,
  courseDetail,
  unitDetail,
  topicDetail,
}

Future<void> _onAppViewerBackPressed(
  BuildContext context, {
  required bool Function() onInnerBack,
}) async {
  if (onInnerBack()) return;
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
    return;
  }
  final confirmed = await confirmLeavePage(context);
  if (confirmed && context.mounted) {
    popToPreviousOrLogin(context);
  }
}

class AppViewerScreen extends StatefulWidget {
  const AppViewerScreen({super.key, this.embeddedDocumentsMode = false});

  /// Reuses document folders UI inside [AcademicPlansScreen] (no outer shell).
  final bool embeddedDocumentsMode;

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen> {
  _ViewerLevel _level = _ViewerLevel.subjects;
  LessonPlatformSidebarSection _sidebarSection =
      LessonPlatformSidebarSection.subjects;
  String _searchQuery = '';
  String? _subjectName;
  List<SubjectSummary> _subjects = [];
  List<LessonModel> _courses = [];
  List<UnitModel> _tabUnits = [];
  List<TopicModel> _tabTopics = [];
  List<ContentItem> _tabDocuments = [];
  List<DocumentFolder> _documentFolders = [];
  List<DocumentFolder> _childDocumentFolders = [];
  List<DocumentFolder> _folderBreadcrumb = [];
  List<FolderPickerContent> _folderContents = [];
  Map<int, int> _folderItemCounts = {};
  Map<int, int> _folderChildCounts = {};
  Map<int, int> _contentReadingPages = {};
  int? _openDocumentFolderId;
  DocumentFolder? _activeDocumentFolder;
  String _folderSearchQuery = '';
  String _folderContentSearchQuery = '';
  Map<int, int> _unitTopicCounts = {};
  bool _loading = true;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    if (widget.embeddedDocumentsMode) {
      _sidebarSection = LessonPlatformSidebarSection.documents;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyLessonPlatformNavigationRequest();
      _loadSectionData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AppState>();
    if (_appState != next) {
      _appState?.removeListener(_onAppStateNavigationRequest);
      _appState = next;
      _appState!.addListener(_onAppStateNavigationRequest);
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateNavigationRequest);
    super.dispose();
  }

  void _onAppStateNavigationRequest() {
    _applyLessonPlatformNavigationRequest();
  }

  void _applyLessonPlatformNavigationRequest() {
    final state = _appState ?? context.read<AppState>();
    if (!widget.embeddedDocumentsMode) {
      if (state.activeTeacherTab != TeacherNavSection.lessonPlatform) {
        return;
      }
      final openDocuments = state.takePendingOpenLessonPlatformDocuments();
      final folderId = state.takePendingDocumentFolderId();
      if (!openDocuments && folderId == null) {
        return;
      }
      if (folderId != null) {
        state.requestOpenDocumentFolder(folderId);
      } else {
        state.requestOpenLessonPlatformDocuments();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          redirectLessonPlatformDocumentsToAcademicPlans(context);
        }
      });
      return;
    }
    state.takePendingOpenLessonPlatformDocuments();
    final folderId = state.takePendingDocumentFolderId();
    setState(() {
      _sidebarSection = LessonPlatformSidebarSection.documents;
      _level = _ViewerLevel.subjects;
      if (folderId != null) {
        _openDocumentFolderId = folderId;
        _folderContentSearchQuery = '';
      }
    });
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    final state = context.read<AppState>();
    setState(() => _loading = true);
    try {
      switch (_sidebarSection) {
        case LessonPlatformSidebarSection.subjects:
          _subjects = await state.db.getSubjects();
        case LessonPlatformSidebarSection.courses:
          _courses = await _loadAllCourses(state);
        case LessonPlatformSidebarSection.units:
          final course = state.selectedLesson as LessonModel?;
          if (course != null) {
            _tabUnits = await state.db.getUnits(course.id);
            _unitTopicCounts =
                await state.db.getTopicCountsByUnitForLesson(course.id);
          } else {
            _tabUnits = [];
          }
        case LessonPlatformSidebarSection.topics:
          final course = state.selectedLesson as LessonModel?;
          final unit = state.selectedUnit as UnitModel?;
          if (course != null && unit != null) {
            final rows =
                await state.db.getTopicsRaw(course.id, unitId: unit.id);
            _tabTopics = rows.map(TopicModel.fromMap).toList();
          } else {
            _tabTopics = [];
          }
        case LessonPlatformSidebarSection.documents:
          _folderItemCounts = await state.db.getDocumentFolderItemCounts();
          _folderChildCounts = await state.db.getDocumentFolderChildCounts();
          if (_openDocumentFolderId != null) {
            _activeDocumentFolder =
                await state.db.getDocumentFolderById(_openDocumentFolderId!);
            _folderBreadcrumb = await state.db.getDocumentFolderPath(
              _openDocumentFolderId!,
            );
            _childDocumentFolders = await state.db.getDocumentFolders(
              parentId: _openDocumentFolderId,
            );
            _documentFolders = [];
            _folderContents =
                await state.db.getFolderContents(_openDocumentFolderId!);
            _contentReadingPages = await state.db.getContentReadingPages(
              _folderContents.map((r) => r.item.id),
            );
          } else {
            _activeDocumentFolder = null;
            _folderBreadcrumb = [];
            _childDocumentFolders = [];
            _documentFolders = await state.db.getDocumentFolders();
            _folderContents = [];
            _folderContentSearchQuery = '';
            _contentReadingPages = {};
          }
          _tabDocuments = _folderContents.map((r) => r.item).toList();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<LessonModel>> _loadAllCourses(AppState state) async {
    final subjects = await state.db.getSubjects();
    final all = <LessonModel>[];
    for (final subject in subjects) {
      all.addAll(await state.db.getCoursesForSubject(subject.name));
    }
    return all;
  }

  void _onSidebarSectionChanged(LessonPlatformSidebarSection section) {
    if (!widget.embeddedDocumentsMode &&
        section == LessonPlatformSidebarSection.documents) {
      redirectLessonPlatformDocumentsToAcademicPlans(context);
      return;
    }
    final state = context.read<AppState>();
    setState(() {
      _sidebarSection = section;
      switch (section) {
        case LessonPlatformSidebarSection.subjects:
          _level = _ViewerLevel.subjects;
          _subjectName = null;
          _unitTopicCounts = {};
        case LessonPlatformSidebarSection.courses:
          _level = _subjectName != null
              ? _ViewerLevel.subjectDetail
              : _ViewerLevel.subjects;
        case LessonPlatformSidebarSection.units:
          if (state.selectedLesson != null) {
            _level = _ViewerLevel.courseDetail;
          } else {
            _level = _ViewerLevel.subjects;
            _tabUnits = [];
          }
        case LessonPlatformSidebarSection.topics:
          if (state.selectedUnit != null) {
            _level = _ViewerLevel.unitDetail;
          } else {
            _level = _ViewerLevel.subjects;
            _tabTopics = [];
          }
        case LessonPlatformSidebarSection.documents:
          _level = _ViewerLevel.subjects;
          _openDocumentFolderId = null;
          _folderSearchQuery = '';
          _folderContentSearchQuery = '';
      }
    });
    _loadSectionData();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _level = _ViewerLevel.subjects;
      _subjectName = null;
      _unitTopicCounts = {};
    });
    await _loadSectionData();
  }

  Future<void> _openSubject(SubjectSummary subject) async {
    final state = context.read<AppState>();
    final courses = await state.db.getCoursesForSubject(subject.name);
    if (!mounted) return;
    setState(() {
      _subjectName = subject.name;
      _courses = courses;
      _level = _ViewerLevel.subjectDetail;
    });
  }

  Future<void> _openCourse(LessonModel course) async {
    final state = context.read<AppState>();
    await state.openCourse(course);
    final topicCounts =
        await state.db.getTopicCountsByUnitForLesson(course.id);
    if (!mounted) return;
    setState(() {
      _subjectName ??= course.name;
      _unitTopicCounts = topicCounts;
      _level = _ViewerLevel.courseDetail;
    });
  }

  Future<void> _openUnit(UnitModel unit) async {
    final state = context.read<AppState>();
    final course = state.selectedLesson as LessonModel?;
    if (course == null || course.id != unit.lessonId) {
      final row = await state.db.getLessonById(unit.lessonId);
      if (row != null) {
        await _openCourse(LessonModel.fromMap(row));
      }
    }
    final resolved = state.units.cast<UnitModel?>().firstWhere(
          (u) => u?.id == unit.id,
          orElse: () => unit,
        ) ??
        unit;
    state.selectUnit(resolved, autoSelectFirstTopic: false);
    if (!mounted) return;
    setState(() {
      _level = _ViewerLevel.unitDetail;
    });
  }

  Future<void> _openTopic(TopicModel topic) async {
    final state = context.read<AppState>();
    final course = state.selectedLesson as LessonModel?;
    if (course == null || course.id != topic.lessonId) {
      final row = await state.db.getLessonById(topic.lessonId);
      if (row != null) {
        await _openCourse(LessonModel.fromMap(row));
      }
    }
    if (topic.unitId != null) {
      final unit = state.units.cast<UnitModel?>().firstWhere(
            (u) => u?.id == topic.unitId,
            orElse: () => null,
          );
      if (unit != null) {
        state.selectUnit(unit, autoSelectFirstTopic: false);
      }
    }
    state.selectTopic(topic);
    if (!mounted) return;
    setState(() {
      _level = _ViewerLevel.topicDetail;
    });
  }

  bool _isPdfContent(ContentItem item) {
    if (item.type == 'pdf') return true;
    final path = item.path.toLowerCase();
    return path.endsWith('.pdf');
  }

  bool _isHomeworkContent(ContentItem item) {
    if (item.type == 'homework') return true;
    if (item.type == 'text') {
      final name = item.name.toLowerCase();
      return name.contains('ödev') || name == 'ödev';
    }
    return false;
  }

  String _contentTypeLabel(AppLocalizations strings, ContentItem item) {
    if (_isHomeworkContent(item)) {
      return strings.t('homeworkBlock');
    }
    return item.type;
  }

  Future<void> _openDocumentFromFolder(
    BuildContext context,
    AppState state,
    ContentItem item,
  ) async {
    if (item.topicId == null) {
      final lessonRow = await state.db.getLessonById(item.lessonId);
      if (lessonRow != null) {
        await state.openCourse(LessonModel.fromMap(lessonRow));
      }
      if (!context.mounted) return;
      final model = ContentModel(
        id: item.id,
        title: item.name,
        contentItem: item,
      );
      await showAppDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          child: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width * 0.85,
            height: MediaQuery.sizeOf(dialogContext).height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ContentPreview(
                    title: item.name,
                    selectedContent: model,
                    fillViewport: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!context.mounted) return;
      final progress = await state.db.getContentReadingProgress(item.id);
      if (progress != null) {
        setState(() => _contentReadingPages[item.id] = progress.lastPage);
      }
      return;
    }
    await _openDocument(state, item);
  }

  Future<void> _openDocument(AppState state, ContentItem item) async {
    if (item.topicId == null) return;
    final topicRow = await state.db.getTopicById(item.topicId!);
    if (topicRow == null) return;
    final topic = TopicModel.fromMap(topicRow);
    LessonModel? course = _courses
        .cast<LessonModel?>()
        .firstWhere(
          (c) => c?.id == item.lessonId,
          orElse: () => null,
        );
    if (course == null) {
      final row = await state.db.getLessonById(item.lessonId);
      if (row != null) {
        course = LessonModel.fromMap(row);
        _subjectName ??= course.name;
      }
    }
    course ??= state.selectedLesson as LessonModel?;
    if (course != null &&
        (state.selectedLesson == null ||
            (state.selectedLesson as LessonModel).id != course.id)) {
      await state.openCourse(course);
    }
    if (topic.unitId != null) {
      final unit = state.units.cast<UnitModel?>().firstWhere(
            (u) => u?.id == topic.unitId,
            orElse: () => null,
          );
      if (unit != null) {
        state.selectUnit(unit, autoSelectFirstTopic: false);
      }
    }
    state.selectTopic(topic);
    if (!mounted) return;
    setState(() {
      _level = _ViewerLevel.topicDetail;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final match = state.filteredContents
          .where((c) => c.id == item.id)
          .firstOrNull;
      if (match != null) state.selectContent(match);
    });
  }

  bool _goUp() {
    if (_sidebarSection == LessonPlatformSidebarSection.documents &&
        _openDocumentFolderId != null) {
      setState(() {
        _openDocumentFolderId = _activeDocumentFolder?.parentId;
        _folderContentSearchQuery = '';
      });
      _loadSectionData();
      return true;
    }
    switch (_level) {
      case _ViewerLevel.topicDetail:
        setState(() => _level = _ViewerLevel.unitDetail);
        return true;
      case _ViewerLevel.unitDetail:
        setState(() => _level = _ViewerLevel.courseDetail);
        return true;
      case _ViewerLevel.courseDetail:
        setState(() => _level = _ViewerLevel.subjectDetail);
        return true;
      case _ViewerLevel.subjectDetail:
        _loadSubjects();
        return true;
      case _ViewerLevel.subjects:
        return false;
    }
  }

  String _courseDisplayName(LessonModel? course) {
    if (course == null) return '';
    final className = course.className ?? '';
    if (className.isNotEmpty) return '${course.name} $className';
    return course.name;
  }

  List<LessonPlatformNavSegment> _buildDocumentNavSegments(
    AppLocalizations strings,
  ) {
    final root = widget.embeddedDocumentsMode
        ? strings.t('academicPlans')
        : strings.t('goToApp');
    final docs = strings.t('documents');
    final segments = <LessonPlatformNavSegment>[
      LessonPlatformNavSegment(label: root),
      LessonPlatformNavSegment(
        label: docs,
        onTap: _openDocumentFolderId == null
            ? null
            : () => _navigateToDocumentFolder(null),
      ),
    ];
    for (var i = 0; i < _folderBreadcrumb.length; i++) {
      final folder = _folderBreadcrumb[i];
      final isLast = i == _folderBreadcrumb.length - 1;
      segments.add(
        LessonPlatformNavSegment(
          label: folder.name,
          onTap: isLast
              ? null
              : () => _navigateToDocumentFolder(folder.id),
        ),
      );
    }
    return segments;
  }

  List<LessonPlatformNavSegment> _buildNavSegments(
    AppLocalizations strings,
    AppState state,
  ) {
    final root = strings.t('goToApp');
    switch (_level) {
      case _ViewerLevel.subjects:
        return [
          LessonPlatformNavSegment(label: root),
          LessonPlatformNavSegment(label: strings.t('subjects')),
        ];
      case _ViewerLevel.subjectDetail:
        return [
          LessonPlatformNavSegment(label: root),
          if (_subjectName != null)
            LessonPlatformNavSegment(label: _subjectName!),
        ];
      case _ViewerLevel.courseDetail:
        final course = state.selectedLesson as LessonModel?;
        return [
          LessonPlatformNavSegment(label: root),
          if (_subjectName != null)
            LessonPlatformNavSegment(label: _subjectName!),
          if (course != null)
            LessonPlatformNavSegment(label: _courseDisplayName(course)),
        ];
      case _ViewerLevel.unitDetail:
        final course = state.selectedLesson as LessonModel?;
        final unit = state.selectedUnit as UnitModel?;
        return [
          LessonPlatformNavSegment(label: root),
          if (_subjectName != null)
            LessonPlatformNavSegment(label: _subjectName!),
          if (course != null)
            LessonPlatformNavSegment(label: _courseDisplayName(course)),
          if (unit != null)
            LessonPlatformNavSegment(label: '${unit.number}. ${unit.name}'),
        ];
      case _ViewerLevel.topicDetail:
        final course = state.selectedLesson as LessonModel?;
        final unit = state.selectedUnit as UnitModel?;
        final topic = state.selectedTopic as TopicModel?;
        return [
          LessonPlatformNavSegment(label: root),
          if (_subjectName != null)
            LessonPlatformNavSegment(label: _subjectName!),
          if (course != null)
            LessonPlatformNavSegment(label: _courseDisplayName(course)),
          if (unit != null)
            LessonPlatformNavSegment(
              label: '${unit.number}. ${unit.name}',
            ),
          if (topic != null) LessonPlatformNavSegment(label: topic.name),
        ];
    }
  }

  Widget _buildEmbeddedDocuments(BuildContext context, AppState state) {
    final strings = AppLocalizations.of(context);
    final isTeacher = state.isTeacher;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonPlatformContentNav(
          segments: _buildDocumentNavSegments(strings),
        ),
        if (_openDocumentFolderId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _onAppViewerBackPressed(
                context,
                onInnerBack: _goUp,
              ),
              tooltip: strings.t('goHome'),
            ),
          ),
        Expanded(
          child: _openDocumentFolderId == null
              ? _buildDocumentFoldersHome(context, state, strings, isTeacher)
              : _buildDocumentFolderDetail(
                  context,
                  state,
                  strings,
                  isTeacher,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (widget.embeddedDocumentsMode) {
          return _buildEmbeddedDocuments(context, state);
        }
        final isTeacher = state.isTeacher;
        if (state.isStudent && !studentLessonViewerRoute(context)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) openStudentPortal(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final headerActions = <Widget>[
          if (_level == _ViewerLevel.topicDetail)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'lesson') {
                  final path = await FilePicker.platform.saveFile(
                    dialogTitle: strings.t('exportLesson'),
                    fileName: 'lesson_export.zip',
                    allowedExtensions: ['zip'],
                    type: FileType.custom,
                  );
                  if (path != null) await state.exportLessonZip(path);
                }
                if (value == 'topic') {
                  final path = await FilePicker.platform.saveFile(
                    dialogTitle: strings.t('exportTopic'),
                    fileName: 'topic_export.zip',
                    allowedExtensions: ['zip'],
                    type: FileType.custom,
                  );
                  if (path != null) await state.exportTopicZip(path);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'lesson',
                  child: Text(strings.t('exportLesson')),
                ),
                PopupMenuItem(
                  value: 'topic',
                  child: Text(strings.t('exportTopic')),
                ),
              ],
              icon: const Icon(Icons.archive_outlined),
              tooltip: strings.t('exportZip'),
            ),
          if (isTeacher)
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SettingsScreen.routeName),
              icon: const Icon(Icons.settings_outlined),
              tooltip: strings.t('settings'),
            ),
        ];

        return AppShell(
          constrainContent: false,
          teacherSection: isTeacher ? TeacherNavSection.lessonPlatform : null,
          studentSection: isTeacher ? null : StudentNavSection.courses,
          lessonPlatformSection: _sidebarSection,
          onLessonPlatformSectionChanged: _onSidebarSectionChanged,
          compactHeader: _level == _ViewerLevel.topicDetail,
          title: _level == _ViewerLevel.topicDetail
              ? ((state.selectedTopic as TopicModel?)?.name ??
                  strings.t('goToApp'))
              : strings.t('goToApp'),
          leading: _level != _ViewerLevel.subjects ||
                  (_sidebarSection == LessonPlatformSidebarSection.documents &&
                      _openDocumentFolderId != null)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _onAppViewerBackPressed(
                    context,
                    onInnerBack: _goUp,
                  ),
                  tooltip: strings.t('goHome'),
                )
              : null,
          actions: headerActions,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, state, strings, isTeacher),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    final showCourseNav = _level != _ViewerLevel.subjects;
    final showDocumentNav =
        _sidebarSection == LessonPlatformSidebarSection.documents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCourseNav)
          LessonPlatformContentNav(segments: _buildNavSegments(strings, state)),
        if (showDocumentNav)
          LessonPlatformContentNav(
            segments: _buildDocumentNavSegments(strings),
          ),
        Expanded(child: _buildLevelBody(context, state, strings, isTeacher)),
      ],
    );
  }

  Widget _buildLevelBody(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    return switch (_level) {
      _ViewerLevel.subjects =>
        _buildSectionList(context, state, strings, isTeacher),
      _ViewerLevel.subjectDetail =>
        _buildCoursesGrid(context, strings, isTeacher, _courses),
      _ViewerLevel.courseDetail =>
        _buildUnitsGrid(context, state, strings, isTeacher),
      _ViewerLevel.unitDetail =>
        _buildTopicsGrid(context, state, strings, isTeacher),
      _ViewerLevel.topicDetail =>
        _buildTopicDetail(context, state, strings, isTeacher),
    };
  }

  Widget _buildSectionList(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    return switch (_sidebarSection) {
      LessonPlatformSidebarSection.subjects =>
        _buildSubjectsHome(context, strings, isTeacher),
      LessonPlatformSidebarSection.courses =>
        _buildCoursesGrid(context, strings, isTeacher, _courses),
      LessonPlatformSidebarSection.units =>
        _buildUnitsGrid(context, state, strings, isTeacher, units: _tabUnits),
      LessonPlatformSidebarSection.topics =>
        _buildTopicsGrid(
          context,
          state,
          strings,
          isTeacher,
          topics: _tabTopics,
        ),
      LessonPlatformSidebarSection.documents =>
        _openDocumentFolderId == null
            ? _buildDocumentFoldersHome(context, state, strings, isTeacher)
            : _buildDocumentFolderDetail(
                context,
                state,
                strings,
                isTeacher,
              ),
    };
  }

  Widget _buildSubjectsHome(
    BuildContext context,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    final filtered = _searchQuery.trim().isEmpty
        ? _subjects
        : _subjects
            .where(
              (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.auto_stories_outlined,
        title: strings.t('noLessons'),
      );
    }
    return LessonPlatformScrollBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonPlatformHomeHeader(
            subtitle: strings.t('lessonPlatformSubtitle'),
            searchHint: strings.t('searchSubjects'),
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            action: isTeacher
                ? FilledButton.icon(
                    onPressed: () => openLessonBuilder(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(strings.t('addNewSubject')),
                  )
                : null,
          ),
          LessonPlatformSectionTitle(
            title: strings.t('subjects'),
            count: filtered.length,
          ),
          _EntityGrid(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final subject = filtered[index];
              return LessonPlatformCompactCard(
                title: subject.name,
                imagePath: subject.imagePath,
                metaParts: [
                  '${subject.courseCount} ${strings.t('courses')}',
                  '${subject.unitCount} ${strings.t('units')}',
                  '${subject.topicCount} ${strings.t('topics')}',
                ],
                onTap: () => _openSubject(subject),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesGrid(
    BuildContext context,
    AppLocalizations strings,
    bool isTeacher,
    List<LessonModel> courses,
  ) {
    if (courses.isEmpty) {
      return AppEmptyState(
        icon: Icons.library_books_outlined,
        title: strings.t('noCourses'),
      );
    }
    return LessonPlatformScrollBody(
      padding: EdgeInsets.all(
        context.isMobileLayout ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTeacher && _level == _ViewerLevel.subjectDetail)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => openLessonBuilder(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.t('addNewCourse')),
              ),
            ),
          if (isTeacher && _level == _ViewerLevel.subjectDetail)
            const SizedBox(height: AppSpacing.sm),
          _EntityGrid(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final className = course.className ?? '';
              return LessonPlatformCompactCard(
                title: _courseDisplayName(course),
                imagePath: course.imagePath,
                metaParts: [
                  if (course.academicYear.isNotEmpty) course.academicYear,
                  if (className.isNotEmpty) className,
                  '${course.unitCount} ${strings.t('units')}',
                  '${course.topicCount} ${strings.t('topics')}',
                ],
                onTap: () => _openCourse(course),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsGrid(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher, {
    List<UnitModel>? units,
  }) {
    final list = _level == _ViewerLevel.courseDetail
        ? state.units
        : (units ?? const <UnitModel>[]);
    if (list.isEmpty) {
      return AppEmptyState(
        icon: Icons.view_module_outlined,
        title: strings.t('noUnits'),
      );
    }
    return LessonPlatformScrollBody(
      padding: EdgeInsets.all(
        context.isMobileLayout ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTeacher && _level == _ViewerLevel.courseDetail)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => openLessonBuilder(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.t('addNewUnit')),
              ),
            ),
          if (isTeacher && _level == _ViewerLevel.courseDetail)
            const SizedBox(height: AppSpacing.sm),
          _EntityGrid(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final unit = list[index];
              final count = _unitTopicCounts[unit.id] ?? 0;
              return LessonPlatformCompactCard(
                title: '${unit.number}. ${unit.name}',
                imagePath: unit.imagePath,
                metaParts: ['$count ${strings.t('topics')}'],
                onTap: () => _openUnit(unit),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsGrid(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher, {
    List<TopicModel>? topics,
  }) {
    final list = _level == _ViewerLevel.unitDetail
        ? state.topics
        : (topics ?? const <TopicModel>[]);
    if (list.isEmpty) {
      return AppEmptyState(
        icon: Icons.topic_outlined,
        title: strings.t('noTopics'),
      );
    }
    return LessonPlatformScrollBody(
      padding: EdgeInsets.all(
        context.isMobileLayout ? AppSpacing.sm : AppSpacing.md,
      ),
      child: _EntityGrid(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final topic = list[index];
          return LessonPlatformCompactCard(
            title: topic.name,
            imagePath: topic.imagePath,
            onTap: () => _openTopic(topic),
          );
        },
      ),
    );
  }

  Future<void> _openDocumentFolder(DocumentFolder folder) async {
    setState(() {
      _openDocumentFolderId = folder.id;
      _folderContentSearchQuery = '';
    });
    await _loadSectionData();
  }

  String _folderItemCountLabel(AppLocalizations strings, int count) {
    return '$count ${strings.t('folderContentItems')}';
  }

  String _folderContentContextLabel(FolderPickerContent row) {
    return [
      row.lessonName,
      row.topicName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' / ');
  }

  Future<void> _navigateToDocumentFolder(int? folderId) async {
    setState(() {
      _openDocumentFolderId = folderId;
      _folderContentSearchQuery = '';
    });
    await _loadSectionData();
  }

  Future<void> _createDocumentFolder(
    BuildContext context,
    AppState state,
    AppLocalizations strings, {
    int? parentId,
  }) async {
    final isSubfolder = parentId != null;
    final name = await _promptFolderName(
      context,
      strings,
      title: isSubfolder ? strings.t('newSubfolder') : strings.t('newFolder'),
    );
    if (name == null || name.trim().isEmpty) return;
    final folderId = await state.db.insertDocumentFolder(
      name.trim(),
      parentId: parentId ?? _openDocumentFolderId,
    );
    await state.recordTeacherActivity(
      type: TeacherActivityTypes.folderCreated,
      title: name.trim(),
      targetType: TeacherActivityTargets.documentFolder,
      targetId: folderId,
    );
    await _loadSectionData();
  }

  String _folderCardMeta(
    AppLocalizations strings,
    int folderId,
  ) {
    final parts = <String>[];
    final itemCount = _folderItemCounts[folderId] ?? 0;
    parts.add(_folderItemCountLabel(strings, itemCount));
    final childCount = _folderChildCounts[folderId] ?? 0;
    if (childCount > 0) {
      parts.add('$childCount ${strings.t('childFoldersCount')}');
    }
    return parts.join(' · ');
  }

  Widget? _folderTeacherMenu(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    DocumentFolder folder,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'rename') {
          final name = await _promptFolderName(
            context,
            strings,
            title: strings.t('renameFolder'),
            initial: folder.name,
          );
          if (name != null && name.trim().isNotEmpty) {
            await state.db.updateDocumentFolderName(folder.id, name.trim());
            await _loadSectionData();
          }
        } else if (value == 'delete') {
          await _confirmDeleteFolder(context, state, strings, folder);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'rename',
          child: Text(strings.t('renameFolder')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(strings.t('delete')),
        ),
      ],
    );
  }

  Future<String?> _promptFolderName(
    BuildContext context,
    AppLocalizations strings, {
    required String title,
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: strings.t('folderName')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _buildDocumentFoldersHome(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    final filteredFolders = _folderSearchQuery.trim().isEmpty
        ? _documentFolders
        : _documentFolders
            .where(
              (f) => f.name
                  .toLowerCase()
                  .contains(_folderSearchQuery.toLowerCase()),
            )
            .toList();
    if (_documentFolders.isEmpty) {
      return LessonPlatformScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonPlatformHomeHeader(
              subtitle: strings.t('documentsSubtitle'),
              searchHint: strings.t('searchFolders'),
              searchQuery: _folderSearchQuery,
              onSearchChanged: (v) => setState(() => _folderSearchQuery = v),
              action: isTeacher
                  ? FilledButton.icon(
                      onPressed: () =>
                          _createDocumentFolder(context, state, strings),
                      icon: const Icon(Icons.create_new_folder, size: 18),
                      label: Text(strings.t('newFolder')),
                    )
                  : null,
            ),
            AppEmptyState(
              icon: Icons.folder_outlined,
              title: strings.t('noFolders'),
            ),
          ],
        ),
      );
    }
    return LessonPlatformScrollBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonPlatformHomeHeader(
            subtitle: strings.t('documentsSubtitle'),
            searchHint: strings.t('searchFolders'),
            searchQuery: _folderSearchQuery,
            onSearchChanged: (v) => setState(() => _folderSearchQuery = v),
            action: isTeacher
                ? FilledButton.icon(
                    onPressed: () =>
                        _createDocumentFolder(context, state, strings),
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: Text(strings.t('newFolder')),
                  )
                : null,
          ),
          LessonPlatformSectionTitle(
            title: strings.t('documents'),
            count: filteredFolders.length,
          ),
          if (filteredFolders.isEmpty)
            AppEmptyState(
              icon: Icons.search_off,
              title: strings.t('noFolderSearchResults'),
            )
          else
            _EntityGrid(
              itemCount: filteredFolders.length,
              itemBuilder: (context, index) {
                final folder = filteredFolders[index];
                return LessonPlatformCompactCard(
                  title: folder.name,
                  headerIcon: Icons.folder_outlined,
                  metaParts: [_folderCardMeta(strings, folder.id)],
                  onTap: () => _openDocumentFolder(folder),
                  trailing: isTeacher
                      ? _folderTeacherMenu(context, state, strings, folder)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    DocumentFolder folder,
  ) async {
    final hasChildren = (_folderChildCounts[folder.id] ?? 0) > 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(
          hasChildren
              ? strings.t('deleteFolderConfirmNested')
              : strings.t('deleteFolderConfirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('yes')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_openDocumentFolderId == folder.id) {
      _openDocumentFolderId = folder.parentId;
    }
    await state.db.deleteDocumentFolder(folder.id);
    await _loadSectionData();
  }

  Widget _buildDocumentFolderDetail(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    final folderName = _activeDocumentFolder?.name ?? '';
    final folderId = _openDocumentFolderId;
    final query = _folderContentSearchQuery.trim().toLowerCase();
    final filteredSubfolders = query.isEmpty
        ? _childDocumentFolders
        : _childDocumentFolders
            .where((f) => f.name.toLowerCase().contains(query))
            .toList();
    final filtered = query.isEmpty
        ? _folderContents
        : _folderContents
            .where((row) => row.item.name.toLowerCase().contains(query))
            .toList();
    final hasAnything = _childDocumentFolders.isNotEmpty ||
        _folderContents.isNotEmpty;
    final showSearch = hasAnything;

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: EdgeInsets.all(
          context.isMobileLayout ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonPlatformContextHeader(
              title: folderName,
              subtitle: strings.t('documents'),
              stats: [
                LessonPlatformStatItem(
                  label: strings.t('subfolders'),
                  value: '${_childDocumentFolders.length}',
                ),
                LessonPlatformStatItem(
                  label: strings.t('folderContentItems'),
                  value: '${_folderContents.length}',
                ),
              ],
              actions: [
                if (isTeacher && folderId != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _createDocumentFolder(
                      context,
                      state,
                      strings,
                      parentId: folderId,
                    ),
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: Text(strings.t('newSubfolder')),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _showAddFolderContentSheet(
                      context,
                      state,
                      strings,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(strings.t('addFolderContent')),
                  ),
                ],
              ],
            ),
            if (showSearch) ...[
              TextField(
                decoration: InputDecoration(
                  hintText: strings.t('searchFolderContent'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _folderContentSearchQuery = value),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Expanded(
              child: !hasAnything
                  ? AppEmptyState(
                      icon: Icons.folder_outlined,
                      title: strings.t('folderEmpty'),
                      actionLabel: isTeacher
                          ? strings.t('addFolderContent')
                          : null,
                      onAction: isTeacher
                          ? () => _showAddFolderContentSheet(
                                context,
                                state,
                                strings,
                              )
                          : null,
                    )
                  : (filteredSubfolders.isEmpty &&
                          filtered.isEmpty &&
                          query.isNotEmpty)
                      ? AppEmptyState(
                          icon: Icons.search_off,
                          title: strings.t('noFolderContentSearchResults'),
                        )
                      : ListView(
                          children: [
                            if (filteredSubfolders.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  strings.t('subfolders'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              for (final sub in filteredSubfolders)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: AppCard(
                                    onTap: () => _openDocumentFolder(sub),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_outlined,
                                          color: AppColors.navy,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sub.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              Text(
                                                _folderCardMeta(
                                                  strings,
                                                  sub.id,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isTeacher)
                                          _folderTeacherMenu(
                                            context,
                                            state,
                                            strings,
                                            sub,
                                          ) ??
                                              const SizedBox.shrink(),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (filtered.isNotEmpty)
                              for (final row in filtered)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: _buildFolderContentRow(
                                    context,
                                    state,
                                    strings,
                                    row,
                                    folderId: folderId,
                                    isTeacher: isTeacher,
                                  ),
                                ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderContentRow(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    FolderPickerContent row, {
    required int? folderId,
    required bool isTeacher,
  }) {
    final item = row.item;
    final isHw = _isHomeworkContent(item);
    final contextLabel = _folderContentContextLabel(row);
    final subtitle = contextLabel.isEmpty
        ? _contentTypeLabel(strings, item)
        : '$contextLabel · ${_contentTypeLabel(strings, item)}';
    final savedPage = _contentReadingPages[item.id];
    final showReadingBookmark =
        _isPdfContent(item) && savedPage != null && savedPage > 1;
    return AppCard(
      onTap: () => _openDocumentFromFolder(context, state, item),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            isHw ? Icons.assignment_outlined : Icons.insert_drive_file_outlined,
            color: AppColors.navy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (showReadingBookmark) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          strings
                              .t('contentReadingBookmark')
                              .replaceAll('{page}', '$savedPage'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isTeacher && folderId != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value != 'remove') return;
                await state.db.removeContentFromFolder(
                  folderId: folderId,
                  contentId: item.id,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.t('removedFromFolder'))),
                );
                await _loadSectionData();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Text(strings.t('removeFromFolder')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showAddFolderContentSheet(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) async {
    final folderId = _openDocumentFolderId;
    if (folderId == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(strings.t('pickExistingDocument')),
              onTap: () => Navigator.pop(ctx, 'doc'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(strings.t('pickExistingHomework')),
              onTap: () => Navigator.pop(ctx, 'homework'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(strings.t('addNewDocument')),
              onTap: () => Navigator.pop(ctx, 'new'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'doc':
        await _pickContentForFolder(
          context,
          state,
          strings,
          folderId: folderId,
          homeworkOnly: false,
        );
      case 'homework':
        await _pickContentForFolder(
          context,
          state,
          strings,
          folderId: folderId,
          homeworkOnly: true,
        );
      case 'new':
        await _addNewFileToFolder(context, state, strings, folderId);
    }
  }

  Future<void> _pickContentForFolder(
    BuildContext context,
    AppState state,
    AppLocalizations strings, {
    required int folderId,
    required bool homeworkOnly,
  }) async {
    final pickedIds = await FolderContentMultiPicker.show(
      context,
      state: state,
      homeworkOnly: homeworkOnly,
    );
    if (!context.mounted) return;
    if (pickedIds == null || pickedIds.isEmpty) return;
    final added = await state.db.addContentsToFolderBatch(
      folderId: folderId,
      contentIds: pickedIds,
    );
    if (added > 0) {
      final folder = await state.db.getDocumentFolderById(folderId);
      final folderName = folder?.name ?? strings.t('documents');
      await state.recordTeacherActivity(
        type: TeacherActivityTypes.contentAddedToFolder,
        title: strings
            .t('activityContentAddedToFolder')
            .replaceAll('{count}', '$added')
            .replaceAll('{folder}', folderName),
        targetType: TeacherActivityTargets.documentFolder,
        targetId: folderId,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings
              .t('addedToFolderCount')
              .replaceAll('{count}', '$added'),
        ),
      ),
    );
    await _loadSectionData();
  }

  Future<void> _ensureLessonTopicForNewContent(
    AppState state,
    LessonModel lesson,
    TopicModel topic,
  ) async {
    final currentLesson = state.selectedLesson as LessonModel?;
    if (currentLesson?.id != lesson.id || state.selectedClass == null) {
      await state.openCourse(lesson);
    }
    if (topic.unitId != null) {
      final unit = state.units.cast<UnitModel?>().firstWhere(
            (u) => u?.id == topic.unitId,
            orElse: () => null,
          );
      if (unit != null) {
        state.selectUnit(unit, autoSelectFirstTopic: false);
      }
    }
    final currentTopic = state.selectedTopic as TopicModel?;
    if (currentTopic?.id != topic.id) {
      state.selectTopic(topic);
    }
  }

  Future<({LessonModel lesson, TopicModel topic})?> _pickNewDocumentTarget(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) {
    return showDialog<({LessonModel lesson, TopicModel topic})>(
      context: context,
      builder: (ctx) => _NewDocumentTargetDialog(state: state),
    );
  }

  Future<void> _addNewFileToFolder(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    int folderId,
  ) async {
    var lesson = state.selectedLesson as LessonModel?;
    var topic = state.selectedTopic as TopicModel?;
    if (lesson == null || topic == null) {
      final picked = await _pickNewDocumentTarget(context, state, strings);
      if (picked == null) return;
      lesson = picked.lesson;
      topic = picked.topic;
    }
    await _ensureLessonTopicForNewContent(state, lesson, topic);
    if (state.selectedClass == null) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final paths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
    if (paths.isEmpty) return;
    final beforeIds = (await state.db.getContentsByTopic(topic.id))
        .map((e) => e.id)
        .toSet();
    await state.addContentFiles(paths);
    final after = await state.db.getContentsByTopic(topic.id);
    for (final item in after) {
      if (!beforeIds.contains(item.id)) {
        await state.db.addContentToFolder(
          folderId: folderId,
          contentId: item.id,
        );
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('addedToFolder'))),
    );
    await _loadSectionData();
  }

  Widget _buildDocumentsGrid(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    List<ContentItem> documents, {
    int? folderId,
    bool isTeacher = false,
  }) {
    if (documents.isEmpty) {
      return AppEmptyState(
        icon: Icons.insert_drive_file_outlined,
        title: strings.t('noDocuments'),
      );
    }
    return LessonPlatformScrollBody(
      padding: EdgeInsets.all(
        context.isMobileLayout ? AppSpacing.sm : AppSpacing.md,
      ),
      child: _EntityGrid(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return LessonPlatformCompactCard(
            title: doc.name,
            metaParts: [_contentTypeLabel(strings, doc)],
            onTap: () => folderId != null
                ? _openDocumentFromFolder(context, state, doc)
                : _openDocument(state, doc),
            trailing: folderId != null && isTeacher
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value != 'remove') return;
                      await state.db.removeContentFromFolder(
                        folderId: folderId,
                        contentId: doc.id,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.t('removedFromFolder')),
                        ),
                      );
                      await _loadSectionData();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(strings.t('removeFromFolder')),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildTopicDetail(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
    bool isTeacher,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: _TopicContentPanel(
        state: state,
        strings: strings,
        subjectName: _subjectName,
        isPhone: context.isMobileLayout,
        onPickTopic: () => _showTopicSheet(context, state, strings),
        showTopicSelector: true,
      ),
    );
  }

  void _showTopicSheet(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.t('selectTopic'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _TopicList(
                    topics: state.topics,
                    selectedId:
                        (state.selectedTopic as TopicModel?)?.id,
                    scrollController: scrollController,
                    onTopicSelected: (topic) {
                      _openTopic(topic);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EntityGrid extends StatelessWidget {
  const _EntityGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final extent = lessonPlatformCardExtent(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: extent,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({
    required this.topics,
    required this.onTopicSelected,
    this.selectedId,
    this.scrollController,
  });

  final List<TopicModel> topics;
  final ValueChanged<TopicModel> onTopicSelected;
  final int? selectedId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).t('noTopics')));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final isSelected = selectedId == topic.id;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTopicSelected(topic),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _coverImage(topic.imagePath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topic.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textPrimary,
                            ),
                      ),
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
}

class _TopicContentPanel extends StatefulWidget {
  const _TopicContentPanel({
    required this.state,
    required this.strings,
    this.subjectName,
    this.isPhone = false,
    this.onPickTopic,
    this.showTopicSelector = false,
  });

  final AppState state;
  final AppLocalizations strings;
  final String? subjectName;
  final bool isPhone;
  final VoidCallback? onPickTopic;
  final bool showTopicSelector;

  @override
  State<_TopicContentPanel> createState() => _TopicContentPanelState();
}

bool _topicPanelIsPdfContent(ContentItem item) {
  if (item.type == 'pdf') return true;
  return item.path.toLowerCase().endsWith('.pdf');
}

class _TopicContentPanelState extends State<_TopicContentPanel> {
  Map<int, int> _contentReadingPages = {};
  String? _readingPagesContentKey;

  void _scheduleReadingPagesLoad(List<ContentModel> contents) {
    final key = contents.map((c) => c.id).join(',');
    if (key == _readingPagesContentKey) {
      return;
    }
    _readingPagesContentKey = key;
    final pdfIds = <int>[];
    for (final content in contents) {
      final item = content.contentItem;
      if (item != null && _topicPanelIsPdfContent(item)) {
        pdfIds.add(item.id);
      }
    }
    if (pdfIds.isEmpty) {
      setState(() => _contentReadingPages = {});
      return;
    }
    widget.state.db.getContentReadingPages(pdfIds).then((map) {
      if (!mounted || _readingPagesContentKey != key) return;
      setState(() => _contentReadingPages = map);
    });
  }

  Widget _readingBookmarkLabel(
    BuildContext context,
    AppLocalizations strings,
    int savedPage,
  ) {
    return Row(
      children: [
        Icon(
          Icons.bookmark,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            strings
                .t('contentReadingBookmark')
                .replaceAll('{page}', '$savedPage'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
    );
  }

  void _ensureFirstContentSelected(AppState state) {
    final contents = state.filteredContents;
    if (contents.isEmpty) return;
    final selected = state.selectedContent;
    final needsSelect = selected == null ||
        !contents.any((content) => content.id == selected.id);
    if (!needsSelect) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      state.selectContent(contents.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = widget.strings;

    if (state.selectedTopic == null) {
      return AppEmptyState(
        icon: Icons.topic_outlined,
        title: strings.t('selectTopic'),
        actionLabel: widget.isPhone ? strings.t('selectTopic') : null,
        onAction: widget.onPickTopic,
      );
    }

    final contents = state.filteredContents;
    if (contents.isEmpty) {
      return AppEmptyState(
        icon: Icons.insert_drive_file_outlined,
        title: strings.t('noContents'),
      );
    }

    _scheduleReadingPagesLoad(contents);
    _ensureFirstContentSelected(state);
    final padding = widget.isPhone ? AppSpacing.xs : AppSpacing.sm;
    final topics = state.topics;
    final selectedTopicId = (state.selectedTopic as TopicModel?)?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isPhone && widget.onPickTopic != null)
          _phoneTopicBar(state, strings),
        if (widget.showTopicSelector &&
            !widget.isPhone &&
            topics.length > 1)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: padding),
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final isSelected = selectedTopicId == topic.id;
                return FilterChip(
                  label: Text(
                    topic.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  onSelected: (_) => state.selectTopic(topic),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (contents.length > 1)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: contents.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        final isSelected =
                            state.selectedContent?.id == content.id;
                        final item = content.contentItem;
                        final savedPage =
                            item != null ? _contentReadingPages[item.id] : null;
                        final showReadingBookmark = item != null &&
                            _topicPanelIsPdfContent(item) &&
                            savedPage != null &&
                            savedPage > 1;
                        return FilterChip(
                          avatar: showReadingBookmark
                              ? Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          label: Text(
                            content.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          onSelected: (_) => state.selectContent(content),
                        );
                      },
                    ),
                  ),
                if (contents.length > 1) const SizedBox(height: 12),
                if (contents.length == 1) ...[
                  Builder(
                    builder: (context) {
                      final item = contents.first.contentItem;
                      final savedPage =
                          item != null ? _contentReadingPages[item.id] : null;
                      final showReadingBookmark = item != null &&
                          _topicPanelIsPdfContent(item) &&
                          savedPage != null &&
                          savedPage > 1;
                      if (!showReadingBookmark) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _readingBookmarkLabel(
                          context,
                          strings,
                          savedPage!,
                        ),
                      );
                    },
                  ),
                ],
                Expanded(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ContentPreview(
                      key: ValueKey(
                        '${(state.selectedTopic as TopicModel?)?.id}-${state.selectedContent?.id ?? 'none'}',
                      ),
                      title: state.selectedContent?.title ?? '',
                      selectedContent: state.selectedContent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneTopicBar(AppState state, AppLocalizations strings) {
    final topic = state.selectedTopic as TopicModel?;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: widget.onPickTopic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.topic_outlined, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic?.name ?? strings.t('selectTopic'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewDocumentTargetDialog extends StatefulWidget {
  const _NewDocumentTargetDialog({required this.state});

  final AppState state;

  @override
  State<_NewDocumentTargetDialog> createState() =>
      _NewDocumentTargetDialogState();
}

class _NewDocumentTargetDialogState extends State<_NewDocumentTargetDialog> {
  int? _lessonId;
  int? _unitId;
  int? _topicId;
  List<Map<String, Object?>> _lessonOptions = [];
  List<UnitModel> _units = [];
  List<TopicModel> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final lesson = widget.state.selectedLesson as LessonModel?;
    final topic = widget.state.selectedTopic as TopicModel?;
    if (lesson != null) {
      _lessonId = lesson.id;
    }
    if (topic != null) {
      _topicId = topic.id;
      _unitId = topic.unitId;
    }
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _lessonOptions = await widget.state.db.listLessonOptionsForContentPicker(
      homeworkOnly: false,
    );
    if (_lessonId != null) {
      _units = await widget.state.db.getUnits(_lessonId!);
    } else {
      _units = [];
      _unitId = null;
      _topicId = null;
      _topics = [];
    }
    if (_lessonId != null) {
      if (_unitId != null) {
        final topicRows = await widget.state.db.getTopicsRaw(
          _lessonId!,
          unitId: _unitId,
        );
        _topics = topicRows.map(TopicModel.fromMap).toList();
      } else if (_units.isEmpty) {
        final topicRows = await widget.state.db.getTopicsRaw(_lessonId!);
        _topics = topicRows.map(TopicModel.fromMap).toList();
      } else {
        _topics = [];
        _topicId = null;
      }
    } else {
      _topics = [];
      _topicId = null;
    }
    if (_topicId != null &&
        !_topics.any((topic) => topic.id == _topicId)) {
      _topicId = null;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_lessonId == null || _topicId == null) return;
    final lessonRow = await widget.state.db.getLessonById(_lessonId!);
    if (lessonRow == null) return;
    final topic = _topics.cast<TopicModel?>().firstWhere(
          (t) => t?.id == _topicId,
          orElse: () => null,
        );
    if (topic == null) return;
    if (!mounted) return;
    Navigator.pop(
      context,
      (lesson: LessonModel.fromMap(lessonRow), topic: topic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final canConfirm =
        !_loading && _lessonId != null && _topicId != null;
    return AlertDialog(
      title: Text(strings.t('addNewDocument')),
      content: _loading
          ? const SizedBox(
              width: 280,
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.t('selectCourseForNewDocument'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _lessonId,
                    decoration: InputDecoration(
                      labelText: strings.t('courses'),
                      isDense: true,
                    ),
                    items: [
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
                    DropdownButtonFormField<int?>(
                      value: _unitId,
                      decoration: InputDecoration(
                        labelText: strings.t('units'),
                        isDense: true,
                      ),
                      items: [
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
                  if (_topics.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: _topicId,
                      decoration: InputDecoration(
                        labelText: strings.t('topics'),
                        isDense: true,
                      ),
                      items: [
                        for (final topic in _topics)
                          DropdownMenuItem<int?>(
                            value: topic.id,
                            child: Text(topic.name),
                          ),
                      ],
                      onChanged: (value) {
                        _topicId = value;
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancelSimple')),
        ),
        FilledButton(
          onPressed: canConfirm ? _confirm : null,
          child: Text(strings.t('save')),
        ),
      ],
    );
  }
}

Widget _coverImage(String? path) {
  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    return Image.file(File(path), fit: BoxFit.cover);
  }
  return const Center(
    child: Icon(Icons.menu_book, size: 48, color: Color(0xFF1E2A5A)),
  );
}
