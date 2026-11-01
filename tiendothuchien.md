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
- [x] Tích hợp Firebase Authentication email/mật khẩu, đọc danh sách địa điểm Firestore, lưu/lọc yêu thích theo tài khoản và phân quyền admin bằng `/admins/{uid}`.
- [x] Cho phép xem công khai với tư cách khách; yêu cầu đăng nhập để tìm/lọc địa điểm, tra vị trí thủ công và xem ảnh vệ tinh.
- [x] Admin có thể nhập dữ liệu vào bản nháp cục bộ riêng, xem lại và xác nhận publish lên Firestore; dữ liệu local cũ được giữ nguyên, không tự chuyển lên cloud.
- [x] Khai báo Firestore Rules trong cấu hình Firebase; client không thể tự cấp quyền admin.
- [ ] Bật Firestore API, tạo database `asia-southeast1`, bật Email/Password trong Firebase Authentication và tạo document admin trên Firebase Console; đây là bước cấu hình project cần hoàn tất trước khi dùng backend thật.
- [ ] Tích hợp Firebase Storage để lưu ảnh địa điểm; hiện chức năng này chưa có.

## Kiểm thử hiện có

Thư mục `test/` có kiểm thử cho vị trí, mã hóa địa chỉ, lưu địa điểm, bản đồ,
màn hình tìm kiếm, phân tích dữ liệu nhập, splash và xử lý văn bản. Kiểm thử
màn hình tìm kiếm bao gồm quyền hiển thị thao tác bản nháp theo vai trò, luồng
chọn vị trí thủ công, ranh giới phường và chuyển lớp bản đồ.

## Phạm vi chưa triển khai

Các module tính năng chưa triển khai được liệt kê trong
[`lib/features/README.md`](lib/features/README.md); chưa được xem là chức năng
đã hoàn thành của ứng dụng.

## Cách cập nhật tiến độ

Khi thêm hoặc thay đổi chức năng, cập nhật checklist này cùng tài liệu ở
[`README.md`](README.md) hoặc tài liệu module tương ứng trong `lib/features/`.
