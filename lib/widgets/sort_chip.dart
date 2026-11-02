// lib/widgets/sort_chip.dart

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// شريحة اختيار طريقة الفرز (تُستخدم في شاشة الطالبات).
class SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const SortChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryColor : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }
}
