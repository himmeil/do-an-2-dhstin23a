# Kiểm thử

Thư mục chứa kiểm thử Flutter cho dịch vụ, model, màn hình và các tiện ích của
ứng dụng. Chạy toàn bộ bằng `flutter test`; có thể chạy riêng từng file khi
đang sửa một chức năng.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Bổ sung kiểm thử chuẩn hóa danh mục OSM/SQL và cập nhật kiểm thử tìm kiếm, bản đồ, bộ lọc.
- 2026-11-03 08:19 (UTC+7): Thêm kiểm thử alias category OSM và lọc đúng xe buýt/nhà trọ theo mã chuẩn.
- 2026-11-03 08:23 (UTC+7): Bổ sung kiểm thử màn hình chọn bộ lọc với dữ liệu thô `bus_stop`, `bus_station` và `hotel`.
- 2026-11-03 08:25 (UTC+7): Cập nhật quy ước nhật ký để lưu 10 lần chỉnh sửa gần nhất.
- 2026-11-03 08:28 (UTC+7): Quy định tài liệu báo cáo/tiến độ lưu trạng thái hiện hành và tiếp theo.
- 2026-11-03 08:36 (UTC+7): Kiểm thử lỗi proxy không còn bị biến thành danh sách rỗng; UI chỉ rõ cách bật backend.
- 2026-11-03 09:43 (UTC+7): Kiểm thử kết hợp đồng thời xe buýt, nhà trọ, quán ăn và cà phê.
- 2026-11-03 09:53 (UTC+7): Kiểm thử hồi quy giữ điểm xe buýt khi trùng tên/vị trí với bản ghi thuộc danh mục khác.
- 2026-11-03 12:59 (UTC+7): Thêm kiểm thử Node cho seed dữ liệu SQLite và các endpoint API trên runtime Functions.
