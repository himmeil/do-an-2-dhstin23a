import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dia_diem/du_lieu/models/place.dart';
import '../../dia_diem/du_lieu/models/place_category.dart';
import '../../dia_diem/du_lieu/repositories/place_repository.dart';
import '../../gps/services/location_service.dart';
import '../services/sample_data.dart';
import '../services/place_import_parser.dart';

/// Màn nạp dữ liệu (dùng lần đầu, hoặc khi cần thêm địa điểm):
/// dán hàng loạt, thêm tay từng điểm, hoặc tạo dữ liệu mẫu để thử app.
/// Khi nạp xong, màn này đóng và trả về số địa điểm đã nạp.
class ImportScreen extends StatefulWidget {
  const ImportScreen({
    required this.service,
    required this.locationService,
    this.isDraft = false,
    super.key,
  });

  final PlaceService service;
  final LocationService locationService;
  final bool isDraft;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _busy = false;

  /// Lưu [places] vào máy. Trả về true nếu thành công.
  /// [closeAfter]: đóng màn và báo số lượng cho màn trước.
  Future<bool> _import(List<Place> places, {required bool closeAfter}) async {
    if (places.isEmpty || _busy) return false;
    setState(() => _busy = true);
    try {
      final count = await widget.service.importAll(places);
      if (!mounted) return true;
      unawaited(_playImportSuccessSound());
      if (closeAfter) {
        Navigator.of(context).pop(count);
      } else {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isDraft
                  ? 'Đã lưu $count địa điểm vào bản nháp.'
                  : 'Đã lưu $count địa điểm.',
            ),
          ),
        );
      }
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chưa lưu được dữ liệu: $error')));
      return false;
    }
  }

  Future<void> _playImportSuccessSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } on MissingPluginException catch (error) {
      debugPrint('Không phát được âm thanh xác nhận: $error');
    } on PlatformException catch (error) {
      debugPrint('Không phát được âm thanh xác nhận: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isDraft ? 'Tạo bản nháp địa điểm' : 'Nạp dữ liệu'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dán hàng loạt'),
              Tab(text: 'Thêm tay'),
              Tab(text: 'Dữ liệu mẫu'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _PasteTab(
                  onImport: _import,
                  busy: _busy,
                  isDraft: widget.isDraft,
                ),
                _ManualTab(
                  onImport: _import,
                  busy: _busy,
                  locationService: widget.locationService,
                  isDraft: widget.isDraft,
                ),
                _SampleTab(
                  onImport: _import,
                  busy: _busy,
                  locationService: widget.locationService,
                  isDraft: widget.isDraft,
                ),
              ],
            ),
            if (_busy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

typedef _ImportCallback = Future<bool> Function(
  List<Place> places, {
  required bool closeAfter,
});

// ---------------------------------------------------------------- Dán hàng loạt

class _PasteTab extends StatefulWidget {
  const _PasteTab({
    required this.onImport,
    required this.busy,
    required this.isDraft,
  });

  final _ImportCallback onImport;
  final bool busy;
  final bool isDraft;

  @override
  State<_PasteTab> createState() => _PasteTabState();
}

class _PasteTabState extends State<_PasteTab> {
  static const _example =
      'name,category,address,lat,lng,phone,hours\n'
      'Cơm tấm Cô Ba,quan_an,"12 Nguyễn Trãi, P.1",10.4571,105.6332,0901234567,06:00 - 21:00\n'
      'Cà phê Góc,cafe,5 Lê Lợi,10.4590,105.6350,,07:00 - 22:00';

  final _controller = TextEditingController();
  ParseResult _result = const ParseResult([], []);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _result.errors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dán dữ liệu dạng CSV (hoặc copy từ Excel / Google Sheets) hoặc JSON. '
          'Mỗi dòng là một địa điểm. Loại hợp lệ: '
          'quan_an, cafe, tro, vui_choi, mua_sam, khac (hoặc viết tên tiếng Việt).',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                _controller.text = _example;
                setState(() => _result = parsePlaces(_example));
              },
              icon: const Icon(Icons.article_outlined),
              label: const Text('Điền ví dụ'),
            ),
            TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text ?? '';
                if (text.isEmpty) return;
                _controller.text = text;
                setState(() => _result = parsePlaces(text));
              },
              icon: const Icon(Icons.content_paste),
              label: const Text('Dán từ clipboard'),
            ),
          ],
        ),
        TextField(
          controller: _controller,
          minLines: 8,
          maxLines: 14,
          onChanged: (value) => setState(() => _result = parsePlaces(value)),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Dán dữ liệu vào đây...',
          ),
        ),
        const SizedBox(height: 12),
        if (_controller.text.trim().isNotEmpty)
          Text(
            'Hợp lệ: ${_result.places.length}   •   Lỗi: ${errors.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        for (final message in errors.take(8))
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (errors.length > 8) Text('...và ${errors.length - 8} lỗi khác.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.busy || _result.places.isEmpty
              ? null
              : () => widget.onImport(_result.places, closeAfter: true),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(
            widget.isDraft && _result.places.isNotEmpty
                ? 'Lưu ${_result.places.length} địa điểm vào bản nháp'
                : widget.isDraft
                ? 'Chưa có dữ liệu hợp lệ'
                : _result.places.isEmpty
                ? 'Nạp dữ liệu'
                : 'Nạp ${_result.places.length} địa điểm',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dòng lỗi sẽ bị bỏ qua. Nạp lại cùng tên + tọa độ thì ghi đè, không bị nhân đôi.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- Thêm tay

class _ManualTab extends StatefulWidget {
  const _ManualTab({
    required this.onImport,
    required this.busy,
    required this.locationService,
    required this.isDraft,
  });

  final _ImportCallback onImport;
  final bool busy;
  final LocationService locationService;
  final bool isDraft;

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _phone = TextEditingController();
  final _hours = TextEditingController();
  String? _category;
  bool _locating = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lng, _phone, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  String? _coordinate(String? value, double limit, String message) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || number < -limit || number > limit ? message : null;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final result = await widget.locationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    final position = result.position;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lấy được vị trí hiện tại.')),
      );
      return;
    }
    _lat.text = position.latitude.toStringAsFixed(6);
    _lng.text = position.longitude.toStringAsFixed(6);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    double parse(TextEditingController c) =>
        double.parse(c.text.trim().replaceAll(',', '.'));
    final place = Place.create(
      name: _name.text.trim(),
      category: _category!,
      address: _address.text.trim(),
      latitude: parse(_lat),
      longitude: parse(_lng),
      phone: _phone.text.trim(),
      hours: _hours.text.trim(),
    );
    final ok = await widget.onImport([place], closeAfter: false);
    if (ok && mounted) {
      // Xóa tên/địa chỉ để nhập điểm tiếp theo; giữ loại cho nhanh.
      _name.clear();
      _address.clear();
      _phone.clear();
      _hours.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên địa điểm'),
            validator: (v) => _required(v, 'Nhập tên địa điểm'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Loại'),
            items: [
              for (final c in placeCategories)
                DropdownMenuItem(value: c.code, child: Text(c.label)),
            ],
            onChanged: (value) => setState(() => _category = value),
            validator: (v) => v == null ? 'Chọn loại địa điểm' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
            validator: (v) => _required(v, 'Nhập địa chỉ'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Vĩ độ'),
                  validator: (v) => _coordinate(v, 90, 'Vĩ độ -90 đến 90'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Kinh độ'),
                  validator: (v) => _coordinate(v, 180, 'Kinh độ -180 đến 180'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                _locating
                    ? 'Đang lấy vị trí...'
                    : 'Dùng vị trí hiện tại của tôi',
              ),
            ),
          ),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại (không bắt buộc)',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _hours,
            decoration: const InputDecoration(
              labelText: 'Giờ mở cửa (không bắt buộc)',
              hintText: '07:00 - 22:00',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(widget.isDraft ? 'Lưu bản nháp' : 'Lưu địa điểm'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Dữ liệu mẫu

class _SampleTab extends StatefulWidget {
  const _SampleTab({
    required this.onImport,
    required this.busy,
    required this.locationService,
    required this.isDraft,
  });

  final _ImportCallback onImport;
  final bool busy;
  final LocationService locationService;
  final bool isDraft;

  @override
  State<_SampleTab> createState() => _SampleTabState();
}

class _SampleTabState extends State<_SampleTab> {
  bool _locating = false;

  Future<void> _create() async {
    setState(() => _locating = true);
    final result = await widget.locationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    final position = result.position;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần vị trí hiện tại để rải dữ liệu mẫu quanh bạn.'),
        ),
      );
      return;
    }
    await widget.onImport(buildSamplePlaces(position), closeAfter: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tạo 12 địa điểm GIẢ (tên bắt đầu bằng "[Mẫu]") rải quanh vị trí '
            'hiện tại của bạn, để thử tìm kiếm, bán kính và bản đồ mà chưa cần '
            'dữ liệu thật.',
          ),
          const SizedBox(height: 8),
          Text(
            widget.isDraft
                ? 'Dữ liệu mẫu sẽ được lưu vào bản nháp quản trị trên thiết bị.'
                : 'Dữ liệu mẫu nằm chung với dữ liệu thật trên máy. Muốn xóa hết, '
                      'xóa dữ liệu của app (hoặc xóa dữ liệu trình duyệt khi chạy web).',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.busy || _locating ? null : _create,
            icon: const Icon(Icons.science_outlined),
            label: Text(
              _locating
                  ? 'Đang lấy vị trí...'
                  : widget.isDraft
                  ? 'Tạo bản nháp mẫu quanh tôi'
                  : 'Tạo dữ liệu mẫu quanh tôi',
            ),
          ),
        ],
      ),
    );
  }
}
