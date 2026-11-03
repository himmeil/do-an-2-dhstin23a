# Thư mục `lib`

Mã nguồn Flutter của ứng dụng. Điểm khởi chạy và lắp ghép các dịch vụ nằm tại
`main.dart`; mã chức năng được tổ chức trong `core/` và `features/`.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Tích hợp chuẩn bị cache địa điểm và tile bản đồ trong luồng khởi động ứng dụng.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký.
