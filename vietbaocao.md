# Báo cáo cập nhật tính năng chọn vị trí

## Mục tiêu

Cho phép người dùng tìm địa điểm quanh một vị trí tự chọn khi không muốn bật
GPS hoặc cấp quyền vị trí.

## Kết nối Firebase

- Tạo project Firebase `do-an-2-b1f35` và đăng ký ứng dụng cho Android, iOS, Web.
- Thêm `firebase_core`, tạo `lib/firebase_options.dart` bằng FlutterFire CLI và
  khởi tạo Firebase trước khi chạy giao diện trong `lib/main.dart`.
- Android dùng cấu hình `android/app/google-services.json`; iOS, Android và Web
  dùng các tùy chọn nền tảng trong `firebase_options.dart`.
- Đây mới là bước khởi tạo Firebase Core. Dữ liệu địa điểm vẫn được lưu cục bộ;
  Authentication, Firestore và Storage chưa được kết nối.
- Cấu hình Firebase Hosting phục vụ bản Flutter Web tại
  `https://do-an-2-b1f35.web.app`. GitHub Actions build ứng dụng và deploy bản
  chính khi có push lên `main`, đồng thời tạo preview cho Pull Request nội bộ.
- GitHub Actions đọc service-account từ secret
  `FIREBASE_SERVICE_ACCOUNT_DO_AN_2_B1F35`; không lưu khóa service-account trong
  repository.

## Nội dung đã thay đổi

- Không tự gọi GPS khi mở màn hình tìm kiếm; GPS chỉ được gọi khi người dùng
  chọn nút **Dùng GPS** hoặc lựa chọn GPS trong bảng chọn vị trí.
- Thanh vị trí cho phép chọn một địa điểm đã lưu hoặc tìm địa chỉ trong TP. Cao
  Lãnh qua Nominatim/OpenStreetMap. Vị trí thủ công được dùng để tính khoảng
  cách, sắp xếp và lọc địa điểm theo bán kính như vị trí GPS.
- Bảo vệ lựa chọn thủ công khỏi bị ghi đè nếu kết quả một yêu cầu GPS đang chạy
  trả về muộn.
- Cập nhật mô tả tính năng trong `README.md` và `tiendothuchien.md`.

## Kiểm thử

- Bổ sung kiểm thử đảm bảo người dùng có thể tìm địa chỉ hoặc chọn địa điểm đã
  lưu mà không gọi dịch vụ GPS.
- Cập nhật kiểm thử để xác nhận GPS chỉ được gọi sau thao tác chủ động của người
  dùng, đồng thời luồng sắp xếp và lọc theo vị trí GPS vẫn hoạt động.
- `flutter test`: toàn bộ kiểm thử thành công.
- `flutter analyze`: còn một cảnh báo `prefer_initializing_formals` tại
  `lib/features/dia_diem/du_lieu/services/place_service.dart:21`, không thuộc
  các tệp thay đổi trong cập nhật này.

## Định hướng phát triển: Điểm vui chơi

Phần này ghi nhận phạm vi đề xuất cho phiên bản mở rộng. Các nội dung dưới đây
chưa được xem là chức năng đã triển khai trong ứng dụng hiện tại.

### Các giai đoạn phát triển

1. **Chuẩn bị phần cứng:** chuẩn bị máy tính phát triển, thiết bị Android/iOS
   để kiểm thử và các thiết bị cần thiết cho quá trình triển khai.
2. **Thiết lập Firebase:** đã tạo project và cấu hình FlutterFire cho Android,
   iOS, Web; cần bật và thiết lập các dịch vụ backend theo nhu cầu.
3. **Thiết lập Flutter project:** đã kết nối Firebase Core; tiếp tục tổ chức
   các màn hình, luồng chức năng cần đồng bộ dữ liệu hoặc tài khoản.
4. **Phát triển backend logic:** xây dựng xử lý dữ liệu địa điểm, sự kiện,
   ưu đãi, đánh giá, tài khoản và quyền theo vai trò.
5. **Phát triển UI/UX:** thiết kế giao diện cho người đăng địa điểm và sinh
   viên tìm kiếm, ưu tiên thao tác đơn giản trên điện thoại.
6. **Testing và debugging:** kiểm thử chức năng, quyền truy cập, dữ liệu và
   giao diện trên các thiết bị mục tiêu; xử lý lỗi trước khi phát hành.
7. **Deployment:** chuẩn bị cấu hình phát hành và triển khai ứng dụng lên các
   nền tảng phân phối phù hợp.
8. **Monitoring và maintenance:** theo dõi lỗi, hiệu năng và phản hồi người
   dùng; cập nhật dữ liệu, bảo trì và cải thiện ứng dụng sau phát hành.

### Vai trò và chức năng dự kiến

#### Địa điểm (người đăng)

Đối tượng gồm quán cà phê, rạp phim, khu vui chơi và các địa điểm tương tự.

- Tạo và cập nhật trang địa điểm gồm ảnh, mô tả, giờ hoạt động và giá vé hoặc
  giá dịch vụ nếu có.
- Đăng, cập nhật sự kiện và ưu đãi theo dịp, chẳng hạn Giáng sinh hoặc mùa
  khai giảng.
- Xem và trả lời đánh giá của khách.

#### Sinh viên tìm chỗ chơi (người tìm kiếm)

- Lọc địa điểm theo loại hình như cà phê, rạp phim, công viên, khu giải trí
  hoặc quán nhậu.
- Lọc theo dịp và nhu cầu như học nhóm, hẹn hò, đi nhóm bạn hoặc tìm nơi giá
  rẻ.
- Xem đánh giá và ảnh thực tế do người đã đến địa điểm chia sẻ.
- Lưu địa điểm yêu thích để tham khảo hoặc rủ bạn bè đi sau.
