import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tasarım 08/11 — yatay kaydırılabilir filtre pill'leri.
class DesignScrollFilterPills extends StatelessWidget {
  const DesignScrollFilterPills({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              child: Semantics(
                button: true,
                selected: selectedIndex == i,
                label: labels[i],
                child: Material(
                  color: selectedIndex == i
                      ? AppColors.primaryBlue
                      : const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => onSelected(i),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selectedIndex == i
                              ? Colors.white
                              : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
