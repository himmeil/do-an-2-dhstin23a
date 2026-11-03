# Tìm kiếm địa điểm

Module điều phối màn hình quanh đây, tra cứu địa điểm, định vị, widget nhập
vị trí và bộ lọc. Bộ lọc riêng nằm trong `bo_loc/`.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:19 (UTC+7): Tách bộ lọc loại địa điểm và bán kính khỏi màn hình tìm kiếm vào module `bo_loc/`.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký tìm kiếm.
- 2026-11-03 09:43 (UTC+7): Giữ đồng thời các nhóm danh mục đã chọn trong màn hình quanh đây.
- 2026-11-03 09:53 (UTC+7): Lọc danh mục trước bước gộp trùng, giữ địa điểm cùng tên nhưng khác nhóm đang chọn.
