# Báo cáo cập nhật tính năng chọn vị trí

## Mục tiêu

Cho phép người dùng tìm địa điểm quanh một vị trí tự chọn khi không muốn bật
GPS hoặc cấp quyền vị trí.

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
2. **Thiết lập Firebase:** tạo Firebase project và cấu hình các dịch vụ cần
   dùng cho backend của phiên bản mở rộng.
3. **Thiết lập Flutter project:** cấu hình ứng dụng Flutter để kết nối với
   Firebase và tổ chức các màn hình, luồng chức năng.
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
