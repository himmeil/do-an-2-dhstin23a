# Module địa điểm (`dia_diem`)

Thư mục này được chia theo **chức năng** để dễ tìm và mở rộng. Mỗi chức năng
chứa các loại file cần cho chính chức năng đó (màn hình, service, widget).
Xem [tiến độ chức năng](../../../tiendothuchien.md) để biết các phần đã có trong mã nguồn.

## Chức năng và vị trí mã

| Thư mục | Chức năng | File chính |
|---|---|---|
| `gps/` | Lấy vị trí GPS, quyền vị trí và mở cài đặt | `services/location_service.dart` |
| `tim_kiem/` | Danh sách quanh đây, lọc/tìm kiếm, tìm địa chỉ, chọn vị trí xuất phát | `screens/nearby_screen.dart`, `services/geocoding_service.dart`, `widgets/location_picker_sheet.dart` |
| `ban_do/` | Bản đồ danh sách, ranh giới phường Cao Lãnh, chuyển lớp đường phố/vệ tinh, bản đồ một địa điểm và chỉ đường | `cao_lanh_ward_boundary.dart`, `map_tile_source.dart`, `widgets/map_source_attribution.dart`, `widgets/nearby_map.dart`, `widgets/location_map.dart` |
| `nap_du_lieu/` | Nạp CSV/JSON, thêm địa điểm và tạo dữ liệu mẫu | `screens/import_screen.dart`, `services/place_import_parser.dart`, `services/sample_data.dart` |
| `chi_tiet/` | Màn hình chi tiết một địa điểm | `screens/place_detail_screen.dart` |
| `du_lieu/` | Mô hình địa điểm, phân loại và lưu trữ trên máy | `models/`, `services/place_service.dart` |

## Quy ước phát triển

- Thêm code vào thư mục chức năng phù hợp, không tạo thêm thư mục chung theo
  loại code ở cấp `dia_diem/`.
- Ví dụ: thêm xử lý GPS thì đặt trong `gps/services/`; thêm màn hình GPS thì
  đặt trong `gps/screens/`.
- Các kiểu dữ liệu và lưu trữ được nhiều chức năng dùng chung đặt trong `du_lieu/`.
- Chỉ chuyển code sang `core/` nếu nó thực sự dùng chung ngoài module địa điểm.
- Cập nhật bảng này khi thêm chức năng hoặc đổi vị trí file.
