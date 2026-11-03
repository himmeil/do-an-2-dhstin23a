# Model dữ liệu địa điểm

Chứa model `Place`, model/registry danh mục và định nghĩa alias cho từng loại
địa điểm.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Chuẩn hóa mã danh mục cũ khi đọc Place; tách registry và metadata danh mục thành các model riêng.
- 2026-11-03 08:19 (UTC+7): Đảm bảo tra metadata danh mục chuẩn hóa các alias `bus_stop`, `bus_station` và `hotel`.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký model địa điểm.
