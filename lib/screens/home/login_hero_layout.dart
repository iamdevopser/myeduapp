import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/login_hero_texts.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'design_login_layout.dart';

/// Tasarım: `docs/design/login-page-design.jpg` — geniş ekran giriş sayfası.
class LoginHeroLayout extends StatelessWidget {
  const LoginHeroLayout({
    super.key,
    required this.onSubmit,
    required this.onMessage,
  });

  static const backgroundAsset = 'assets/design/login_background.jpg';

  final DesignLoginSubmit onSubmit;
  final LoginMessageCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.max(380.0, constraints.maxWidth * 0.44);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF2F4F55)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: panelWidth, child: const _InfoPanel()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: DesignLoginLayout(
                          desktopSplit: true,
                          glass: true,
                          onSubmit: onSubmit,
                          onMessage: onMessage,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InfoPanel extends StatefulWidget {
  const _InfoPanel();

  @override
  State<_InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<_InfoPanel> with WidgetsBindingObserver {
  static const _ink = Color(0xFF1F2937);

  /// Kullanıcının panelden elle seçtiği dil; null ise cihaz dili kullanılır.
  String? _manualLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String? _appLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appLanguage = Localizations.localeOf(context).languageCode;
    if (_appLanguage != null && _appLanguage != appLanguage) {
      _manualLanguage = appLanguage;
    }
    _appLanguage = appLanguage;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_manualLanguage == null) setState(() {});
  }

  /// Panel shows every hero language; app-supported ones also switch the app.
  void _onLanguageSelected(String code) {
    setState(() => _manualLanguage = code);
    final appSupported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == code,
    );
    if (appSupported) {
      context.read<AppState>().setDisplayLocale(Locale(code));
    }
  }

  LoginHeroTexts _resolveTexts(BuildContext context) {
    final manual = _manualLanguage;
    if (manual != null) {
      final match = LoginHeroTexts.forLanguage(manual);
      if (match != null) return match;
    }
    return LoginHeroTexts.detect(
      WidgetsBinding.instance.platformDispatcher.locales,
      fallback: Localizations.localeOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final texts = _resolveTexts(context);
    final bodyStyle = theme.textTheme.titleMedium?.copyWith(
      color: _ink,
      fontWeight: FontWeight.w500,
      height: 1.35,
      fontSize: 18,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.85),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = (constraints.maxHeight * 0.085).clamp(
                36.0,
                64.0,
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BrandHeader(
                      strings: strings,
                      texts: texts,
                      onLanguageSelected: _onLanguageSelected,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SideIcons(size: iconSize),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Center(
                              child: Directionality(
                                textDirection: texts.textDirection,
                                child: SingleChildScrollView(
                                  child: Column(
                                    key: ValueKey(texts.languageCode),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        texts.title,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _ink,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 28,
                                              height: 1.25,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        texts.subtitle,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(color: _ink),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      Text(texts.bodyIntro, style: bodyStyle),
                                      Text(texts.bodyMain, style: bodyStyle),
                                      Text(texts.bodyOutro, style: bodyStyle),
                                      const SizedBox(height: AppSpacing.lg),
                                      Text(
                                        texts.cta,
                                        style: bodyStyle?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BottomIcons(size: iconSize),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.strings,
    required this.texts,
    required this.onLanguageSelected,
  });

  final AppLocalizations strings;
  final LoginHeroTexts texts;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.referenceBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.referenceBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  strings.t('appTitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.referenceBlue,
                  ),
                ),
              ),
            ),
            _LanguagePicker(
              current: texts,
              tooltip: strings.t('loginHeroLanguage'),
              onSelected: onLanguageSelected,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: texts.textDirection,
          child: Text(
            texts.tagline,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.referenceBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.current,
    required this.tooltip,
    required this.onSelected,
  });

  final LoginHeroTexts current;
  final String tooltip;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      initialValue: current.languageCode,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final t in LoginHeroTexts.all)
          PopupMenuItem<String>(
            value: t.languageCode,
            child: Text(t.languageName),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate,
                size: 20,
                color: AppColors.referenceBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                current.languageCode.toUpperCase(),
                semanticsLabel: current.languageName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.referenceBlue,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.referenceBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideIcons extends StatelessWidget {
  const _SideIcons({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _GlyphIcon(Icons.biotech, const Color(0xFF0E9F9A), size),
          _GlyphIcon(Icons.settings_suggest, const Color(0xFF2563EB), size),
          _GlyphIcon(Icons.tips_and_updates, const Color(0xFFF59E0B), size),
        ],
      ),
    );
  }
}

class _BottomIcons extends StatelessWidget {
  const _BottomIcons({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _GlyphIcon(Icons.palette, const Color(0xFF3B82F6), size),
          _GlyphIcon(Icons.school, const Color(0xFF0F766E), size),
          _GlyphIcon(Icons.auto_stories, const Color(0xFF92400E), size),
          SizedBox(
            width: size,
            height: size,
            child: const CustomPaint(painter: _DnaHelixPainter()),
          ),
        ],
      ),
    );
  }
}

class _GlyphIcon extends StatelessWidget {
  const _GlyphIcon(this.icon, this.color, this.size);

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _DnaHelixPainter extends CustomPainter {
  const _DnaHelixPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strandA = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = size.width * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final strandB = Paint()
      ..color = const Color(0xFF0E9F9A)
      ..strokeWidth = size.width * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final amplitude = size.width * 0.3;
    final centerX = size.width / 2;
    final pathA = Path();
    final pathB = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = t * size.height;
      final phase = t * math.pi * 3;
      final xA = centerX + amplitude * math.sin(phase);
      final xB = centerX - amplitude * math.sin(phase);
      if (i == 0) {
        pathA.moveTo(xA, y);
        pathB.moveTo(xB, y);
      } else {
        pathA.lineTo(xA, y);
        pathB.lineTo(xB, y);
      }
      if (i % 5 == 2) {
        canvas.drawLine(Offset(xA, y), Offset(xB, y), rung);
      }
    }
    canvas.drawPath(pathA, strandA);
    canvas.drawPath(pathB, strandB);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
