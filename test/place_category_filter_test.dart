import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place_category_registry.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/bo_loc/services/place_category_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OSM transit and lodging codes map to their app filter categories', () {
    for (final code in ['bus_stop', 'bus_station', 'bus stop']) {
      expect(
        PlaceCategoryFilter.matches(
          selectedCategories: {'ben_xe'},
          placeCategory: code,
        ),
        isTrue,
        reason: '$code should match the bus filter',
      );
      expect(categoryOf(code).code, 'ben_xe');
    }

    for (final code in ['hotel', 'motel', 'hostel', 'dormitory']) {
      expect(
        PlaceCategoryFilter.matches(
          selectedCategories: {'tro'},
          placeCategory: code,
        ),
        isTrue,
        reason: '$code should match the lodging filter',
      );
      expect(categoryOf(code).code, 'tro');
    }
  });

  test('filter matches any selected category and keeps aliases distinct', () {
    expect(
      PlaceCategoryFilter.matches(
        selectedCategories: {'tro', 'ben_xe'},
        placeCategory: 'bus_stop',
      ),
      isTrue,
    );
    expect(
      PlaceCategoryFilter.matches(
        selectedCategories: {'tro', 'ben_xe'},
        placeCategory: 'hotel',
      ),
      isTrue,
    );
    expect(
      PlaceCategoryFilter.matches(
        selectedCategories: {'tro', 'ben_xe'},
        placeCategory: 'cafe',
      ),
      isFalse,
    );
    expect(
      PlaceCategoryFilter.matches(
        selectedCategories: {},
        placeCategory: 'bus_stop',
      ),
      isTrue,
    );
  });
}
