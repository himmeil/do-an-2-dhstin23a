# Tiến độ thực hiện

Tài liệu này ghi nhận các chức năng đã có trong mã nguồn của ứng dụng. Cập nhật
ngày 01/11/2026.

## Chức năng đã có

- [x] Khởi chạy ứng dụng Flutter với giao diện sáng/tối và màn hình splash.
- [x] Cho phép chủ động dùng GPS hoặc chọn địa chỉ/địa điểm đã lưu làm vị trí xuất phát; không yêu cầu bật GPS khi mở app.
- [x] Hiển thị địa điểm gần đây theo danh sách và bản đồ OpenStreetMap.
- [x] Chuyển đổi giữa bản đồ đường phố OpenStreetMap và ảnh vệ tinh Esri ở bản đồ khu vực và bản đồ chi tiết.
- [x] Tái sử dụng ảnh splash làm nền màn hình chưa có dữ liệu và thống nhất kiểu nút chính trong app.
- [x] Thêm minh họa bản đồ riêng cho màn hình khởi tạo và âm báo hệ thống khi nạp địa điểm thành công.
- [x] Hiển thị ranh giới phường Cao Lãnh trên bản đồ, kể cả trước khi nạp địa điểm.
- [x] Tìm kiếm theo từ khóa; lọc theo loại địa điểm và bán kính.
- [x] Tìm địa chỉ bằng Nominatim/OpenStreetMap.
- [x] Xem chi tiết địa điểm và mở chỉ đường bằng Google Maps.
- [x] Nạp địa điểm từ CSV/TSV hoặc JSON, thêm địa điểm thủ công và tạo dữ liệu mẫu.
- [x] Lưu dữ liệu cục bộ bằng SharedPreferences; không cần tài khoản hay máy chủ riêng.
- [x] Khởi tạo Firebase Core với cấu hình FlutterFire cho Android, iOS và Web.
- [x] Cấu hình Firebase Hosting cho Flutter Web và GitHub Actions tự build/deploy khi cập nhật nhánh `main`.
- [ ] Chuyển dữ liệu địa điểm sang Firebase; hiện ứng dụng vẫn chỉ lưu dữ liệu trên thiết bị.
- [ ] Tích hợp Firebase Authentication, Firestore hoặc Storage khi hoàn thiện các chức năng cần tài khoản và đồng bộ dữ liệu.

## Kiểm thử hiện có

Thư mục `test/` có kiểm thử cho vị trí, mã hóa địa chỉ, lưu địa điểm, bản đồ,
màn hình tìm kiếm, phân tích dữ liệu nhập, splash và xử lý văn bản. Kiểm thử
màn hình tìm kiếm cho luồng xem ranh giới phường và bản đồ chi tiết cho luồng
chuyển lớp bản đồ đã chạy thành công.

## Phạm vi chưa triển khai

Các module tính năng chưa triển khai được liệt kê trong
[`lib/features/README.md`](lib/features/README.md); chưa được xem là chức năng
đã hoàn thành của ứng dụng.

## Cách cập nhật tiến độ

Khi thêm hoặc thay đổi chức năng, cập nhật checklist này cùng tài liệu ở
[`README.md`](README.md) hoặc tài liệu module tương ứng trong `lib/features/`.
