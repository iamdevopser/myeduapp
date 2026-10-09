import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/student_portal_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_system.dart';
import '../../utils/student_announcement_notification.dart';
import '../../utils/student_portal_announcement_ui.dart';
/// Tasarım 12 — duyuru detay (08 ile ortak design system).
class StudentAnnouncementDetailScreen extends StatefulWidget {
  const StudentAnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  final StudentPortalAnnouncement announcement;

  @override
  State<StudentAnnouncementDetailScreen> createState() =>
      _StudentAnnouncementDetailScreenState();
}

class _StudentAnnouncementDetailScreenState
    extends State<StudentAnnouncementDetailScreen> {
  bool _marking = false;
  bool _marked = false;

  String _longDate(String iso) {
    final trimmed = iso.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split('-');
    if (parts.length < 3) return trimmed;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) {
      return trimmed;
    }
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '$d ${months[m - 1]} $y';
  }

  Widget _coverHero(StudentPortalAnnouncement a, Color accent) {
    final path = a.coverImagePath?.trim();
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(DesignSystem.cardRadius),
          child: Image.file(
            file,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _iconHero(accent, a),
          ),
        );
      }
    }
    return _iconHero(accent, a);
  }

  Widget _iconHero(Color accent, StudentPortalAnnouncement a) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignSystem.cardRadius),
        border: Border.all(color: DesignSystem.cardBorder),
      ),
      alignment: Alignment.center,
      child: Icon(
        announcementFeedIcon(a, 0),
        size: 56,
        color: accent,
      ),
    );
  }

  Future<void> _markRead() async {
    if (_marking || _marked) return;
    setState(() => _marking = true);
    final state = context.read<AppState>();
    final ok = await markStudentAnnouncementReadFromNotifications(
      state: state,
      announcementId: widget.announcement.id,
    );
    if (!mounted) return;
    setState(() {
      _marking = false;
      if (ok) _marked = true;
    });
    if (ok) {
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('designMarkAsReadDone'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final a = widget.announcement;
    final accent = announcementFeedAccent(a.id);

    return Scaffold(
      backgroundColor: DesignSystem.workspaceBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          strings.t('designAnnouncementDetailTitle'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: strings.t('designAnnouncementCoverImage'),
              child: _coverHero(a, accent),
            ),
            const SizedBox(height: 20),
            Text(
              a.title,
              style: DesignSystem.pageTitle(context).copyWith(fontSize: 20),
            ),
            if (a.date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _longDate(a.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(DesignSystem.cardRadius),
              ),
              child: Text(
                a.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.navy,
                      height: 1.5,
                    ),
              ),
            ),
            if (a.courseName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                a.courseName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: strings.t('designMarkAsRead'),
              child: FilledButton(
                onPressed: _marked ? null : _markRead,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _marking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _marked
                            ? strings.t('designMarkAsReadDone')
                            : strings.t('designMarkAsRead'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
