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
- [x] Ghi nhận kiến trúc demo: Firebase dùng để minh họa khả năng vận hành web
  thực tế; dữ liệu bản đồ được phục vụ qua server local để tránh CORS khi gọi
  nguồn OpenStreetMap trực tiếp từ trình duyệt.
- [ ] Bật Firestore API, tạo database `asia-southeast1`, bật Email/Password trong Firebase Authentication và tạo document admin trên Firebase Console; đây là bước cấu hình project cần hoàn tất trước khi dùng backend thật.
- [ ] Tích hợp Firebase Storage để lưu ảnh địa điểm; hiện chức năng này chưa có.
- [x] Tạo proxy/server local trong `backend/` cho dữ liệu OpenStreetMap, ưu tiên
  Overpass và tự fallback sang OpenStreetMap API khi Overpass timeout.
- [x] Tải toàn bộ dữ liệu có tên trong bbox Cao Lãnh theo nhiều ô, ghép loại
  trùng, lưu vào SQLite và cho người dùng đã đăng nhập tải bản sao offline.
- [x] Tạo các bản sao `dia_diem_cao_lanh.json` và
  `dia_diem_cao_lanh.sql`, đồng thời backup bản cũ sau mỗi lần cập nhật map.

## Kiểm thử hiện có

Thư mục `test/` có kiểm thử cho vị trí, mã hóa địa chỉ, lưu địa điểm, bản đồ,
màn hình tìm kiếm, phân tích dữ liệu nhập, splash và xử lý văn bản. Kiểm thử
màn hình tìm kiếm bao gồm quyền hiển thị thao tác bản nháp theo vai trò, luồng
chọn vị trí thủ công, ranh giới phường và chuyển lớp bản đồ.

## Phạm vi chưa triển khai

Các module tính năng chưa triển khai được liệt kê trong
[`lib/features/README.md`](lib/features/README.md); chưa được xem là chức năng
đã hoàn thành của ứng dụng.

## Định hướng mở rộng: Điểm vui chơi

### Vai trò Địa điểm (người đăng)

- Tạo trang địa điểm với ảnh, mô tả, giờ hoạt động và giá vé/giá dịch vụ nếu có.
- Cập nhật sự kiện, ưu đãi theo dịp như Giáng sinh hoặc khai giảng.
- Trả lời đánh giá của người dùng.

### Vai trò Sinh viên tìm chỗ chơi (người tìm kiếm)

- Lọc theo loại hình: cà phê, rạp phim, công viên, khu giải trí, quán nhậu.
- Lọc theo dịp: học nhóm, hẹn hò, đi nhóm bạn, giá rẻ.
- Xem đánh giá và ảnh thực tế từ người đã đến.
- Lưu địa điểm yêu thích để rủ bạn bè đi sau.

## Cách chạy và kiểm tra

Chi tiết lệnh chạy backend, Flutter Web, cập nhật map và kiểm tra endpoint nằm
trong [README.md](README.md) và [backend/README.md](backend/README.md).

Các kiểm tra gần nhất đã đạt:

- `node --check backend/server.js`
- `flutter analyze`
- `flutter test test/nearby_places_service_test.dart`
- Cập nhật map thật từ `osm-api`: 1.018 đối tượng, 16 ô dữ liệu.

## Cách cập nhật tiến độ

Khi thêm hoặc thay đổi chức năng, cập nhật checklist này cùng tài liệu ở
[`README.md`](README.md) hoặc tài liệu module tương ứng trong `lib/features/`.
