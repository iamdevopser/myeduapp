import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import 'academic_plan_labels.dart';
import 'weekly_schedule_class_options.dart';
import 'weekly_schedule_grid.dart';
import 'weekly_schedule_periods.dart';

class WeeklySchedulePanel extends StatefulWidget {
  const WeeklySchedulePanel({
    super.key,
    this.readOnly = false,
    this.allowedStudentClassIds,
  });

  final bool readOnly;

  /// Öğrenci görünümü: yalnızca bu sınıf id’lerine ait program hücreleri.
  final Set<int>? allowedStudentClassIds;

  @override
  State<WeeklySchedulePanel> createState() => _WeeklySchedulePanelState();
}

class _WeeklySchedulePanelState extends State<WeeklySchedulePanel> {
  List<WeeklyScheduleGridCell> _grid = [];
  List<({String start, String end})> _periodSlots =
      WeeklySchedulePeriods.defaultSlots;
  bool _loading = true;
  String? _error;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  static final List<String> _classOptions = WeeklyScheduleClassOptions.all();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = context.read<AppState>().db;
      _periodSlots = await db.getWeeklySchedulePeriodSlots();
      var entries = await db.getWeeklyScheduleEntries();
      final allowed = widget.allowedStudentClassIds;
      if (allowed != null && allowed.isNotEmpty) {
        entries = entries
            .where((e) {
              final classId = e['ogrenci_sinif_id'] as int?;
              return classId != null && allowed.contains(classId);
            })
            .toList();
      }
      _grid = buildWeeklyScheduleGrid(
        entries,
        periodCount: WeeklySchedulePeriods.count,
      );
    } catch (_) {
      _grid = [];
      if (mounted) {
        _error = AppLocalizations.of(context).t('weeklyScheduleLoadError');
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  ({String start, String end}) _timesFor(int period) {
    return WeeklySchedulePeriods.timesForPeriod(period, _periodSlots);
  }

  Future<void> _editPeriod(int period) async {
    if (widget.readOnly) return;
    final strings = AppLocalizations.of(context);
    final times = _timesFor(period);
    final startController = TextEditingController(text: times.start);
    final endController = TextEditingController(text: times.end);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('weeklyScheduleEditPeriod')),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings
                    .t('weeklySchedulePeriodLabel')
                    .replaceAll('{n}', '$period'),
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: InputDecoration(
                  labelText: strings.t('weeklyScheduleStartTime'),
                ),
              ),
              TextField(
                controller: endController,
                decoration: InputDecoration(
                  labelText: strings.t('weeklyScheduleEndTime'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    await context.read<AppState>().db.saveWeeklySchedulePeriodSlot(
          periodNumber: period,
          startTime: startController.text.trim(),
          endTime: endController.text.trim(),
        );
    await _load();
  }

  Future<void> _editCell(WeeklyScheduleGridCell cell) async {
    if (widget.readOnly) return;
    final strings = AppLocalizations.of(context);
    final current = WeeklyScheduleClassOptions.normalizeSelection(
      cell.classLabel,
    );
    String? selectedClass = current;

    final saved = await showDialog<Object?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('weeklyScheduleEditCell')),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${weeklyDayLabel(strings, cell.dayOfWeek)} · '
                '${strings.t('weeklySchedulePeriodLabel').replaceAll('{n}', '${cell.period}')}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: selectedClass,
                menuMaxHeight: 360,
                decoration: InputDecoration(
                  labelText: strings.t('weeklyScheduleSelectClass'),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('—'),
                  ),
                  ..._classOptions.map(
                    (label) => DropdownMenuItem<String?>(
                      value: label,
                      child: Text(label),
                    ),
                  ),
                ],
                onChanged: (v) => selectedClass = v,
              ),
            ],
          ),
        ),
        actions: [
          if (cell.entryId != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: Text(strings.t('weeklyScheduleClearCell')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (saved == 'clear') {
      await context.read<AppState>().db.deleteWeeklyScheduleEntry(cell.entryId!);
      await _load();
      return;
    }
    if (saved != true) return;

    final times = _timesFor(cell.period);
    await context.read<AppState>().db.saveWeeklyScheduleGridCell(
          dayOfWeek: cell.dayOfWeek,
          periodNumber: cell.period,
          startTime: times.start,
          endTime: times.end,
          classLabel: selectedClass ?? '',
          existingEntryId: cell.entryId,
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: strings.t('weeklyScheduleRetry'),
        onAction: _load,
      );
    }

    final hasAnyClass = _grid.any((c) => !c.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.readOnly)
          Text(
            strings.t('weeklyScheduleTapHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        if (!widget.readOnly) const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 720.0;
              final tableWidth = math.max(constraints.maxWidth, minTableWidth);
              return Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  primary: false,
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    notificationPredicate: (n) => n.depth == 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalScrollController,
                      primary: false,
                      child: SizedBox(
                        width: tableWidth,
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: _WeeklyScheduleTable(
                            strings: strings,
                            grid: _grid,
                            periodSlots: _periodSlots,
                            onCellTap: _editCell,
                            onPeriodTap: _editPeriod,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!hasAnyClass) ...[
          const SizedBox(height: AppSpacing.md),
          AppEmptyState(
            icon: Icons.calendar_view_week_outlined,
            title: strings.t('weeklyScheduleEmpty'),
          ),
        ],
      ],
    );
  }
}

class _WeeklyScheduleTable extends StatelessWidget {
  const _WeeklyScheduleTable({
    required this.strings,
    required this.grid,
    required this.periodSlots,
    required this.onCellTap,
    required this.onPeriodTap,
  });

  final AppLocalizations strings;
  final List<WeeklyScheduleGridCell> grid;
  final List<({String start, String end})> periodSlots;
  final ValueChanged<WeeklyScheduleGridCell> onCellTap;
  final ValueChanged<int> onPeriodTap;

  WeeklyScheduleGridCell _cell(int day, int period) {
    return findWeeklyScheduleCell(grid, day, period) ??
        WeeklyScheduleGridCell(dayOfWeek: day, period: period);
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );
    final periodStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        );
    final cellStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        );

    return Table(
      border: TableBorder.all(color: AppColors.border),
      columnWidths: const {
        0: FixedColumnWidth(112),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FlexColumnWidth(),
        5: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.background),
          children: [
            _headerCell(strings.t('weeklyScheduleLessonColumn'), headerStyle),
            for (var day = 1; day <= 5; day++)
              _headerCell(weeklyDayLabel(strings, day), headerStyle),
          ],
        ),
        for (var period = 1; period <= WeeklySchedulePeriods.count; period++)
          TableRow(
            children: [
              _periodCell(context, period, periodStyle),
              for (var day = 1; day <= 5; day++)
                _dataCell(
                  context,
                  _cell(day, period),
                  cellStyle,
                  onCellTap,
                ),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  Widget _periodCell(BuildContext context, int period, TextStyle? style) {
    final times = WeeklySchedulePeriods.timesForPeriod(period, periodSlots);
    final label = strings.t('weeklySchedulePeriodLabel').replaceAll(
          '{n}',
          '$period',
        );
    return Material(
      color: AppColors.background.withValues(alpha: 0.5),
      child: InkWell(
        onTap: () => onPeriodTap(period),
        hoverColor: AppColors.primaryBlue.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: style, textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(
                '${times.start}\n${times.end}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataCell(
    BuildContext context,
    WeeklyScheduleGridCell cell,
    TextStyle? style,
    ValueChanged<WeeklyScheduleGridCell> onTap,
  ) {
    final label = cell.classLabel.trim();
    return Material(
      color: cell.isEmpty
          ? AppColors.surface
          : AppColors.primaryBlue.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => onTap(cell),
        hoverColor: AppColors.primaryBlue.withValues(alpha: 0.08),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label.isEmpty ? '—' : label,
              style: style?.copyWith(
                color: label.isEmpty
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
