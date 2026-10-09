import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Scrollable page body for Ders Platformu levels.
class LessonPlatformScrollBody extends StatelessWidget {
  const LessonPlatformScrollBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isMobileLayout;
    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: padding ?? EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
        child: child,
      ),
    );
  }
}

/// Section title above card grids (e.g. "Kurslar").
class LessonPlatformSectionTitle extends StatelessWidget {
  const LessonPlatformSectionTitle({
    super.key,
    required this.title,
    this.count,
  });

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Context header for Ders / Kurs / Ünite detail pages.
class LessonPlatformContextHeader extends StatelessWidget {
  const LessonPlatformContextHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.stats = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final String? imagePath;
  final List<LessonPlatformStatItem> stats;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isMobileLayout;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: isPhone ? 72 : 96,
        height: isPhone ? 72 : 96,
        child: ColoredBox(
          color: AppColors.background,
          child: _headerImage(imagePath),
        ),
      ),
    );

    final info = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: stats
                  .map((item) => _StatPill(label: item.label, value: item.value))
                  .toList(),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, const SizedBox(width: AppSpacing.md), info],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [image, const SizedBox(width: AppSpacing.lg), info],
            ),
      ),
    );
  }

  Widget _headerImage(String? path) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return const Center(
      child: Icon(Icons.menu_book, size: 36, color: AppColors.navy),
    );
  }
}

class LessonPlatformStatItem {
  const LessonPlatformStatItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid extent for Ders Platformu cards.
double lessonPlatformCardExtent(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (AppSpacing.isMobile(width)) return 180;
  if (AppSpacing.isTablet(width)) return 200;
  return 240;
}

/// Home page intro: subtitle, search, primary action.
class LessonPlatformHomeHeader extends StatelessWidget {
  const LessonPlatformHomeHeader({
    super.key,
    required this.subtitle,
    required this.searchHint,
    required this.searchQuery,
    required this.onSearchChanged,
    this.action,
  });

  final String subtitle;
  final String searchHint;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isMobileLayout;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isPhone)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  action!,
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  action!,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Compact metadata line for cards, e.g. "3 Kurs • 12 Ünite • 48 Konu".
class LessonPlatformMetaLine extends StatelessWidget {
  const LessonPlatformMetaLine({super.key, required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    return Text(
      parts.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}

/// Modern compact card used across Ders Platformu grids.
class LessonPlatformCompactCard extends StatelessWidget {
  const LessonPlatformCompactCard({
    super.key,
    required this.title,
    required this.onTap,
    this.imagePath,
    this.headerIcon,
    this.metaParts = const [],
    this.trailing,
  });

  final String title;
  final VoidCallback onTap;
  final String? imagePath;
  final IconData? headerIcon;
  final List<String> metaParts;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              child: ColoredBox(
                color: AppColors.background,
                child: headerIcon != null
                    ? Center(
                        child: Icon(
                          headerIcon,
                          size: 40,
                          color: AppColors.navy.withValues(alpha: 0.85),
                        ),
                      )
                    : _cardImage(imagePath),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  LessonPlatformMetaLine(parts: metaParts),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardImage(String? path) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return const Center(
      child: Icon(Icons.menu_book, size: 32, color: AppColors.navy),
    );
  }
}
