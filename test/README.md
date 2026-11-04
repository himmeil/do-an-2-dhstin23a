# Kiểm thử

- `unit/`: kiểm thử model, parsing, repository/service và tiện ích.
- `widget/`: kiểm thử widget/màn hình và hành vi giao diện.
- Chạy toàn bộ bằng `flutter test`.
- Chạy nhóm riêng bằng `flutter test test/unit` hoặc `flutter test test/widget`.
- Chưa có integration test; không tạo suite rỗng cho tới khi có luồng tích hợp
  cần kiểm tra.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:28 (UTC+7): Quy định tài liệu báo cáo/tiến độ lưu trạng thái hiện hành và tiếp theo.
- 2026-11-03 08:36 (UTC+7): Kiểm thử lỗi proxy không còn bị biến thành danh sách rỗng; UI chỉ rõ cách bật backend.
- 2026-11-03 09:43 (UTC+7): Kiểm thử kết hợp đồng thời xe buýt, nhà trọ, quán ăn và cà phê.
- 2026-11-03 09:53 (UTC+7): Kiểm thử hồi quy giữ điểm xe buýt khi trùng tên/vị trí với bản ghi thuộc danh mục khác.
- 2026-11-03 12:59 (UTC+7): Thêm kiểm thử Node cho seed dữ liệu SQLite và các endpoint API trên runtime Functions.
- 2026-11-03 14:15 (UTC+7): Kiểm thử giới hạn tên nhập 200 ký tự và phân loại `ben_xe` để khớp Firestore Rules.
- 2026-11-03 14:18 (UTC+7): Dùng cache tile `flutter_map` giới hạn 128 MiB và bỏ tải trước tile trùng lượt với map.
- 2026-11-03 14:40 (UTC+7): Phân nhóm kiểm thử Flutter vào `unit/` và `widget/`.
- 2026-11-03 15:19 (UTC+7): Kiểm tra index truy vấn tọa độ SQLite và không vẽ lặp marker địa điểm đang chọn.
- 2026-11-03 15:29 (UTC+7): Kiểm thử migration danh mục OSM cho điểm vui chơi trong SQLite và dữ liệu Overpass.
