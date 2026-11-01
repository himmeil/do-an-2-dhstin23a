import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/services/place_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Place _place(String name) => Place.create(
  name: name,
  category: 'cafe',
  address: 'Địa chỉ $name',
  latitude: 10.4571,
  longitude: 105.6332,
  phone: '0901',
  hours: '07:00 - 22:00',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lưu rồi đọc lại đủ các trường, nạp lại không nhân đôi', () async {
    final service = LocalPlaceService();
    expect(await service.watchAll().first, isEmpty);

    await service.importAll([_place('Cà phê Góc')]);
    await service.importAll([_place('Cà phê Góc')]);

    final saved = await LocalPlaceService().watchAll().first;
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Cà phê Góc');
    expect(saved.single.latitude, 10.4571);
    expect(saved.single.hours, '07:00 - 22:00');
  });

  test('danh sách tự cập nhật khi có dữ liệu mới', () async {
    final service = LocalPlaceService();
    final counts = <int>[];
    final sub = service.watchAll().listen((list) => counts.add(list.length));
    await pumpEventQueue();
    await service.importAll([_place('A'), _place('B')]);
    await pumpEventQueue();
    await sub.cancel();
    expect(counts, [0, 2]);
  });

  test('dữ liệu lưu bị hỏng thì coi như trống', () async {
    SharedPreferences.setMockInitialValues({
      LocalPlaceService.storageKey: '{không phải json',
    });
    expect(await LocalPlaceService().watchAll().first, isEmpty);
  });
}
