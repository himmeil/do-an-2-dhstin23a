# Feature quản trị

Module `screens/admin_management_screen.dart` cung cấp trang quản lý riêng cho
tài khoản có quyền admin. Màn xem địa điểm vẫn là trải nghiệm chính; admin có
thể chuyển từ đó sang quản lý và quay lại chế độ người xem.

Quyền truy cập lấy từ document `admins/{uid}` qua `AuthService.watchIsAdmin`.
Ứng dụng chỉ hiển thị lối vào trang quản lý khi tài khoản có quyền; màn quản lý
cũng từ chối hiển thị chức năng nếu không có quyền. Firestore Rules và backend
tiếp tục là lớp bảo vệ dữ liệu/thao tác, không dựa riêng vào ẩn giao diện.

Trang quản lý hiện có:

- Tạo bản nháp địa điểm và duyệt trước khi đăng lên Firestore.
- Cập nhật hoặc chọn snapshot bản đồ khi chạy backend local.
- Xem các mã lỗi hệ thống gần đây.

Firebase Hosting đọc snapshot OSM tĩnh nên các thao tác cập nhật/chọn snapshot
chỉ khả dụng trên backend local. Tài khoản không phải admin không thấy nút
quản lý trong màn xem và không thể mở các thao tác quản trị.
