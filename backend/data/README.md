# Dữ liệu backend

Thư mục chứa schema SQLite và snapshot SQL dùng để khôi phục dữ liệu bản đồ.
Các JSON/SQLite runtime có thể bị Git ignore; không chỉnh trực tiếp snapshot
được sinh tự động nếu chưa đồng bộ với dữ liệu nguồn.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Chuẩn hóa mã `bus_stop`/`bus_station` thành `ben_xe`, mã lưu trú thành `tro`, và đồng bộ phân loại JSON theo SQL.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký dữ liệu.
