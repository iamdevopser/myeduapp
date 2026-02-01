import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../data/models/class_model.dart';
import '../data/models/content_with_tags.dart';
import '../data/models/lesson_model.dart';
import '../data/models/topic_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'settings_screen.dart';

class AppViewerScreen extends StatelessWidget {
  const AppViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('appViewerTitle')),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: strings.t('goHome'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'lesson') {
                    final path = await FilePicker.platform.saveFile(
                      dialogTitle: strings.t('exportLesson'),
                      fileName: 'lesson_export.zip',
                      allowedExtensions: ['zip'],
                      type: FileType.custom,
                    );
                    if (path != null) {
                      await state.exportLessonZip(path);
                    }
                  }
                  if (value == 'topic') {
                    final path = await FilePicker.platform.saveFile(
                      dialogTitle: strings.t('exportTopic'),
                      fileName: 'topic_export.zip',
                      allowedExtensions: ['zip'],
                      type: FileType.custom,
                    );
                    if (path != null) {
                      await state.exportTopicZip(path);
                    }
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
                icon: const Icon(Icons.archive),
                tooltip: strings.t('exportZip'),
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
          body: Row(
            children: [
              Container(
                width: 280,
                color: const Color(0xFFEFF2FB),
                child: _Sidebar(state: state),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _ContentPreview(
                        title:
                            '${state.selectedClass?.name ?? ''} / ${state.selectedLesson?.name ?? ''} / ${state.selectedTopic?.name ?? ''}',
                        selectedContent: state.selectedContent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.state,
  });

  final AppState state;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _showFavorites = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = widget.state;
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
    return SizedBox(
      width: 280,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              strings.t('appViewerTitle'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<ClassModel>(
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
              onChanged: (value) =>
                  state.selectClass(value as ClassModel?),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<LessonModel>(
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
                  : (value) => state.selectLesson(value as LessonModel?),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<TopicModel>(
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
                  : (value) => state.selectTopic(value as TopicModel?),
            ),
          ),
          if (state.classes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.t('noClasses')),
            ),
          SwitchListTile(
            title: Text(strings.t('favorites')),
            value: _showFavorites,
            onChanged: (value) {
              setState(() {
                _showFavorites = value;
              });
            },
          ),
          if (state.selectedLesson == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.t('lessonRequired')),
            )
          else if (state.topics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.t('noTopics')),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(strings.t('selectTopic')),
            ),
            ...state.topics.map(
              (topic) => ListTile(
                title: Text(topic.name),
                selected: state.selectedTopic?.id == topic.id,
                onTap: () => state.selectTopic(topic),
              ),
            ),
            const Divider(),
            ...(_showFavorites
                    ? state.filteredContents
                        .where((item) => state.favoriteContentIds.contains(
                              item.content.id,
                            ))
                    : state.filteredContents)
                .map(
              (content) => ListTile(
                dense: true,
                title: Text(content.content.name),
                leading: const Icon(Icons.insert_drive_file, size: 18),
                selected: state.selectedContent?.content.id == content.content.id,
                trailing: IconButton(
                  icon: Icon(
                    state.favoriteContentIds.contains(content.content.id)
                        ? Icons.star
                        : Icons.star_border,
                  ),
                  onPressed: () => state.toggleFavorite(content),
                ),
                onTap: () => state.selectContent(content),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentPreview extends StatefulWidget {
  const _ContentPreview({
    required this.title,
    required this.selectedContent,
  });

  final String title;
  final ContentWithTags? selectedContent;

  @override
  State<_ContentPreview> createState() => _ContentPreviewState();
}

class _ContentPreviewState extends State<_ContentPreview> {
  PdfController? _pdfController;
  String? _pdfPath;
  int _currentPage = 1;
  int _pageCount = 0;
  List<int> _pdfSearchResults = [];
  VideoPlayerController? _videoController;
  String? _videoPath;
  bool _videoReady = false;
  final WebviewController _webController = WebviewController();
  bool _webReady = false;
  String? _webUrl;

  @override
  void didUpdateWidget(covariant _ContentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.selectedContent?.content.path;
    if (path == null) {
      _disposePdf();
      _disposeVideo();
      return;
    }
    final extension = p.extension(path).toLowerCase();
    if (extension == '.pdf' && _pdfPath != path) {
      _disposePdf();
      _pdfPath = path;
      _pdfController = PdfController(
        document: PdfDocument.openFile(path),
      );
      _currentPage = 1;
      _pageCount = 0;
    } else if (extension != '.pdf') {
      _disposePdf();
    }
    if (['.mp4', '.avi'].contains(extension) && _videoPath != path) {
      _initVideo(path);
    } else if (!['.mp4', '.avi'].contains(extension)) {
      _disposeVideo();
    }
    final content = widget.selectedContent;
    if (content?.content.type == 'link' && _webUrl != path) {
      _initWeb(path);
    } else if (content?.content.type != 'link') {
      _disposeWeb();
    }
  }

  @override
  void dispose() {
    _disposePdf();
    _disposeVideo();
    _disposeWeb();
    super.dispose();
  }

  void _disposePdf() {
    _pdfController?.dispose();
    _pdfController = null;
    _pdfPath = null;
    _currentPage = 1;
    _pageCount = 0;
    _pdfSearchResults = [];
  }

  Future<void> _initVideo(String path) async {
    _disposeVideo();
    _videoPath = path;
    final controller = VideoPlayerController.file(File(path));
    _videoController = controller;
    await controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _videoReady = true;
    });
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoPath = null;
    _videoReady = false;
  }

  Future<void> _initWeb(String url) async {
    _webReady = false;
    _webUrl = url;
    if (!_webController.value.isInitialized) {
      await _webController.initialize();
    }
    await _webController.loadUrl(url);
    if (!mounted) {
      return;
    }
    setState(() {
      _webReady = true;
    });
  }

  void _disposeWeb() {
    _webReady = false;
    _webUrl = null;
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
    if (result == null || result.isEmpty) {
      return;
    }
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
    setState(() {
      _pdfSearchResults = matches;
    });
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
    final path = content?.content.path;
    final extension = path == null ? '' : p.extension(path).toLowerCase();
    final type = content?.content.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: () => _showPdfSearchDialog(context, path ?? ''),
                icon: const Icon(Icons.search),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (content == null)
          Text(strings.t('selectFile'))
        else if (extension == '.pdf' && _pdfController != null)
          Expanded(
            child: Column(
              children: [
                _PdfToolbar(
                  currentPage: _currentPage,
                  pageCount: _pageCount,
                  onFirst: () {
                    _pdfController?.jumpToPage(1);
                  },
                  onPrevious: () {
                    if (_currentPage <= 1) {
                      return;
                    }
                    _pdfController?.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  onNext: () {
                    if (_pageCount != 0 && _currentPage >= _pageCount) {
                      return;
                    }
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
                      setState(() {
                        _pageCount = document.pagesCount;
                      });
                    },
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        else if (['.mp4', '.avi'].contains(extension) &&
            _videoController != null &&
            _videoReady)
          Expanded(
            child: Column(
              children: [
                _VideoToolbar(
                  isPlaying: _videoController!.value.isPlaying,
                  onTogglePlay: () {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                ),
              ],
            ),
          )
        else if (['.mp4', '.avi'].contains(extension))
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (['.jpg', '.jpeg', '.png'].contains(extension))
          Expanded(
            child: InteractiveViewer(
              child: Image.file(File(path!)),
            ),
          )
        else if (type == 'exam')
          Expanded(
            child: _ExamPreview(
              examId: int.tryParse(path ?? '') ?? 0,
            ),
          )
        else if (type == 'link' && _webReady)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Webview(_webController),
            ),
          )
        else if (type == 'link')
          Expanded(
            child: Center(
              child: Text(path ?? ''),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(strings.t('previewNotSupported')),
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
        Text(
          pageCount == 0 ? '-' : '$currentPage / $pageCount',
        ),
        IconButton(
          onPressed: isLastPage ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _VideoToolbar extends StatelessWidget {
  const _VideoToolbar({
    required this.isPlaying,
    required this.onTogglePlay,
  });

  final bool isPlaying;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onTogglePlay,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }
}

class _ExamPreview extends StatelessWidget {
  const _ExamPreview({required this.examId});

  final int examId;

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
              child: FilledButton.icon(
                onPressed: () => _showExamRunner(context, questions),
                icon: const Icon(Icons.play_arrow),
                label: Text(strings.t('startExam')),
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
                          Text('${index + 1}. $text'),
                          const SizedBox(height: 8),
                          if (type == 'image')
                            Image.file(File(text),
                                height: 200, fit: BoxFit.contain),
                          if (type == 'mcq')
                            Column(
                              children: [
                                for (var i = 0; i < options.length; i += 1)
                                  Row(
                                    children: [
                                      Icon(
                                        correct == i
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: correct == i
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
    if (duration == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExamRunnerScreen(
          questions: questions,
          durationMinutes: duration,
        ),
      ),
    );
  }
}

class _ExamRunnerScreen extends StatefulWidget {
  const _ExamRunnerScreen({
    required this.questions,
    required this.durationMinutes,
  });

  final List<Map<String, Object?>> questions;
  final int durationMinutes;

  @override
  State<_ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<_ExamRunnerScreen> {
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
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _secondsLeft -= 1;
        });
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
                if (type == 'image')
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

