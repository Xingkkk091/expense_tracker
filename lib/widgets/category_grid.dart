import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';

class CategoryGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = kCategories;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = cat.label == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          label: '分類 ${cat.label}',
          child: Material(
            color:
                isSelected ? cat.color : cat.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(cat.label);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat.icon,
                        color: isSelected ? Colors.white : cat.color,
                        size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : cat.color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
