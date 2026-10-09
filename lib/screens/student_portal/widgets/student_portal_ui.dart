import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_card.dart';
import 'student_teacher_badge.dart';

class StudentPortalSectionHeader extends StatelessWidget {
  const StudentPortalSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Profil ve detay satırları — dar ekranda dikey hizalama.
class StudentProfileInfoRow extends StatelessWidget {
  const StudentProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    final valueStyle = Theme.of(context).textTheme.bodyMedium;
    if (context.isMobileLayout) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: labelStyle),
          ),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

class StudentProfileHeader extends StatelessWidget {
  const StudentProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StudentAnnouncementCard extends StatelessWidget {
  const StudentAnnouncementCard({
    super.key,
    required this.title,
    required this.body,
    required this.date,
    required this.teacherLabel,
    this.courseName,
  });

  final String title;
  final String body;
  final String date;
  final String teacherLabel;
  final String? courseName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DateChip(label: date),
                StudentTeacherBadge(label: teacherLabel),
              ],
            ),
          ),
          children: [
            if (courseName != null && courseName!.isNotEmpty) ...[
              Text(
                courseName!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class StudentDocumentCard extends StatelessWidget {
  const StudentDocumentCard({
    super.key,
    required this.name,
    required this.type,
    required this.courseName,
    required this.className,
    required this.date,
    required this.teacherLabel,
  });

  final String name;
  final String type;
  final String courseName;
  final String className;
  final String date;
  final String teacherLabel;

  @override
  Widget build(BuildContext context) {
    final meta = '$courseName · $className';
    if (context.isMobileLayout) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            StudentTeacherBadge(label: teacherLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _TypeChip(label: type),
                if (date.isNotEmpty) _DateChip(label: date),
              ],
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(meta),
                const SizedBox(height: 4),
                StudentTeacherBadge(label: teacherLabel),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TypeChip(label: type),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Sınav / ödev kartı — mobilde trailing taşmasını önler.
class StudentPortalActivityCard extends StatelessWidget {
  const StudentPortalActivityCard({
    super.key,
    required this.title,
    required this.subtitleLines,
    required this.teacherLabel,
    this.trailingPrimary,
    this.trailingSecondary,
    this.statusLabel,
    this.statusColor,
  });

  final String title;
  final List<String> subtitleLines;
  final String teacherLabel;
  final String? trailingPrimary;
  final String? trailingSecondary;
  final String? statusLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final trailing = _buildTrailing(context);
    if (context.isMobileLayout) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            ...subtitleLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 6),
            StudentTeacherBadge(label: teacherLabel),
            if (trailing != null) ...[
              const SizedBox(height: 10),
              trailing,
            ],
          ],
        ),
      );
    }
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                ...subtitleLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line),
                  ),
                ),
                const SizedBox(height: 6),
                StudentTeacherBadge(label: teacherLabel),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (statusLabel != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (statusColor ?? AppColors.brandPrimary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          statusLabel!,
          style: TextStyle(
            color: statusColor ?? AppColors.brandPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }
    if (trailingPrimary == null && trailingSecondary == null) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (trailingPrimary != null)
          Text(
            trailingPrimary!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        if (trailingSecondary != null)
          Text(
            trailingSecondary!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class StudentCourseCard extends StatelessWidget {
  const StudentCourseCard({
    super.key,
    required this.name,
    required this.className,
    required this.teacherLabel,
    required this.onTap,
  });

  final String name;
  final String className;
  final String teacherLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(className),
          const SizedBox(height: 4),
          StudentTeacherBadge(label: teacherLabel),
        ],
      ),
    );
  }
}
