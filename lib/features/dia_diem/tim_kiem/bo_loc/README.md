# Bộ lọc tìm kiếm

Module chuyên trách cho bộ lọc tìm kiếm quanh đây:

- `services/`: chuẩn hóa và so khớp mã loại địa điểm.
- `widgets/`: chip lọc nhiều danh mục và bán kính.

Các mã OSM cũ như `bus_stop`, `bus_station`, `hotel` được ánh xạ qua alias của
registry để bộ lọc dùng mã chuẩn `ben_xe` hoặc `tro`. Có thể bật đồng thời
nhiều danh mục; kết quả khớp bất kỳ danh mục nào đã chọn. Không chọn danh mục
nào tương đương **Tất cả**.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:19 (UTC+7): Tạo module bộ lọc chuyên trách, tách giao diện chip và logic so khớp alias OSM.
- 2026-11-03 08:28 (UTC+7): Xác nhận bộ lọc nhận alias OSM và áp dụng quy ước nhật ký 10 mục.
- 2026-11-03 09:43 (UTC+7): Chuyển bộ lọc sang chọn nhiều danh mục đồng thời, thay vì lựa chọn loại trừ nhau.
