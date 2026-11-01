import 'dart:convert';

import '../../../../core/utils/text_utils.dart';
import '../../du_lieu/models/place.dart';
import '../../du_lieu/models/place_category.dart';

class ParseResult {
  const ParseResult(this.places, this.errors);

  final List<Place> places;

  /// Mỗi phần tử là 1 dòng lỗi dễ hiểu, ví dụ "Dòng 3: thiếu tên".
  final List<String> errors;
}

/// Đọc dữ liệu người dùng dán vào: JSON (mảng hoặc {"places": [...]}) hoặc
/// bảng CSV/TSV (dán thẳng từ Excel/Google Sheets được).
///
/// Thứ tự cột khi không có dòng tiêu đề:
/// tên, loại, địa chỉ, vĩ độ, kinh độ, số điện thoại, giờ mở cửa.
ParseResult parsePlaces(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const ParseResult([], []);
  if (text.startsWith('[') || text.startsWith('{')) return _parseJson(text);
  return _parseTable(text);
}

const _keyAliases = <String, List<String>>{
  'name': ['name', 'ten', 'tendiadiem', 'tenquan'],
  'category': ['category', 'loai', 'danhmuc', 'type'],
  'address': ['address', 'diachi'],
  'lat': ['lat', 'latitude', 'vido'],
  'lng': ['lng', 'lon', 'long', 'longitude', 'kinhdo'],
  'phone': ['phone', 'sdt', 'dienthoai', 'sodienthoai'],
  'hours': ['hours', 'giomocua', 'giolamviec', 'openinghours', 'gio'],
};

const _positionalOrder = [
  'name',
  'category',
  'address',
  'lat',
  'lng',
  'phone',
  'hours',
];

String _normalizeKey(String key) =>
    foldVietnamese(key).replaceAll(RegExp(r'[^a-z0-9]'), '');

String? _canonicalKey(String key) {
  final normalized = _normalizeKey(key);
  for (final entry in _keyAliases.entries) {
    if (entry.value.contains(normalized)) return entry.key;
  }
  return null;
}

ParseResult _parseJson(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    return ParseResult(const [], ['JSON không hợp lệ: ${e.message}']);
  }
  Object? list = decoded;
  if (decoded is Map && decoded['places'] is List) list = decoded['places'];
  if (list is! List) {
    return const ParseResult([], ['JSON phải là một mảng các địa điểm.']);
  }
  final places = <Place>[];
  final errors = <String>[];
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map) {
      errors.add('Mục ${i + 1}: không phải đối tượng JSON');
      continue;
    }
    final fields = <String, String>{};
    item.forEach((key, value) {
      final canonical = _canonicalKey(key.toString());
      if (canonical != null && value != null) fields[canonical] = '$value';
    });
    _addPlace(fields, 'Mục ${i + 1}', places, errors);
  }
  return ParseResult(places, errors);
}

ParseResult _parseTable(String text) {
  final firstLine = text.split('\n').first;
  final delimiter = firstLine.contains('\t')
      ? '\t'
      : (!firstLine.contains(',') && firstLine.contains(';') ? ';' : ',');
  final rows = _splitRows(text, delimiter);
  if (rows.isEmpty) return const ParseResult([], []);

  // Có dòng tiêu đề nếu dòng đầu chứa tên cột đã biết (ví dụ "name" / "tên").
  final headerKeys = [for (final cell in rows.first) _canonicalKey(cell)];
  final hasHeader = headerKeys.contains('name') && headerKeys.contains('lat');
  final columns = hasHeader ? headerKeys : _positionalOrder;
  final dataRows = hasHeader ? rows.skip(1).toList() : rows;

  final places = <Place>[];
  final errors = <String>[];
  for (var i = 0; i < dataRows.length; i++) {
    final fields = <String, String>{};
    final cells = dataRows[i];
    for (var c = 0; c < cells.length && c < columns.length; c++) {
      final key = columns[c];
      if (key != null) fields[key] = cells[c];
    }
    _addPlace(fields, 'Dòng ${i + 1}', places, errors);
  }
  return ParseResult(places, errors);
}

void _addPlace(
  Map<String, String> fields,
  String label,
  List<Place> places,
  List<String> errors,
) {
  final name = (fields['name'] ?? '').trim();
  final address = (fields['address'] ?? '').trim();
  final lat = _parseNumber(fields['lat']);
  final lng = _parseNumber(fields['lng']);

  if (name.isEmpty) return errors.add('$label: thiếu tên');
  if (name.length > 200) return errors.add('$label: tên quá dài (tối đa 200)');
  if (address.isEmpty) return errors.add('$label ($name): thiếu địa chỉ');
  if (address.length > 300) {
    return errors.add('$label ($name): địa chỉ quá dài (tối đa 300)');
  }
  if (lat == null || lat < -90 || lat > 90) {
    return errors.add('$label ($name): vĩ độ không hợp lệ');
  }
  if (lng == null || lng < -180 || lng > 180) {
    return errors.add('$label ($name): kinh độ không hợp lệ');
  }

  places.add(
    Place.create(
      name: name,
      category: parseCategoryCode(fields['category'] ?? ''),
      address: address,
      latitude: lat,
      longitude: lng,
      phone: _clip(fields['phone'], 30),
      hours: _clip(fields['hours'], 60),
    ),
  );
}

double? _parseNumber(String? value) {
  if (value == null) return null;
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

String _clip(String? value, int max) {
  final text = (value ?? '').trim();
  return text.length <= max ? text : text.substring(0, max);
}

/// Tách bảng thành các dòng/ô, hiểu ô nằm trong dấu ngoặc kép (có thể chứa
/// dấu phẩy hoặc xuống dòng, `""` là một dấu ngoặc kép).
List<List<String>> _splitRows(String text, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;

  void endCell() {
    row.add(cell.toString().trim());
    cell.clear();
  }

  void endRow() {
    endCell();
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == delimiter) {
      endCell();
    } else if (ch == '\n') {
      endRow();
    } else if (ch != '\r') {
      cell.write(ch);
    }
  }
  endRow();
  return rows;
}
