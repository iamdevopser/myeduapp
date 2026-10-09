import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

abstract final class MentorshipEventType {
  static const individual = 'individual';
  static const group = 'group';
  static const parentMeeting = 'veli_toplantisi';
}

abstract final class MentorshipBehaviorType {
  static const positive = 'positive';
  static const improvement = 'improvement';
  static const attention = 'attention';
}

abstract final class MentorshipEventStatus {
  static const planned = 'planned';
  static const completed = 'completed';
}

String mentorshipEventTypeLabel(AppLocalizations strings, String type) {
  switch (type) {
    case MentorshipEventType.individual:
      return strings.t('individualMeeting');
    case MentorshipEventType.group:
      return strings.t('groupEvent');
    case MentorshipEventType.parentMeeting:
      return strings.t('parentMeetingEvent');
    default:
      return strings.t('behaviorReport');
  }
}

String mentorshipBehaviorTypeLabel(AppLocalizations strings, String type) {
  switch (type) {
    case MentorshipBehaviorType.positive:
      return strings.t('positiveBehavior');
    case MentorshipBehaviorType.improvement:
      return strings.t('needsImprovement');
    case MentorshipBehaviorType.attention:
      return strings.t('needsAttention');
    default:
      return type;
  }
}

String mentorshipStatusLabel(AppLocalizations strings, String status) {
  switch (status) {
    case MentorshipEventStatus.completed:
      return strings.t('completed');
    case MentorshipEventStatus.planned:
    default:
      return strings.t('planned');
  }
}

IconData mentorshipEventTypeIcon(String type) {
  switch (type) {
    case MentorshipEventType.individual:
      return Icons.person_outline;
    case MentorshipEventType.group:
      return Icons.groups_outlined;
    case MentorshipEventType.parentMeeting:
      return Icons.family_restroom_outlined;
    default:
      return Icons.psychology_outlined;
  }
}

String mentorshipTimeLabel(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay mentorshipTimeFromString(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return const TimeOfDay(hour: 9, minute: 0);
  }
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 9,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}
