import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
/// Tasarım 05 — yatay pill sekmeler (Bilgiler / Notlar / …).
class DesignPillTabs extends StatelessWidget {
  const DesignPillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              child: Semantics(
                button: true,
                selected: selectedIndex == i,
                label: tabs[i],
                child: Material(
                  color: selectedIndex == i
                      ? AppColors.primaryBlue
                      : const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => onSelected(i),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ),
      ],
    );
  }
}
