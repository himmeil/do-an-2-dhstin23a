# Module địa điểm (`dia_diem`)

Thư mục này được chia theo **chức năng** để dễ tìm và mở rộng. Mỗi chức năng
chứa các loại file cần cho chính chức năng đó (màn hình, service, widget).
Xem [tiến độ chức năng](../../../tiendothuchien.md) để biết các phần đã có trong mã nguồn.

## Chức năng và vị trí mã

| Thư mục | Chức năng | File chính |
|---|---|---|
| `gps/` | Lấy vị trí GPS, quyền vị trí và mở cài đặt | `services/location_service.dart` |
| `tim_kiem/` | Danh sách quanh đây, lọc/tìm kiếm, tìm địa chỉ, chọn vị trí xuất phát | `screens/nearby_screen.dart`, `services/geocoding_service.dart`, `widgets/location_picker_sheet.dart` |
| `ban_do/` | Bản đồ danh sách, ranh giới phường Cao Lãnh, chuyển lớp đường phố/vệ tinh, điều khiển Zoom, bản đồ một địa điểm và chỉ đường | `cao_lanh_ward_boundary.dart`, `map_tile_source.dart`, `widgets/map_zoom_controls.dart`, `widgets/nearby_map.dart`, `widgets/location_map.dart` |
| `nap_du_lieu/` | Nạp CSV/JSON, thêm địa điểm và tạo dữ liệu mẫu | `screens/import_screen.dart`, `services/place_import_parser.dart`, `services/sample_data.dart` |
| `chi_tiet/` | Màn hình chi tiết một địa điểm | `screens/place_detail_screen.dart` |
| `du_lieu/` | Mô hình địa điểm, phân loại và lưu trữ trên máy | `models/`, `models/loai_dia_diem/`, `services/place_service.dart` |

## Quy ước phát triển

- Thêm code vào thư mục chức năng phù hợp, không tạo thêm thư mục chung theo
  loại code ở cấp `dia_diem/`.
- Ví dụ: thêm xử lý GPS thì đặt trong `gps/services/`; thêm màn hình GPS thì
  đặt trong `gps/screens/`.
- Các kiểu dữ liệu và lưu trữ được nhiều chức năng dùng chung đặt trong `du_lieu/`.
- Mỗi loại địa điểm có metadata riêng trong `du_lieu/models/loai_dia_diem/`;
  danh sách và xử lý mã loại dùng chung nằm trong `place_category_registry.dart`.
- Bộ lọc loại địa điểm và bán kính thuộc module `tim_kiem/bo_loc/`; alias OSM
  như `bus_stop`, `bus_station`, `hotel` được chuẩn hóa về mã danh mục của app.
- `Tất cả` là lựa chọn bộ lọc, không phải một loại địa điểm.
- Chỉ chuyển code sang `core/` nếu nó thực sự dùng chung ngoài module địa điểm.
- Cập nhật bảng này khi thêm chức năng hoặc đổi vị trí file.
- Lớp vệ tinh chỉ thay tile nền; marker, ghim đỏ và nút Zoom dùng chung cho
  mọi lớp bản đồ.
- Vị trí xuất phát được đánh dấu trên bản đồ bằng cùng một ghim, dù dùng GPS
  hay chọn vị trí thủ công; bản đồ căn lại tâm khi vị trí thay đổi.
- Khi gộp địa điểm đã lưu và dữ liệu bản đồ, các bản ghi trùng tên cùng địa chỉ
  hoặc cách nhau tối đa 50 m chỉ hiển thị một lần; chi nhánh cùng tên ở xa vẫn
  được giữ riêng.
- Tìm kiếm quanh đây nhận diện các cơ sở lưu trú theo thẻ OpenStreetMap như
  `tourism=guest_house/hostel/hotel`, `amenity=dormitory`, cùng bến xe theo
  `amenity=bus_station`, `highway=bus_stop`, hoặc điểm dừng
  `public_transport=platform/stop_position` có `bus=yes`.
- Admin có thể chọn snapshot bản đồ mới/cũ từ backend local; snapshot đang dùng
  được lưu để tiếp tục sử dụng sau khi backend khởi động lại.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Cập nhật tài liệu module về bộ lọc, phân loại OSM, gộp địa điểm và điều khiển bản đồ.
- 2026-11-03 08:19 (UTC+7): Tách widget và logic lọc loại địa điểm/bán kính sang `tim_kiem/bo_loc/`; bổ sung alias cho mã OSM cũ.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước nhật ký 10 mục và cập nhật trạng thái alias mã danh mục.
