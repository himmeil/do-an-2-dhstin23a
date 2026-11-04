import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place_category_registry.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/bo_loc/services/place_category_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy OSM codes normalize in shared place data', () {
    for (final code in ['museum', 'pitch', 'sports_centre', 'swimming_pool']) {
      expect(categoryOf(code).code, 'vui_choi');
      expect(
        Place.fromMap('1', {
          'name': 'Địa điểm',
          'category': code,
          'lat': 10.45,
          'lng': 105.63,
        }).category,
        'vui_choi',
      );
    }

    expect(categoryOf('supermarket').code, 'mua_sam');
    expect(categoryOf('kindergarten').code, 'truong_hoc');
  });

  test(
    'category aliases normalize underscores, hyphens, accents, and casing',
    () {
      for (final alias in [
        'nha_tro',
        'NHÀ TRỌ',
        'khach_san',
        'khách-sạn',
        'hotel',
        'guest_house',
        'nha_nghi',
        'bus_stop',
      ]) {
        final expected = alias.contains('bus') ? 'ben_xe' : 'tro';
        expect(categoryOf(alias).code, expected, reason: alias);
        expect(
          Place.fromMap('1', {
            'name': 'Địa điểm',
            'category': alias,
            'lat': 10.45,
            'lng': 105.63,
          }).category,
          expected,
          reason: 'Place.fromMap: $alias',
        );
      }

      expect(categoryOf('unknown_osm_code').code, 'khac');
    },
  );

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
