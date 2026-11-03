# lib/features

Mỗi thư mục con là một module theo chức năng. Module địa điểm đang gom toàn bộ
mã tìm kiếm và hiển thị địa điểm vào `dia_diem/`; xem [tài liệu module](dia_diem/README.md).
Tiến độ chức năng hiện tại được ghi tại [tiendothuchien.md](../../tiendothuchien.md).

| Thư mục | Trạng thái | Ghi chú |
|---|---|---|
| `dia_diem/` | **Đang dùng** | GPS, tìm quanh đây, bản đồ, chi tiết và nạp dữ liệu |
| `an_uong/` | Để trống | Quán ăn, cà phê (mã loại `quan_an`, `cafe`) |
| `vui_choi/` | Để trống | Điểm vui chơi (mã loại `vui_choi`) |
| `tro/` | Để trống | Nhà trọ (mã loại `tro`) |
| `mua_sam/` | Để trống | Cửa hàng, siêu thị (mã loại `mua_sam`) |
| `ho_so_sv/` | Để trống | Hồ sơ sinh viên |
| `hoac_khu_benh/` | Minh chứng | Giữ cấu trúc module trong đồ án; chưa có chức năng thực tế |
| `quach_thanh/` | Minh chứng | Giữ cấu trúc module trong đồ án; chưa có chức năng thực tế |

Quy ước:
- Đặt mã mới trong module sở hữu chức năng; chỉ để ở `core/` khi thực sự dùng chung.
- Màn hình đi qua lớp `services/`, không gọi lưu trữ trực tiếp từ `screens/`.
- Metadata từng loại địa điểm nằm riêng trong
  `dia_diem/du_lieu/models/loai_dia_diem/`; registry dùng chung ở
  `dia_diem/du_lieu/models/place_category_registry.dart`.
- Điều khiển zoom dùng chung đặt trong `dia_diem/ban_do/widgets/map_zoom_controls.dart`;
  không gắn logic zoom vào từng lớp tile.
- File `.gitkeep` trong hai module minh chứng giữ thư mục rỗng trên Git; không đồng nghĩa chức năng đã được triển khai.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Tách metadata từng danh mục địa điểm thành các model riêng, bổ sung registry và quy ước vị trí mã dùng chung.
- 2026-11-03 08:28 (UTC+7): Cập nhật quy ước nhật ký 10 mục và trỏ tài liệu tiến độ về trạng thái hiện hành.
