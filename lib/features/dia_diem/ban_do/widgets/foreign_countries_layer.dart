import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ForeignCountriesLayer extends StatefulWidget {
  const ForeignCountriesLayer({super.key});

  @override
  State<ForeignCountriesLayer> createState() => _ForeignCountriesLayerState();
}

class _ForeignCountriesLayerState extends State<ForeignCountriesLayer> {
  late final Future<List<_CountryFeature>> _countries = _loadCountries();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_CountryFeature>>(
    future: _countries,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('Không tải được ranh giới quốc gia.'));
      }
      if (!snapshot.hasData) return const SizedBox.shrink();

      final colors = Theme.of(context).colorScheme;
      final features = snapshot.data!;
      return PolygonLayer(
        polygons: [
          for (final country in features)
            for (var index = 0; index < country.shapes.length; index++)
              Polygon(
                points: country.shapes[index].outer,
                holePointsList: country.shapes[index].holes,
                color: colors.surfaceContainerHighest,
                borderColor: colors.outlineVariant,
                borderStrokeWidth: 0.7,
                label: index == 0 ? country.name : null,
                labelStyle: TextStyle(
                  color: colors.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      );
    },
  );

  Future<List<_CountryFeature>> _loadCountries() async {
    final json = await rootBundle.loadString(
      'assets/maps/countries_110m.geojson',
    );
    final collection = jsonDecode(json);
    if (collection is! Map || collection['features'] is! List) {
      throw const FormatException('Country boundary GeoJSON is invalid.');
    }

    final features = <_CountryFeature>[];
    for (final rawFeature in collection['features'] as List) {
      if (rawFeature is! Map ||
          rawFeature['properties'] is! Map ||
          rawFeature['geometry'] is! Map) {
        continue;
      }

      final properties = rawFeature['properties'] as Map;
      final geometry = rawFeature['geometry'] as Map;
      if (properties['ADM0_A3'] == 'VNM') continue;

      final shapes = _parseShapes(geometry);
      if (shapes.isEmpty) continue;

      features.add(
        _CountryFeature(
          name: _vietnameseCountryName('${properties['ADMIN'] ?? ''}'),
          shapes: shapes,
        ),
      );
    }
    return features;
  }

  List<_CountryShape> _parseShapes(Map geometry) {
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];
    if (type == 'Polygon' && coordinates is List) {
      final shape = _parsePolygon(coordinates);
      return shape == null ? const [] : [shape];
    }
    if (type == 'MultiPolygon' && coordinates is List) {
      final shapes = <_CountryShape>[];
      for (final polygon in coordinates) {
        if (polygon is! List) continue;
        final shape = _parsePolygon(polygon);
        if (shape != null) shapes.add(shape);
      }
      return shapes;
    }
    return const [];
  }

  _CountryShape? _parsePolygon(List coordinates) {
    if (coordinates.isEmpty || coordinates.first is! List) return null;
    final outer = _parseRing(coordinates.first as List);
    if (outer.length < 3) return null;
    final holes = <List<LatLng>>[];
    for (final ring in coordinates.skip(1)) {
      if (ring is! List) continue;
      final points = _parseRing(ring);
      if (points.length >= 3) holes.add(points);
    }
    return _CountryShape(outer: outer, holes: holes);
  }

  List<LatLng> _parseRing(List ring) => [
    for (final coordinate in ring)
      if (coordinate is List && coordinate.length >= 2)
        if (coordinate[0] is num && coordinate[1] is num)
          LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
  ];

  String _vietnameseCountryName(String name) => switch (name) {
    'China' => 'Trung Quốc',
    'Cambodia' => 'Campuchia',
    'Laos' => 'Lào',
    'Thailand' => 'Thái Lan',
    'Myanmar' => 'Myanmar',
    'Malaysia' => 'Malaysia',
    'Singapore' => 'Singapore',
    'Indonesia' => 'Indonesia',
    'Philippines' => 'Philippines',
    'Brunei' => 'Brunei',
    'India' => 'Ấn Độ',
    _ => name,
  };
}

class _CountryFeature {
  const _CountryFeature({required this.name, required this.shapes});

  final String name;
  final List<_CountryShape> shapes;
}

class _CountryShape {
  const _CountryShape({required this.outer, required this.holes});

  final List<LatLng> outer;
  final List<List<LatLng>> holes;
}
