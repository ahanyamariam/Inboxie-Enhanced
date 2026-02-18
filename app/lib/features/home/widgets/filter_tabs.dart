import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';

class FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  static const List<String> tabs = [
    'All',
    'Action',
    'Urgent',
    'Important',
    'Low',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.getTextMuted(context),
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: isSelected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
