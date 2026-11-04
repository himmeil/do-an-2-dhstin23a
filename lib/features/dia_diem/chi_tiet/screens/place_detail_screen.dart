import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/place_comments_section.dart';
import '../../ban_do/widgets/location_map.dart';
import '../../du_lieu/models/place_category.dart';
import '../../du_lieu/repositories/place_comment_repository.dart';
import '../../../tim_kiem/utils/geo.dart';
import '../../../tim_kiem/widgets/place_tile.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    required this.hit,
    this.commentService,
    this.isSignedIn = false,
    this.accountName = '',
    this.isOpenStreetMapPlace = false,
    this.canUseSatellite = true,
    this.onRequireSignIn,
    this.onRequireCommentSignIn,
    super.key,
  });

  final PlaceHit hit;
  final PlaceCommentService? commentService;
  final bool isSignedIn;
  final String accountName;
  final bool isOpenStreetMapPlace;
  final bool canUseSatellite;
  final VoidCallback? onRequireSignIn;
  final VoidCallback? onRequireCommentSignIn;

  @override
  Widget build(BuildContext context) {
    final place = hit.place;
    final category = categoryOf(place.category);
    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            place.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(category.icon),
              label: Text(category.label),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on_outlined, text: place.address),
          if (hit.distance != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.near_me_outlined,
              text: 'Cách bạn ${formatDistance(hit.distance!)}',
              bold: true,
            ),
          ],
          if (place.hours.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.access_time, text: place.hours),
          ],
          if (place.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: place.phone)),
              child: _InfoRow(icon: Icons.phone_outlined, text: place.phone),
            ),
          ],
          if (isOpenStreetMapPlace) ...[
            const SizedBox(height: 8),
            const Text(
              'Dữ liệu địa điểm © OpenStreetMap contributors',
              style: TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          LocationMap(
            latitude: place.latitude,
            longitude: place.longitude,
            canUseSatellite: canUseSatellite,
            onRequireSignIn: onRequireSignIn,
          ),
          if (commentService != null) ...[
            const SizedBox(height: 24),
            PlaceCommentsSection(
              placeId: place.id,
              service: commentService!,
              isSignedIn: isSignedIn,
              accountName: accountName,
              onRequireSignIn: onRequireCommentSignIn,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ),
    ],
  );
}
