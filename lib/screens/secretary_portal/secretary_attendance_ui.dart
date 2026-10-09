import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/attendance_status.dart';
import 'secretary_ui/secretary_design.dart';

String attendanceStatusLabel(
  AppLocalizations strings,
  AttendanceStatus status,
) {
  return switch (status) {
    AttendanceStatus.present => strings.t('attendanceStatusPresent'),
    AttendanceStatus.absent => strings.t('attendanceStatusAbsent'),
    AttendanceStatus.excused => strings.t('attendanceStatusExcused'),
  };
}

abstract final class AttendanceStatusColors {
  static const present = Color(0xFF10B981);
  static const absent = Color(0xFFEF4444);
  static const excused = Color(0xFFF59E0B);

  static Color tone(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => present,
    AttendanceStatus.absent => absent,
    AttendanceStatus.excused => excused,
  };
}

/// Satır içi Var / Yok / İzinli seçimi (segmented pill).
class AttendanceStatusPillGroup extends StatelessWidget {
  const AttendanceStatusPillGroup({
    super.key,
    required this.strings,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
  });

  final AppLocalizations strings;
  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus> onChanged;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AttendanceStatus.values.map((status) {
        final selected = value == status;
        final color = AttendanceStatusColors.tone(status);
        final label = _shortLabel(strings, status);
        return Padding(
          padding: EdgeInsets.only(right: compact ? 4 : 6),
          child: _StatusPill(
            label: label,
            color: color,
            selected: selected,
            enabled: enabled,
            onTap: () => onChanged(status),
            compact: compact,
          ),
        );
      }).toList(),
    );
  }

  String _shortLabel(AppLocalizations strings, AttendanceStatus status) {
    return attendanceStatusLabel(strings, status);
  }
}

class AttendanceStatusReadonlyBadge extends StatelessWidget {
  const AttendanceStatusReadonlyBadge({
    super.key,
    required this.strings,
    required this.status,
  });

  final AppLocalizations strings;
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = AttendanceStatusColors.tone(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        attendanceStatusLabel(strings, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.color.withValues(alpha: 0.22)
        : widget.color.withValues(alpha: _hovered ? 0.1 : 0.06);
    final border = widget.selected
        ? widget.color.withValues(alpha: 0.55)
        : widget.color.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(999),
          splashColor: widget.color.withValues(alpha: 0.2),
          highlightColor: widget.color.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: SecretaryDesign.hoverDuration,
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 12,
              vertical: widget.compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: widget.selected
                    ? widget.color.withValues(alpha: 0.95)
                    : const Color(0xFF64748B),
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toplu yoklama aksiyonları — hover + ripple.
class AttendanceBulkActionButton extends StatefulWidget {
  const AttendanceBulkActionButton({
    super.key,
    required this.label,
    required this.status,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final AttendanceStatus status;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  State<AttendanceBulkActionButton> createState() =>
      _AttendanceBulkActionButtonState();
}

class _AttendanceBulkActionButtonState
    extends State<AttendanceBulkActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = AttendanceStatusColors.tone(widget.status);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: SecretaryDesign.hoverDuration,
        decoration: BoxDecoration(
          color: color.withValues(alpha: _hovered ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: color.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use AttendanceStatusPillGroup')
Widget attendanceStatusDropdown({
  required AppLocalizations strings,
  required AttendanceStatus value,
  required ValueChanged<AttendanceStatus?> onChanged,
  bool enabled = true,
}) {
  return AttendanceStatusPillGroup(
    strings: strings,
    value: value,
    enabled: enabled,
    onChanged: (s) => onChanged(s),
  );
}
