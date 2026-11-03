# Widget bộ lọc

Chứa các thành phần giao diện lựa chọn nhiều danh mục và bán kính tìm kiếm.
Danh mục dùng FilterChip độc lập; chọn **Tất cả** xóa các lựa chọn. Widget nhận
trạng thái/callback từ màn hình cha, không tự quản lý dữ liệu địa điểm.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:19 (UTC+7): Tách chip danh mục và bán kính thành `NearbyFilterChips` có thể tái sử dụng.
- 2026-11-03 08:23 (UTC+7): Thêm khóa cho danh sách chip danh mục để kiểm thử thao tác cuộn và chọn.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước nhật ký 10 mục cho widget bộ lọc.
- 2026-11-03 09:43 (UTC+7): Cho phép chọn nhiều danh mục cùng lúc và xóa bộ chọn khi nhấn Tất cả.
