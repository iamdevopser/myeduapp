import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import 'design_scroll_filter_pills.dart';

/// Tasarım 08/11 — workspace içi liste sayfası (başlık, arama, filtre).
class DesignPortalPageLayout extends StatelessWidget {
  const DesignPortalPageLayout({
    super.key,
    required this.title,
    required this.filterLabels,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    required this.body,
    this.searchHint,
    this.onSearchChanged,
    this.showSearchField = false,
    this.onSearchToggle,
  });

  final String title;
  final List<String> filterLabels;
  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final Widget body;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearchField;
  final VoidCallback? onSearchToggle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.pagePadding(width);

    return ColoredBox(
      color: DesignSystem.workspaceBackground,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padding.copyWith(bottom: 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: DesignSystem.pageTitle(context),
                        ),
                      ),
                      if (onSearchToggle != null)
                        Semantics(
                          button: true,
                          label: searchHint ?? 'Ara',
                          child: IconButton(
                            tooltip: searchHint,
                            onPressed: onSearchToggle,
                            icon: Icon(
                              showSearchField
                                  ? Icons.close
                                  : Icons.search,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showSearchField && onSearchChanged != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: DesignSystem.cardBorder,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DesignScrollFilterPills(
                    labels: filterLabels,
                    selectedIndex: selectedFilterIndex,
                    onSelected: onFilterSelected,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: padding.copyWith(top: 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
