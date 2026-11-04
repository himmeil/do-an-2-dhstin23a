# Thư mục `lib`

Mã nguồn Flutter của ứng dụng. `main.dart` khởi tạo Firebase và lắp ghép các
adapter. `core/` chứa tiện ích nền tảng không thuộc miền nghiệp vụ; `features/`
chia ứng dụng theo chức năng. `firebase_options.dart` giữ cấu hình nền tảng.

```text
lib/
  core/
    constants/ theme/ utils/ widgets/
  features/
    dia_diem/
      ban_do/ chi_tiet/ du_lieu/models/ du_lieu/repositories/ services/
    gps/
    nap_du_lieu/
    tim_kiem/
    mini_game/
    tai_khoan/
    hoac_khu_benh/ quach_thanh/   # placeholder minh chứng, chưa triển khai
  firebase_options.dart
  main.dart
```

Hạ tầng không được khởi tạo trong widget. `main.dart` inject các adapter;
screen dùng contract repository và model thuần. Firebase Functions vẫn được
deploy từ `backend/` để giữ một nguồn API duy nhất theo `firebase.json`.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Tích hợp chuẩn bị cache địa điểm và tile bản đồ trong luồng khởi động ứng dụng.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký.
- 2026-11-03 14:40 (UTC+7): Cập nhật sơ đồ source sau khi tách feature địa điểm và data adapter.
