import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class HomeBrandPanel extends StatelessWidget {
  const HomeBrandPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
            Color(0xFFE8F0FE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.lg : AppSpacing.xxl,
            vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
          ),
          child: compact
              ? _compactContent(context, strings, theme)
              : _fullContent(context, strings, theme),
        ),
      ),
    );
  }

  Widget _fullContent(
    BuildContext context,
    AppLocalizations strings,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _logoRow(theme, strings),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.t('homeBrandTagline'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.referenceBlue,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(flex: 2),
        Text(
          strings.t('homeBrandHeadline'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.t('homeBrandSubheadline'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(flex: 3),
        _EducationIllustration(),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _compactContent(
    BuildContext context,
    AppLocalizations strings,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _logoRow(theme, strings),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.t('homeBrandHeadline'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.t('homeBrandSubheadline'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _logoRow(ThemeData theme, AppLocalizations strings) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.referenceBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.referenceBlue,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          strings.t('appTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.referenceBlue,
          ),
        ),
      ],
    );
  }
}

class _EducationIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _bookStack(),
          ),
          Positioned(
            left: 88,
            bottom: 8,
            child: Icon(
              Icons.eco_outlined,
              size: 48,
              color: AppColors.accentGreen.withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            left: 52,
            top: 0,
            child: Transform.rotate(
              angle: -0.08,
              child: Icon(
                Icons.school,
                size: 56,
                color: AppColors.primaryBlue.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookStack() {
    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _book(const Color(0xFF3B82F6), 100, 18),
          ),
          Positioned(
            left: 8,
            bottom: 6,
            child: _book(const Color(0xFF60A5FA), 92, 16),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: _book(const Color(0xFF93C5FD), 84, 14),
          ),
        ],
      ),
    );
  }

  Widget _book(Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(3),
          right: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
