# lib/features

Mỗi thư mục cấp cao là một feature nghiệp vụ độc lập. Địa điểm được chia thành
miền dữ liệu, tìm kiếm, định vị và nạp dữ liệu; xem
[tài liệu miền địa điểm](dia_diem/README.md) và
[tài liệu tìm kiếm](tim_kiem/README.md). Tiến độ hiện tại nằm tại
[tiendothuchien.md](../../tiendothuchien.md).

| Thư mục | Trạng thái | Ghi chú |
|---|---|---|
| `dia_diem/` | **Đang dùng** | Model, danh mục, repository contract, Firestore/local adapters, bản đồ và chi tiết |
| `gps/` | **Đang dùng** | Abstraction và adapter Geolocator |
| `nap_du_lieu/` | **Đang dùng** | Nhập CSV/JSON và dữ liệu mẫu |
| `tim_kiem/` | **Đang dùng** | Điều phối tìm quanh đây, bộ lọc, geocoding và widget tìm kiếm |
| `mini_game/` | **Đang dùng** | Quiz Cao Lãnh và lưu tiến độ/trạng thái |
| `tai_khoan/` | **Đang dùng** | Đăng nhập và xác thực |
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
- `main.dart` là composition root: khởi tạo adapter cụ thể rồi inject vào UI.
- Screen phụ thuộc contract trong `dia_diem/du_lieu/repositories/`, không phụ
  thuộc trực tiếp Firebase hoặc SharedPreferences.
- Adapter lưu trữ và Firebase nằm trong `dia_diem/services/`; đổi backend không
  buộc phải đổi model hoặc quy tắc giao diện.
- Dùng package imports cho liên kết giữa feature; relative imports chỉ dùng
  bên trong cùng module để giới hạn ảnh hưởng khi di chuyển thư mục.
- Metadata từng loại địa điểm nằm riêng trong
  `dia_diem/du_lieu/models/loai_dia_diem/`; registry dùng chung ở
  `dia_diem/du_lieu/models/place_category_registry.dart`.
- Điều khiển zoom dùng chung đặt trong `dia_diem/ban_do/widgets/map_zoom_controls.dart`;
  không gắn logic zoom vào từng lớp tile.
- File `.gitkeep` trong hai module minh chứng giữ thư mục rỗng trên Git; không đồng nghĩa chức năng đã được triển khai.
- Firebase Functions hiện giữ một nguồn deploy duy nhất tại `backend/` theo
  `firebase.json`; không tạo bản sao mã API dưới `functions/`.
- Test Flutter được phân nhóm `test/unit/` và `test/widget/`. Chưa có integration
  test; chỉ tạo `test/integration/` khi có kiểm thử tích hợp thực sự.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Tách metadata từng danh mục địa điểm thành các model riêng, bổ sung registry và quy ước vị trí mã dùng chung.
- 2026-11-03 08:28 (UTC+7): Cập nhật quy ước nhật ký 10 mục và trỏ tài liệu tiến độ về trạng thái hiện hành.
- 2026-11-03 14:40 (UTC+7): Tách feature GPS, tìm kiếm, nạp dữ liệu; đưa test vào unit/widget và tách repository contract khỏi adapter lưu trữ.
