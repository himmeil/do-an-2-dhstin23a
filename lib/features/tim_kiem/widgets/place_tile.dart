import 'package:flutter/material.dart';

import '../../dia_diem/du_lieu/models/place.dart';
import '../../dia_diem/du_lieu/models/place_category.dart';
import '../utils/geo.dart';

/// Một địa điểm kèm khoảng cách (null nếu chưa biết vị trí của người dùng).
class PlaceHit {
  const PlaceHit(this.place, this.distance);

  final Place place;
  final double? distance;
}

class PlaceTile extends StatelessWidget {
  const PlaceTile({
    required this.hit,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.floralStyle = false,
    this.floralIndex = 0,
    super.key,
  });

  final PlaceHit hit;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool floralStyle;
  final int floralIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = hit.place;
    final category = categoryOf(place.category);
    return Card(
      color: floralStyle ? _petalCardColor(floralIndex) : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(floralStyle ? 26 : 12),
          topRight: const Radius.circular(14),
          bottomRight: Radius.circular(floralStyle ? 26 : 12),
          bottomLeft: const Radius.circular(14),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: floralStyle
            ? _PetalBadge(icon: category.icon, index: floralIndex)
            : CircleAvatar(
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hit.distance != null)
              Text(
                formatDistance(hit.distance!),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (onFavoriteTap != null)
              IconButton(
                tooltip: isFavorite
                    ? 'Bỏ khỏi yêu thích'
                    : 'Lưu địa điểm yêu thích',
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colors.error : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _petalCardColor(int index) => switch (index % 4) {
    0 => const Color(0xFFFFF1F6),
    1 => const Color(0xFFF0F8F1),
    2 => const Color(0xFFFFF6F8),
    _ => const Color(0xFFEAF6F0),
  };
}

class _PetalBadge extends StatelessWidget {
  const _PetalBadge({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFE989AB);
    const green = Color(0xFF75A985);
    final petals = index.isEven
        ? const [pink, pink, green, pink, green]
        : const [green, pink, pink, green, pink];
    return SizedBox(
      key: const ValueKey('place-petal-badge'),
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 0,
            child: _Petal(color: petals[0], angle: 0),
          ),
          Positioned(
            right: 1,
            top: 10,
            child: _Petal(color: petals[1], angle: 0.9),
          ),
          Positioned(
            right: 5,
            bottom: 1,
            child: _Petal(color: petals[2], angle: 1.8),
          ),
          Positioned(
            left: 6,
            bottom: 1,
            child: _Petal(color: petals[3], angle: -1.8),
          ),
          Positioned(
            left: 1,
            top: 10,
            child: _Petal(color: petals[4], angle: -0.9),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFEAF6F0),
              foregroundColor: const Color(0xFF397B54),
              child: Icon(icon, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _Petal extends StatelessWidget {
  const _Petal({required this.color, required this.angle});

  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 14,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
    ),
  );
}
