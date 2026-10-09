import 'package:flutter/material.dart';

import '../services/student_portal_service.dart';
import '../utils/student_announcement_meta.dart';

/// Tasarım 08 — duyuru filtreleri (mevcut `hedef_tur` alanına dayalı).
enum StudentAnnouncementFilter {
  all,
  school,
  classScope,
  parentHint,
}

List<StudentPortalAnnouncement> filterStudentAnnouncements(
  List<StudentPortalAnnouncement> items,
  StudentAnnouncementFilter filter,
) {
  switch (filter) {
    case StudentAnnouncementFilter.all:
      return items;
    case StudentAnnouncementFilter.school:
      return items
          .where((a) => a.targetType == StudentAnnouncementTargetType.allSchool)
          .toList();
    case StudentAnnouncementFilter.classScope:
      return items
          .where((a) => a.targetType == StudentAnnouncementTargetType.grade)
          .toList();
    case StudentAnnouncementFilter.parentHint:
      return items
          .where(
            (a) =>
                a.targetType == StudentAnnouncementTargetType.section ||
                a.classId != null,
          )
          .toList();
  }
}

IconData announcementFeedIcon(StudentPortalAnnouncement item, int index) {
  if (item.courseName.isNotEmpty) return Icons.menu_book_outlined;
  switch (item.targetType) {
    case StudentAnnouncementTargetType.allSchool:
      return Icons.campaign_outlined;
    case StudentAnnouncementTargetType.grade:
      return Icons.school_outlined;
    case StudentAnnouncementTargetType.section:
      return Icons.groups_outlined;
  }
}

Color announcementFeedAccent(int index) {
  const palette = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFFEC4899),
  ];
  return palette[index % palette.length];
}

String announcementShortDate(String isoDate) {
  final trimmed = isoDate.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split('-');
  if (parts.length < 3) return trimmed;
  const months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null || m < 1 || m > 12) return trimmed;
  return '$d ${months[m - 1]}';
}

String announcementBodyPreview(String body) {
  final line = body.replaceAll('\n', ' ').trim();
  if (line.length <= 96) return line;
  return '${line.substring(0, 93)}…';
}

/// Tasarım 11 — doküman filtreleri (mevcut alanlara dayalı, sahte kategori yok).
enum StudentDocumentFilter {
  all,
  school,
  classScope,
  course,
}

List<StudentPortalDocument> filterStudentDocuments(
  List<StudentPortalDocument> items,
  StudentDocumentFilter filter,
) {
  switch (filter) {
    case StudentDocumentFilter.all:
      return items;
    case StudentDocumentFilter.school:
      return items
          .where((d) => d.className.isEmpty && d.courseName.isEmpty)
          .toList();
    case StudentDocumentFilter.classScope:
      return items.where((d) => d.className.isNotEmpty).toList();
    case StudentDocumentFilter.course:
      return items.where((d) => d.courseName.isNotEmpty).toList();
  }
}

IconData documentFeedIcon(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('pdf')) return Icons.picture_as_pdf_outlined;
  if (lower.contains('xls') || lower.contains('excel')) {
    return Icons.table_chart_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

Color documentFeedAccent(int index) {
  const palette = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF1E3A5F),
  ];
  return palette[index % palette.length];
}
