import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_announcement_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../utils/student_announcement_meta.dart';
import '../../widgets/app_card.dart';
import 'secretary_announcement_ui.dart';

class SecretaryAnnouncementDetailScreen extends StatefulWidget {
  const SecretaryAnnouncementDetailScreen({super.key});

  @override
  State<SecretaryAnnouncementDetailScreen> createState() =>
      _SecretaryAnnouncementDetailScreenState();
}

class _SecretaryAnnouncementDetailScreenState
    extends State<SecretaryAnnouncementDetailScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    final id = state.secretaryFocusAnnouncementId;
    if (!auth.canViewAnnouncements || id == null) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryAnnouncementService(state.db);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder(
      key: ValueKey('ann-detail-$id-$_reload'),
      future: Future.wait([
        service.getById(id),
        SecretaryStudentService(state.db).listStudentClasses(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = snapshot.data![0] as SecretaryAnnouncement?;
        final classes = snapshot.data![1] as List<Map<String, Object?>>;
        if (item == null) {
          return Center(child: Text(strings.t('teacherAnnouncementsEmpty')));
        }

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${strings.t('announcementStatusLabel')}: '
                      '${announcementStatusLabel(strings, item.status)}',
                    ),
                    Text(
                      '${strings.t('announcementTargetLabel')}: '
                      '${item.targetType == StudentAnnouncementTargetType.allSchool ? strings.t('announcementTargetAllSchool') : service.targetGradeSectionLabel(item, classes)}',
                    ),
                    Text(
                      '${strings.t('announcementPublishedAt')}: '
                      '${(item.publishedAt ?? item.createdAt).split('T').first}',
                    ),
                    const SizedBox(height: 16),
                    Text(item.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (auth.canEditAnnouncement)
                    OutlinedButton.icon(
                      onPressed: () {
                        state.setSecretaryFocusAnnouncement(item.id);
                        navigateSecretarySection(
                          context,
                          SecretaryNavSection.announcementAdd,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.t('announcementEdit')),
                    ),
                  if (auth.canPublishAnnouncement &&
                      item.status == StudentAnnouncementStatus.draft)
                    FilledButton(
                      onPressed: () async {
                        await service.publish(item.id);
                        if (context.mounted) setState(() => _reload++);
                      },
                      child: Text(strings.t('announcementPublish')),
                    ),
                  if (auth.canUnpublishAnnouncement &&
                      item.status == StudentAnnouncementStatus.published)
                    FilledButton.tonal(
                      onPressed: () async {
                        await service.unpublish(item.id);
                        if (context.mounted) setState(() => _reload++);
                      },
                      child: Text(strings.t('announcementUnpublish')),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
