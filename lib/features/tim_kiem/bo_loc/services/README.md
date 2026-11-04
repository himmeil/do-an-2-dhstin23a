# Dịch vụ bộ lọc

Chứa logic lọc thuần không phụ thuộc giao diện, bao gồm chuẩn hóa alias danh mục
trước khi so sánh địa điểm với lựa chọn của người dùng. Nhiều danh mục được
kết hợp theo điều kiện OR; tập lựa chọn rỗng nghĩa là không lọc danh mục.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:19 (UTC+7): Thêm `PlaceCategoryFilter` để `bus_stop`/`bus_station` khớp `ben_xe` và `hotel` khớp `tro`.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký dịch vụ lọc.
- 2026-11-03 09:43 (UTC+7): So khớp OR trên nhiều mã danh mục đã chuẩn hóa, giữ trống là trạng thái Tất cả.
