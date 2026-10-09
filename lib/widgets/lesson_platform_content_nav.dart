import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Single segment in the Ders Platformu breadcrumb trail.
class LessonPlatformNavSegment {
  const LessonPlatformNavSegment({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

/// Shared breadcrumb navigation for Ders → Kurs → Ünite → Konu → İçerik.
class LessonPlatformContentNav extends StatelessWidget {
  const LessonPlatformContentNav({
    super.key,
    required this.segments,
  });

  final List<LessonPlatformNavSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final isPhone = context.isMobileLayout;
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: isPhone ? 11 : 12,
        );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isPhone ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xs,
        isPhone ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0)
                Text(' > ', style: baseStyle),
              if (segments[i].onTap != null)
                InkWell(
                  onTap: segments[i].onTap,
                  child: Text(
                    segments[i].label,
                    style: linkStyle,
                  ),
                )
              else
                Text(
                  segments[i].label,
                  style: baseStyle,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

