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
| `hoac_khu_benh/` | Để trống | Minh chứng đánh dấu bản quyền |
| `quach_thanh/` | Để trống | Minh chứng đánh dấu bản quyền |

Quy ước:
- Đặt mã mới trong module sở hữu chức năng; chỉ để ở `core/` khi thực sự dùng chung.
- Màn hình đi qua lớp `services/`, không gọi lưu trữ trực tiếp từ `screens/`.
- Dùng chung mã loại ở `dia_diem/du_lieu/models/place_category.dart` khi thêm loại địa điểm.
- File `.gitkeep` chỉ để Git giữ thư mục rỗng; xóa đi khi đã có file thật.
