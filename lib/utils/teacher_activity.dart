import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/content_item.dart';
import '../data/models/teacher_recent_activity.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/app_navigation.dart';
import '../utils/academic_plans_navigation.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/content_preview.dart';
import 'teacher_nav_section.dart';

/// Activity `tur` values stored in [ogretmen_son_islemler].
abstract final class TeacherActivityTypes {
  static const pdfOpened = 'pdf_opened';
  static const performanceUpdated = 'performance_updated';
  static const folderCreated = 'folder_created';
  static const contentAddedToFolder = 'content_added_to_folder';
  static const classNotebookNote = 'class_notebook_note';
  static const homeworkCreated = 'homework_created';
}

/// Activity `hedef_tur` values (no FK — optional navigation hints).
abstract final class TeacherActivityTargets {
  static const content = 'content';
  static const documentFolder = 'document_folder';
  static const classNotebookNote = 'class_notebook_note';
  static const studentClass = 'student_class';
}

IconData iconForTeacherActivityType(String type) {
  return switch (type) {
    TeacherActivityTypes.pdfOpened => Icons.picture_as_pdf_outlined,
    TeacherActivityTypes.performanceUpdated => Icons.trending_up_outlined,
    TeacherActivityTypes.folderCreated => Icons.folder_outlined,
    TeacherActivityTypes.contentAddedToFolder => Icons.create_new_folder_outlined,
    TeacherActivityTypes.classNotebookNote => Icons.menu_book_outlined,
    TeacherActivityTypes.homeworkCreated => Icons.assignment_outlined,
    _ => Icons.history_outlined,
  };
}

Future<void> handleTeacherActivityTap(
  BuildContext context,
  TeacherRecentActivity activity,
) async {
  final state = context.read<AppState>();
  final strings = AppLocalizations.of(context);
  final targetType = activity.targetType;
  final targetId = activity.targetId;

  if (targetType == null || targetId == null) {
    return;
  }

  switch (targetType) {
    case TeacherActivityTargets.documentFolder:
      final folder = await state.db.getDocumentFolderById(targetId);
      if (!context.mounted) return;
      if (folder == null) {
        _missingTarget(context, strings);
        return;
      }
      state.requestOpenDocumentFolder(targetId);
      openAcademicPlans(
        context,
        section: AcademicPlansSidebarSection.documents,
      );
    case TeacherActivityTargets.content:
      final row = await state.db.getContentById(targetId);
      if (!context.mounted) return;
      if (row == null) {
        _missingTarget(context, strings);
        return;
      }
      final item = ContentItem.fromMap(row);
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
    case TeacherActivityTargets.studentClass:
      final classes = await state.db.getStudentClasses();
      if (!context.mounted) return;
      final exists = classes.any((row) => row['id'] == targetId);
      if (!exists) {
        _missingTarget(context, strings);
        return;
      }
      openStudentPlatform(context, classId: targetId);
    case TeacherActivityTargets.classNotebookNote:
      final note = await state.db.getClassNotebookNoteById(targetId);
      if (!context.mounted) return;
      if (note == null) {
        _missingTarget(context, strings);
        return;
      }
      state.requestOpenClassNotebook(note.classId);
      navigateTeacherSection(context, TeacherNavSection.home);
    default:
      break;
  }
}

void _missingTarget(BuildContext context, AppLocalizations strings) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(strings.t('activityTargetMissing'))),
  );
}
