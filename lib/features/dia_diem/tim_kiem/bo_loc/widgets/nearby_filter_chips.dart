import 'package:flutter/material.dart';

import '../../../du_lieu/models/place_category_registry.dart';

class NearbyFilterChips extends StatelessWidget {
  const NearbyFilterChips({
    required this.selectedCategories,
    required this.selectedRadiusKm,
    required this.showRadius,
    required this.onCategorySelected,
    required this.onRadiusSelected,
    super.key,
  });

  static const _radiiKm = <double?>[1, 5, 10, null];

  final Set<String> selectedCategories;
  final double? selectedRadiusKm;
  final bool showRadius;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<double?> onRadiusSelected;

  static String radiusLabel(double? radiusKm) =>
      radiusKm == null ? 'Tất cả' : '${radiusKm.toStringAsFixed(0)} km';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 48,
        child: ListView(
          key: const ValueKey('nearby-category-filters'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final entry in [
              ('all', 'Tất cả'),
              for (final category in placeCategories)
                (category.code, category.label),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(entry.$2),
                  selected: entry.$1 == 'all'
                      ? selectedCategories.isEmpty
                      : selectedCategories.contains(entry.$1),
                  onSelected: (_) => onCategorySelected(entry.$1),
                ),
              ),
          ],
        ),
      ),
      if (showRadius)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text('Bán kính:')),
              ),
              for (final radiusKm in _radiiKm)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(radiusLabel(radiusKm)),
                    selected: selectedRadiusKm == radiusKm,
                    onSelected: (_) => onRadiusSelected(radiusKm),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
