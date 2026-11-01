import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/text_utils.dart';
import '../../du_lieu/models/place.dart';
import '../services/geocoding_service.dart';

/// Kết quả chọn vị trí: [position] null nghĩa là "dùng GPS".
class LocationChoice {
  const LocationChoice.gps() : position = null, label = null;
  const LocationChoice.manual(LatLng this.position, String this.label);

  final LatLng? position;
  final String? label;

  bool get isGps => position == null;
}

/// Bảng chọn vị trí xuất phát: GPS, gõ địa chỉ trong TP. Cao Lãnh, hoặc chọn
/// một địa điểm đã có trong dữ liệu.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    required this.geocoder,
    required this.places,
    super.key,
  });

  final GeocodingService geocoder;
  final List<Place> places;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _controller = TextEditingController();
  List<GeoResult> _results = const [];
  List<Place> _localMatches = const [];
  bool _searching = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _searching) return;
    final folded = foldVietnamese(query);
    setState(() {
      _searching = true;
      _error = null;
      _localMatches = [
        for (final p in widget.places)
          if (foldVietnamese('${p.name} ${p.address}').contains(folded)) p,
      ].take(5).toList();
    });
    try {
      final results = await widget.geocoder.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searched = true;
        _searching = false;
        _error = 'Không tìm được địa chỉ lúc này (kiểm tra mạng).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final nothing =
        _searched &&
        _results.isEmpty &&
        _localMatches.isEmpty &&
        _error == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn vị trí của bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.my_location),
            title: const Text('Dùng vị trí hiện tại (GPS)'),
            onTap: () => Navigator.of(context).pop(const LocationChoice.gps()),
          ),
          const Divider(),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Hoặc nhập địa chỉ',
              helperText: 'Chỉ tìm trong ${CaoLanhArea.name}',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Tìm',
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (nothing)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Không thấy địa chỉ trong TP. Cao Lãnh. Thử tên đường, khu vực '
                'hoặc tên nơi quen (trường, chợ...) thay vì số nhà.',
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in _localMatches)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () =>
                        Navigator.of(context)
                            .pop(LocationChoice.manual(p.latLng, p.name)),
                  ),
                for (final r in _results)
                  ListTile(
                    leading: const Icon(Icons.pin_drop_outlined),
                    title: Text(
                      r.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () =>
                        Navigator.of(context)
                            .pop(LocationChoice.manual(r.position, r.label)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
