# Dịch vụ tìm kiếm địa điểm

Chứa các dịch vụ tra cứu địa điểm gần đây và xử lý dữ liệu từ Overpass, proxy
backend và cache offline.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Bổ sung phân loại lưu trú/xe buýt theo OSM và SQL, hỗ trợ cache offline và quản lý snapshot bản đồ.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký dịch vụ tìm kiếm.
- 2026-11-03 08:36 (UTC+7): Không còn trả danh sách rỗng âm thầm khi proxy mất kết nối và chưa có cache offline.
