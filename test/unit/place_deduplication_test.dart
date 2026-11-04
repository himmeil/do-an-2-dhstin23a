import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';

Place _place(String name, double latitude, double longitude, String address) =>
    Place.create(
      name: name,
      category: 'cafe',
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

void main() {
  test('chuẩn hóa category OSM cũ khi đọc địa điểm đã lưu', () {
    expect(
      Place.fromMap('bus-stop', {
        'name': 'Điểm dừng xe buýt',
        'category': 'bus_stop',
      }).category,
      'ben_xe',
    );
    expect(
      Place.fromMap('bus-station', {
        'name': 'Bến xe',
        'category': 'bus_station',
      }).category,
      'ben_xe',
    );
    expect(
      Place.fromMap('hotel', {
        'name': 'Khách sạn',
        'category': 'hotel',
      }).category,
      'tro',
    );
  });

  test('gộp tên không dấu trùng ở cùng vị trí, giữ chi nhánh ở xa', () {
    final local = _place('Cà phê Góc Phố', 10.46, 105.63, 'Đường A');
    final duplicate = _place('Ca phe Goc Pho', 10.4601, 105.63, 'Đường B');
    final otherBranch = _place('Cà phê Góc Phố', 10.47, 105.63, 'Đường C');

    expect(deduplicatePlaces([local, duplicate, otherBranch]), [
      local,
      otherBranch,
    ]);
  });

  test('gộp cùng địa chỉ dù tọa độ giữa hai nguồn hơi lệch', () {
    final first = _place('Quán Ăn An', 10.46, 105.63, '12 Nguyễn Huệ');
    final duplicate = _place('Quan an An', 10.47, 105.64, 'Số 12 Nguyễn Huệ');

    expect(deduplicatePlaces([first, duplicate]), [first]);
  });

  test('không gộp hai chi nhánh xa nhau chỉ vì cùng tên đường', () {
    final first = _place('Cà phê Góc Phố', 10.46, 105.63, 'Đường Nguyễn Huệ');
    final otherBranch = _place(
      'Cà phê Góc Phố',
      10.47,
      105.64,
      'Đường Nguyễn Huệ',
    );

    expect(deduplicatePlaces([first, otherBranch]), [first, otherBranch]);
  });

  test('không gộp địa điểm khác tên dù ở gần nhau', () {
    final cafe = _place('Cà phê A', 10.46, 105.63, 'Chưa có địa chỉ');
    final restaurant = _place('Quán ăn A', 10.4601, 105.63, 'Chưa có địa chỉ');

    expect(deduplicatePlaces([cafe, restaurant]), [cafe, restaurant]);
  });

  test('giữ bản ghi khác danh mục khi đang lọc, nhưng gộp alias cùng nhóm', () {
    final library = Place(
      id: 'library',
      name: 'Nhà sách Nguyễn Văn Cừ',
      category: 'khac',
      address: '',
      latitude: 10.4550533,
      longitude: 105.6344971,
    );
    final busStop = Place(
      id: 'bus-stop',
      name: 'Nhà sách Nguyễn Văn Cừ',
      category: 'bus_stop',
      address: '',
      latitude: 10.4550591,
      longitude: 105.6343132,
    );
    final busStation = Place(
      id: 'bus-station',
      name: 'Nhà sách Nguyễn Văn Cừ',
      category: 'ben_xe',
      address: '',
      latitude: 10.45506,
      longitude: 105.63431,
    );

    expect(deduplicatePlaces([library, busStop]), [library]);
    expect(
      deduplicatePlaces([
        library,
        busStop,
        busStation,
      ], preserveDifferentCategories: true),
      [library, busStop],
    );
  });
}
