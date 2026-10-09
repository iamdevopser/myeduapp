import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'secretary_design.dart';

typedef SecretaryRowBuilder = DataRow Function(BuildContext context, int index);

/// Full-width data table with client-side pagination and hover rows.
class SecretaryPaginatedTable extends StatefulWidget {
  const SecretaryPaginatedTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.pageSize = 20,
    this.fillHeight = false,
  });

  final List<DataColumn> columns;
  final int rowCount;
  final SecretaryRowBuilder rowBuilder;
  final int pageSize;
  final bool fillHeight;

  @override
  State<SecretaryPaginatedTable> createState() =>
      _SecretaryPaginatedTableState();
}

class _SecretaryPaginatedTableState extends State<SecretaryPaginatedTable> {
  int _page = 0;

  int get _pageCount => widget.rowCount == 0
      ? 1
      : ((widget.rowCount - 1) / widget.pageSize).floor() + 1;

  @override
  Widget build(BuildContext context) {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.rowCount);
    final rows = <DataRow>[];
    for (var i = start; i < end; i++) {
      rows.add(widget.rowBuilder(context, i));
    }

    Widget tableForWidth(double minWidth) {
      final table = DataTable(
        headingRowColor: WidgetStateProperty.all(SecretaryDesign.workspaceBg),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columnSpacing: 24,
        horizontalMargin: 20,
        columns: widget.columns,
        rows: rows,
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: table,
        ),
      );
    }

    final pagination = widget.rowCount > widget.pageSize
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Text(
                  '${start + 1}–$end / ${widget.rowCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Previous',
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_page + 1} / $_pageCount'),
                IconButton(
                  tooltip: 'Next',
                  onPressed: _page < _pageCount - 1
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    return SecretaryGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: widget.fillHeight
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: tableForWidth(constraints.maxWidth),
                      );
                    },
                  ),
                ),
                pagination,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) =>
                      tableForWidth(constraints.maxWidth),
                ),
                pagination,
              ],
            ),
    );
  }
}
