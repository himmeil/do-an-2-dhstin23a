import '../../../dia_diem/du_lieu/models/place_category_registry.dart';

class PlaceCategoryFilter {
  const PlaceCategoryFilter._();

  static bool matches({
    required Set<String> selectedCategories,
    required String placeCategory,
  }) {
    if (selectedCategories.isEmpty) return true;
    final normalizedPlaceCategory = parseCategoryCode(placeCategory);
    return selectedCategories.any(
      (category) => parseCategoryCode(category) == normalizedPlaceCategory,
    );
  }
}
