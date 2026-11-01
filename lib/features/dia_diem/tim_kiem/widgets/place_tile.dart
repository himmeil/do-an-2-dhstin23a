import 'package:flutter/material.dart';

import '../../du_lieu/models/place.dart';
import '../../du_lieu/models/place_category.dart';
import '../utils/geo.dart';

/// Một địa điểm kèm khoảng cách (null nếu chưa biết vị trí của người dùng).
class PlaceHit {
  const PlaceHit(this.place, this.distance);

  final Place place;
  final double? distance;
}

class PlaceTile extends StatelessWidget {
  const PlaceTile({required this.hit, required this.onTap, super.key});

  final PlaceHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = hit.place;
    final category = categoryOf(place.category);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(category.icon),
        ),
        title: Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          place.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hit.distance == null
            ? null
            : Text(
                formatDistance(hit.distance!),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
