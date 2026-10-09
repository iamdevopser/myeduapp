import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:video_player/video_player.dart';
import 'package:webview_windows/webview_windows.dart';

import '../data/local/app_database.dart';
import '../data/models/content_with_tags.dart';
import '../data/models/lesson_builder_models.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/teacher_activity.dart';

enum ContentDisplayMode { student, preview }

ContentModel contentModelFromTagged(ContentWithTags item) {
  return ContentModel(
    id: item.content.id,
    title: item.content.name,
    archived: item.content.archived,
    contentItem: item.content,
    tags: item.tags,
  );
}

/// Shared renderer used by the student Ders Platformu and builder preview.
class ContentPreview extends StatefulWidget {
  const ContentPreview({
    super.key,
    required this.title,
    required this.selectedContent,
    this.mode = ContentDisplayMode.student,
    this.fillViewport = true,
  });

  final String title;
  final dynamic selectedContent;
  final ContentDisplayMode mode;
  final bool fillViewport;

  @override
  State<ContentPreview> createState() => _ContentPreviewState();
}

class _ContentPreviewState extends State<ContentPreview> {
  PdfController? _pdfController;
  int _currentPage = 1;
  int _pageCount = 0;
  List<int> _pdfSearchResults = [];
  VideoPlayerController? _mediaController;
  bool _mediaReady = false;
  final WebviewController _webController = WebviewController();
  bool _webReady = false;
  Timer? _readingSaveTimer;
  int? _trackedContentId;
  AppDatabase? _readingDb;
  bool _resumedFromSavedPage = false;
  int? _pdfActivityLoggedForContentId;

  bool get _readOnly => widget.mode == ContentDisplayMode.preview;

  static const _readingSaveDelay = Duration(milliseconds: 450);

  static const _videoExt = ['.mp4', '.avi', '.webm', '.mov'];
  static const _audioExt = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
  static const _imageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  static const _wordExt = ['.doc', '.docx'];
  static const _pptExt = ['.ppt', '.pptx'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  String _pathOf(dynamic content) => content?.path as String? ?? '';
  String _typeOf(dynamic content) => content?.type as String? ?? '';

  int? _contentIdOf(dynamic content) {
    if (content == null) return null;
    if (content is ContentModel) return content.id;
    final dynamic id = content.id;
    if (id is int) return id;
    return null;
  }

  void _cancelReadingSave() {
    _readingSaveTimer?.cancel();
    _readingSaveTimer = null;
  }

  void _scheduleReadingSave(int page) {
    if (_readOnly || _trackedContentId == null || _readingDb == null) return;
    _readingSaveTimer?.cancel();
    _readingSaveTimer = Timer(_readingSaveDelay, () {
      unawaited(_persistReadingPage(page));
    });
  }

  Future<void> _persistReadingPage(int page) async {
    final id = _trackedContentId;
    final db = _readingDb;
    if (id == null || db == null || _readOnly) return;
    await db.upsertContentReadingProgress(contentId: id, lastPage: page);
  }

  Future<void> _loadPdfFile(String path, dynamic content) async {
    _disposePdf();
    _cancelReadingSave();
    _trackedContentId = null;
    _readingDb = null;
    _resumedFromSavedPage = false;

    var initialPage = 1;
    final contentId = _contentIdOf(content);
    if (contentId != null && !_readOnly && mounted) {
      final db = context.read<AppState>().db;
      _readingDb = db;
      _trackedContentId = contentId;
      final progress = await db.getContentReadingProgress(contentId);
      if (progress != null && progress.lastPage > 1) {
        initialPage = progress.lastPage;
        _resumedFromSavedPage = true;
      }
    }

    if (!mounted) return;
    try {
      _pdfController = PdfController(
        document: PdfDocument.openFile(path),
        initialPage: initialPage,
      );
      _currentPage = initialPage;
      _pageCount = 0;
    } catch (_) {
      _disposePdf();
    }
    if (mounted) {
      setState(() {});
      _logPdfOpenedActivity(contentId, content);
    }
  }

  void _logPdfOpenedActivity(int? contentId, dynamic content) {
    if (contentId == null || _readOnly || _pdfController == null) {
      return;
    }
    if (_pdfActivityLoggedForContentId == contentId) {
      return;
    }
    _pdfActivityLoggedForContentId = contentId;
    final title = widget.title.trim().isNotEmpty
        ? widget.title.trim()
        : (content is ContentModel ? content.title : '');
    if (title.isEmpty) {
      return;
    }
    unawaited(
      context.read<AppState>().recordTeacherActivity(
        type: TeacherActivityTypes.pdfOpened,
        title: title,
        targetType: TeacherActivityTargets.content,
        targetId: contentId,
      ),
    );
  }

  void _loadContent() {
    if (!mounted) return;
    final content = widget.selectedContent;
    final path = _pathOf(content);
    final type = _typeOf(content);
    if (content == null || (path.isEmpty && type != 'text' && type != 'homework')) {
      _disposePdf();
      _disposeMedia();
      _disposeWeb();
      setState(() {});
      return;
    }
    final extension = path.isEmpty ? '' : p.extension(path).toLowerCase();
    if (extension == '.pdf' && path.isNotEmpty) {
      _disposeMedia();
      _disposeWeb();
      unawaited(_loadPdfFile(path, content));
    } else if ((_videoExt.contains(extension) || _audioExt.contains(extension)) &&
        path.isNotEmpty) {
      _disposePdf();
      _disposeWeb();
      _initMedia(path);
    } else if (type == 'link' && path.isNotEmpty && widget.fillViewport) {
      _disposePdf();
      _disposeMedia();
      final url = path.startsWith('http') ? path : 'https://$path';
      _initWeb(url);
    } else {
      _cancelReadingSave();
      _trackedContentId = null;
      _readingDb = null;
      _resumedFromSavedPage = false;
      _disposePdf();
      _disposeMedia();
      _disposeWeb();
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ContentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.selectedContent?.id;
    final newId = widget.selectedContent?.id;
    final oldPath = _pathOf(oldWidget.selectedContent);
    final newPath = _pathOf(widget.selectedContent);
    if (oldId != newId || oldPath != newPath) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _cancelReadingSave();
    final id = _trackedContentId;
    final page = _currentPage;
    final db = _readingDb;
    if (id != null &&
        db != null &&
        !_readOnly &&
        _pdfController != null &&
        page >= 1) {
      unawaited(db.upsertContentReadingProgress(contentId: id, lastPage: page));
    }
    _disposePdf();
    _disposeMedia();
    _disposeWeb();
    super.dispose();
  }

  void _disposePdf() {
    _pdfController?.dispose();
    _pdfController = null;
    _currentPage = 1;
    _pageCount = 0;
    _pdfSearchResults = [];
    _resumedFromSavedPage = false;
    _pdfActivityLoggedForContentId = null;
  }

  Future<void> _initMedia(String path) async {
    _disposeMedia();
    final controller = VideoPlayerController.file(File(path));
    _mediaController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _mediaReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mediaReady = false);
    }
  }

  void _disposeMedia() {
    _mediaController?.dispose();
    _mediaController = null;
    _mediaReady = false;
  }

  Future<void> _initWeb(String url) async {
    _webReady = false;
    if (!_webController.value.isInitialized) {
      await _webController.initialize();
    }
    await _webController.loadUrl(url);
    if (!mounted) return;
    setState(() => _webReady = true);
  }

  void _disposeWeb() {
    _webReady = false;
  }

  Widget _layout(Widget child, {double? height}) {
    if (widget.fillViewport) {
      return Expanded(child: child);
    }
    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return child;
  }

  Future<void> _openExternal(String target) async {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', target]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [target]);
    } else {
      await Process.start('xdg-open', [target]);
    }
  }

  Future<void> _showPdfSearchDialog(BuildContext context, String path) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('searchPdf')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: strings.t('search')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(strings.t('search')),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final bytes = await File(path).readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    final extractor = sf.PdfTextExtractor(document);
    final matches = <int>[];
    for (var i = 0; i < document.pages.count; i += 1) {
      final text = extractor.extractText(startPageIndex: i);
      if (text.toLowerCase().contains(result.toLowerCase())) {
        matches.add(i + 1);
      }
    }
    document.dispose();
    setState(() => _pdfSearchResults = matches);
    if (matches.isNotEmpty) {
      _pdfController?.animateToPage(
        matches.first,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final content = widget.selectedContent;
    final path = _pathOf(content);
    final extension = path.isEmpty ? '' : p.extension(path).toLowerCase();
    final type = _typeOf(content);
    final title = content?.title as String? ?? content?.name as String? ?? widget.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fillViewport)
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (extension == '.pdf')
                IconButton(
                  tooltip: strings.t('searchPdf'),
                  onPressed: () => _showPdfSearchDialog(context, path),
                  icon: const Icon(Icons.search),
                ),
            ],
          ),
        if (widget.fillViewport) const SizedBox(height: 12),
        if (content == null)
          Text(strings.t('selectFile'))
        else if (type == 'exam' || type == 'question')
          _layout(
            ExamContentPreview(
              examId: int.tryParse(path) ?? 0,
              title: title,
              readOnly: _readOnly,
              revealAnswers: !_readOnly && widget.mode == ContentDisplayMode.student,
            ),
            height: 360,
          )
        else if (type == 'link')
          _layout(_linkBody(context, strings, title, path), height: 220)
        else if (type == 'homework')
          _layout(_homeworkBody(context, strings, title, path, extension), height: 200)
        else if ((type == 'text') && path.isNotEmpty)
          _layout(
            SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                path,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            height: 180,
          )
        else if (extension == '.pdf' && _pdfController != null)
          _layout(_pdfBody(strings, path), height: 420)
        else if ((_videoExt.contains(extension) || _audioExt.contains(extension)) &&
            _mediaController != null &&
            _mediaReady)
          _layout(
            _mediaBody(_audioExt.contains(extension)),
            height: _audioExt.contains(extension) ? 88 : 320,
          )
        else if (_videoExt.contains(extension) || _audioExt.contains(extension))
          _layout(
            const Center(child: CircularProgressIndicator()),
            height: 80,
          )
        else if (_imageExt.contains(extension))
          _layout(_imageBody(strings, path), height: 320)
        else if (_wordExt.contains(extension) ||
            _pptExt.contains(extension) ||
            type == 'word' ||
            type == 'ppt')
          _layout(
            _documentCard(
              context,
              strings: strings,
              name: title,
              typeLabel: _pptExt.contains(extension) || type == 'ppt'
                  ? strings.t('presentationLabel')
                  : strings.t('wordLabel'),
              path: path,
              icon: _pptExt.contains(extension) || type == 'ppt'
                  ? Icons.slideshow
                  : Icons.description,
            ),
            height: 180,
          )
        else
          _layout(
            Center(child: Text(strings.t('previewNotSupported'))),
            height: 80,
          ),
      ],
    );
  }

  Widget _imageBody(AppLocalizations strings, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Center(child: Text(strings.t('imagePreviewUnavailable')));
    }
    return InteractiveViewer(
      child: Image.file(file, fit: BoxFit.contain),
    );
  }

  Widget _pdfBody(AppLocalizations strings, String path) {
    return Column(
      children: [
        if (_resumedFromSavedPage && _currentPage > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.t('contentReadingResume'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        _PdfToolbar(
          currentPage: _currentPage,
          pageCount: _pageCount,
          onFirst: () => _pdfController?.jumpToPage(1),
          onPrevious: () {
            if (_currentPage <= 1) return;
            _pdfController?.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
          onNext: () {
            if (_pageCount != 0 && _currentPage >= _pageCount) return;
            _pdfController?.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
        ),
        if (_pdfSearchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${strings.t('searchResults')}: ${_pdfSearchResults.join(', ')}',
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: PdfView(
            controller: _pdfController!,
            onDocumentLoaded: (document) {
              if (!mounted) return;
              final count = document.pagesCount;
              setState(() => _pageCount = count);
              if (count > 0 && _currentPage > count) {
                final target = count;
                _pdfController?.jumpToPage(target);
                setState(() => _currentPage = target);
                _scheduleReadingSave(target);
              }
            },
            onPageChanged: (page) {
              if (!mounted) return;
              setState(() => _currentPage = page);
              _scheduleReadingSave(page);
            },
          ),
        ),
      ],
    );
  }

  Widget _mediaBody(bool audioOnly) {
    final controller = _mediaController!;
    final duration = controller.value.duration;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
                setState(() {});
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            if (audioOnly)
              Expanded(
                child: Text(
                  _formatDuration(controller.value.position, duration),
                ),
              ),
          ],
        ),
        if (!audioOnly)
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        VideoProgressIndicator(controller, allowScrubbing: true),
      ],
    );
  }

  String _formatDuration(Duration position, Duration total) {
    String two(int n) => n.toString().padLeft(2, '0');
    final p = '${two(position.inMinutes)}:${two(position.inSeconds % 60)}';
    final t = '${two(total.inMinutes)}:${two(total.inSeconds % 60)}';
    return '$p / $t';
  }

  Widget _linkBody(
    BuildContext context,
    AppLocalizations strings,
    String title,
    String path,
  ) {
    if (widget.fillViewport && _webReady) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Webview(_webController),
      );
    }
    if (widget.fillViewport && !_webReady) {
      return Center(child: Text(path));
    }
    return _actionCard(
      icon: Icons.link,
      title: strings.t('webLinkLabel'),
      subtitle: title.isEmpty ? path : title,
      buttonLabel: strings.t('openLink'),
      onPressed: path.isEmpty ? null : () => _openExternal(path),
    );
  }

  Widget _homeworkBody(
    BuildContext context,
    AppLocalizations strings,
    String title,
    String path,
    String extension,
  ) {
    final isFile = _imageExt.contains(extension) ||
        extension == '.pdf' ||
        _wordExt.contains(extension);
    return _actionCard(
      icon: Icons.assignment,
      title: strings.t('homeworkBlock'),
      subtitle: isFile ? title : (path.isEmpty ? title : path),
      buttonLabel: strings.t('openTask'),
      onPressed: _readOnly
          ? null
          : () {
              if (isFile && path.isNotEmpty) {
                _openExternal(path);
              }
            },
    );
  }

  Widget _documentCard(
    BuildContext context, {
    required AppLocalizations strings,
    required String name,
    required String typeLabel,
    required String path,
    required IconData icon,
  }) {
    final exists = path.isNotEmpty && File(path).existsSync();
    final sizeLabel = exists
        ? '${(File(path).lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB'
        : strings.t('imagePreviewUnavailable');
    return _actionCard(
      icon: icon,
      title: name,
      subtitle: '$typeLabel\n$sizeLabel',
      buttonLabel: strings.t('openFile'),
      onPressed: exists ? () => _openExternal(path) : null,
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF5F7FA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E2A5A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExamContentPreview extends StatelessWidget {
  const ExamContentPreview({
    super.key,
    required this.examId,
    required this.title,
    this.readOnly = false,
    this.revealAnswers = false,
  });

  final int examId;
  final String title;
  final bool readOnly;
  final bool revealAnswers;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (examId == 0) {
      return Center(child: Text(strings.t('previewNotSupported')));
    }
    final state = context.read<AppState>();
    return FutureBuilder<List<Map<String, Object?>>>(
      future: state.db.getExamQuestions(examId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return Center(child: Text(strings.t('noQuestions')));
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Card(
                elevation: 0,
                color: const Color(0xFFF5F7FA),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${strings.t('examBlock')} Â· $title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${questions.length} ${strings.t('questions')}',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: readOnly
                            ? null
                            : () => _showExamRunner(context, questions),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(strings.t('startExam')),
                      ),
                      if (readOnly) ...[
                        const SizedBox(height: 8),
                        Text(
                          strings.t('previewSimulation'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final row = questions[index];
                  final text = row['soru'] as String? ?? '';
                  final type = row['tur'] as String? ?? 'text';
                  final optionsJson = row['secenekler'] as String?;
                  final correct = row['dogru_secenek'] as int?;
                  final audio = row['ses_yolu'] as String?;
                  final options = optionsJson == null
                      ? <String>[]
                      : (jsonDecode(optionsJson) as List)
                          .map((e) => e.toString())
                          .toList();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${strings.t('questionLabel')} ${index + 1}'),
                          const SizedBox(height: 8),
                          Text(text),
                          const SizedBox(height: 8),
                          if (type == 'image' && File(text).existsSync())
                            Image.file(File(text),
                                height: 200, fit: BoxFit.contain),
                          if (type == 'mcq')
                            Column(
                              children: [
                                for (var i = 0; i < options.length; i += 1)
                                  Row(
                                    children: [
                                      Icon(
                                        revealAnswers && correct == i
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: revealAnswers && correct == i
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(options[i])),
                                    ],
                                  ),
                              ],
                            ),
                          if (audio != null && audio.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.audiotrack, size: 18),
                                  const SizedBox(width: 6),
                                  Text(strings.t('audioAttached')),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExamRunner(
    BuildContext context,
    List<Map<String, Object?>> questions,
  ) async {
    final strings = AppLocalizations.of(context);
    final durationController = TextEditingController(text: '10');
    final duration = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('examDuration')),
        content: TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(durationController.text) ?? 10;
              Navigator.of(context).pop(minutes);
            },
            child: Text(strings.t('startExam')),
          ),
        ],
      ),
    );
    if (duration == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamRunnerScreen(
          questions: questions,
          durationMinutes: duration,
        ),
      ),
    );
  }
}

class TopicStudentPreview extends StatelessWidget {
  const TopicStudentPreview({
    super.key,
    required this.contents,
    required this.className,
    required this.lessonName,
    required this.topicName,
    this.onBackToEditor,
  });

  final List<ContentWithTags> contents;
  final String className;
  final String lessonName;
  final String topicName;
  final VoidCallback? onBackToEditor;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFF1E2A5A),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.t('studentPreview'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onBackToEditor != null)
                  TextButton.icon(
                    onPressed: onBackToEditor,
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    label: Text(
                      strings.t('backToEditor'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessonName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A5A),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                className,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                topicName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: contents.isEmpty
              ? Center(child: Text(strings.t('noContents')))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: contents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = contents[index];
                    final model = contentModelFromTagged(item);
                    final type = BlockTypeX.fromCode(item.content.type);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(type.icon, color: const Color(0xFF1E2A5A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.content.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ContentPreview(
                              key: ValueKey(model.id),
                              title: item.content.name,
                              selectedContent: model,
                              mode: ContentDisplayMode.preview,
                              fillViewport: false,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PdfToolbar extends StatelessWidget {
  const _PdfToolbar({
    required this.currentPage,
    required this.pageCount,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isFirstPage = currentPage <= 1;
    final isLastPage = pageCount != 0 && currentPage >= pageCount;
    return Row(
      children: [
        IconButton(
          onPressed: isFirstPage ? null : onFirst,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          onPressed: isFirstPage ? null : onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(pageCount == 0 ? '-' : '$currentPage / $pageCount'),
        IconButton(
          onPressed: isLastPage ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class ExamRunnerScreen extends StatefulWidget {
  const ExamRunnerScreen({
    super.key,
    required this.questions,
    required this.durationMinutes,
  });

  final List<Map<String, Object?>> questions;
  final int durationMinutes;

  @override
  State<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<ExamRunnerScreen> {
  late int _secondsLeft;
  late final PageController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.t('examDuration')}: ${_secondsLeft}s'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final row = widget.questions[index];
          final text = row['soru'] as String? ?? '';
          final type = row['tur'] as String? ?? 'text';
          final optionsJson = row['secenekler'] as String?;
          final audio = row['ses_yolu'] as String?;
          final options = optionsJson == null
              ? <String>[]
              : (jsonDecode(optionsJson) as List)
                  .map((e) => e.toString())
                  .toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. $text'),
                const SizedBox(height: 12),
                if (type == 'image' && File(text).existsSync())
                  Image.file(File(text), height: 240, fit: BoxFit.contain),
                if (type == 'mcq')
                  ...options.map((e) => ListTile(title: Text(e))),
                if (audio != null && audio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(strings.t('audioAttached')),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            TextButton(
              onPressed: () => _controller.previousPage(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              ),
              child: Text(strings.t('previous')),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _controller.nextPage(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              ),
              child: Text(strings.t('next')),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.t('finish')),
            ),
          ],
        ),
      ),
    );
  }
}

