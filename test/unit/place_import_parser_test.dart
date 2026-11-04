import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/nap_du_lieu/services/place_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV có tiêu đề, ô trong ngoặc kép chứa dấu phẩy', () {
    const csv =
        'name,category,address,lat,lng,phone,hours\n'
        'Cơm tấm Cô Ba,quan_an,"12 Nguyễn Trãi, P.1",10.4571,105.6332,0901,06:00 - 21:00\n'
        'Cà phê Góc,Cà phê,5 Lê Lợi,10.4590,105.6350,,';
    final result = parsePlaces(csv);
    expect(result.errors, isEmpty);
    expect(result.places, hasLength(2));
    expect(result.places[0].address, '12 Nguyễn Trãi, P.1');
    expect(result.places[0].latitude, 10.4571);
    expect(result.places[1].category, 'cafe');
  });

  test('CSV không tiêu đề dùng thứ tự cột mặc định', () {
    final result = parsePlaces('Quán A,tro,1 Đường X,10.1,105.2');
    expect(result.errors, isEmpty);
    expect(result.places.single.category, 'tro');
  });

  test('dán từ Excel (phân tách bằng tab, số thập phân dùng dấu phẩy)', () {
    final result = parsePlaces('Quán B\tcafe\t2 Đường Y\t10,5\t105,5');
    expect(result.errors, isEmpty);
    expect(result.places.single.latitude, 10.5);
  });

  test('JSON dạng mảng, nhận cả tên khóa tiếng Việt', () {
    const json =
        '[{"tên":"Quán C","loại":"vui chơi","địa chỉ":"3 Z","vĩ độ":10.2,"kinh độ":105.3}]';
    final result = parsePlaces(json);
    expect(result.errors, isEmpty);
    expect(result.places.single.category, 'vui_choi');
  });

  test('giữ loại bến xe và giới hạn tên 200 ký tự', () {
    final name = List.filled(200, 'N').join();
    final result = parsePlaces(
      '[{"name":"$name","category":"ben_xe","address":"A","lat":10.1,"lng":105.1}]',
    );
    expect(result.errors, isEmpty);
    expect(result.places.single.category, 'ben_xe');
    expect(result.places.single.name, hasLength(200));

    final tooLong = List.filled(201, 'N').join();
    expect(
      parsePlaces(
        '[{"name":"$tooLong","category":"ben_xe","address":"A","lat":10.1,"lng":105.1}]',
      ).errors,
      isNotEmpty,
    );
  });

  test('dòng sai bị bỏ qua và báo lỗi, dòng đúng vẫn nạp', () {
    const csv =
        'name,category,address,lat,lng\n'
        'Đúng,cafe,1 A,10.1,105.1\n'
        'Sai vĩ độ,cafe,2 B,999,105.1\n'
        ',cafe,3 C,10.1,105.1';
    final result = parsePlaces(csv);
    expect(result.places, hasLength(1));
    expect(result.errors, hasLength(2));
  });

  test('chuỗi rỗng và JSON hỏng không làm app lỗi', () {
    expect(parsePlaces('   ').places, isEmpty);
    expect(parsePlaces('[{oops').errors, isNotEmpty);
  });

  test('id ổn định: cùng tên + tọa độ thì cùng id', () {
    final a = placeStableId('Cà phê Góc', 10.459, 105.635);
    final b = placeStableId('ca phe goc ', 10.459, 105.635);
    final c = placeStableId('Cà phê Góc', 10.460, 105.635);
    expect(a, b);
    expect(a, isNot(c));
  });
}
