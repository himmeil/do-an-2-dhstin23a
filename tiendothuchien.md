# Tiến độ thực hiện

Tài liệu này ghi nhận trạng thái hiện hành của các chức năng trong mã nguồn ứng
dụng, các việc còn chờ và hướng làm tiếp theo. Cập nhật ngày 03/11/2026 09:53
(UTC+7).

## Trạng thái hiện hành

- Bộ lọc danh mục đã tách thành module riêng; mã cũ `bus_stop`,
  `bus_station`, `hotel` được nhận diện tương ứng là `ben_xe` và `tro`.
- Kiểm thử alias, dịch vụ tìm kiếm và thao tác chọn bộ lọc trên màn hình đều
  đạt; `flutter analyze` không phát hiện vấn đề.
- Ảnh chụp cho thấy web tĩnh ở cổng `5000` nhưng proxy `8787` không chạy. SQLite
  có 1.018 địa điểm và có hai bến xe trong bán kính 5 km; lỗi kết nối trước đây
  bị đổi thành danh sách rỗng do chưa có cache offline.
- Đã sửa để báo rõ khi backend không chạy và chưa có cache, đồng thời hướng dẫn
  chạy `run_web.bat`/`bat_app.bat`. Nếu dùng static server, phải chạy `npm start`
  trong `backend/` riêng rồi tải lại trang.
- Điều tra hiện tượng chỉ thấy nhóm danh mục cuối cùng: nguyên nhân là giao diện
  dùng chọn đơn (`ChoiceChip`) và trạng thái chỉ lưu một mã, không phải dữ liệu
  danh mục bị ghi đè. Đổi sang chọn nhiều nhóm độc lập; kết quả là hợp của các
  nhóm đã chọn, còn **Tất cả** xóa lựa chọn.
- Kiểm tra SQL hiện có trong bán kính mặc định: 19 quán cà phê, 11 quán ăn,
  14 nơi lưu trú và 3 mục xe buýt; có dữ liệu nhiều nhóm để hiển thị đồng thời.
- Kiểm thử màn hình hiện xác nhận kết hợp xe buýt/nhà trọ/quán ăn/cà phê, bỏ
  riêng một danh mục không làm mất nhóm còn lại, và **Tất cả** xóa bộ lọc.
- Đã xử lý nguyên nhân thứ hai khiến điểm xe buýt biến mất: gộp bản ghi trùng
  khác danh mục trước khi lọc có thể giữ lại bản ghi sai nhóm. Khi đang lọc,
  ứng dụng lọc danh mục trước rồi mới gộp; các danh mục chuẩn khác nhau được
  giữ riêng, còn alias cùng nhóm vẫn gộp.
- Bổ sung kiểm thử hồi quy cho bản ghi cùng tên/cùng vị trí có nhãn thư viện và
  `bus_stop`; bộ lọc xe buýt vẫn tìm được điểm dừng. Kiểm thử màn hình, dịch vụ,
  alias, gộp trùng và `flutter analyze` đều đạt.
- Đã sửa fixture kiểm thử sắp xếp khoảng cách dùng tọa độ ngoài vùng thành điểm
  nằm trong Cao Lãnh, giữ nguyên các ngưỡng khoảng cách cần kiểm tra.
- Backend local phục vụ web demo; proxy vẫn cần phương án tương đương khi triển
  khai Hosting.

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
- [x] Thêm nút **Zoom + / Zoom -** trên bản đồ chính và bản đồ chi tiết;
  kiểm tra chuyển ảnh vệ tinh không làm thay đổi marker hoặc điều khiển zoom.
- [x] Chuẩn hóa phân loại lưu trú, xe buýt, giáo dục và công viên trong dữ liệu
  SQL; nhận diện theo thẻ OpenStreetMap và tên địa điểm để đưa vào bộ lọc đúng.
- [x] `run_web.bat` kiểm tra backend local và tự khởi động backend khi chưa chạy,
  tránh trang web hiện danh sách rỗng chỉ vì thiếu proxy `localhost:8787`.
- [x] Tách bộ lọc danh mục/bán kính sang `tim_kiem/bo_loc/`; chuẩn hóa alias
  `bus_stop`, `bus_station`, `hotel` trước khi lọc và hiển thị metadata.
- [x] Bổ sung kiểm thử UI xác nhận dữ liệu alias xe buýt và khách sạn vào đúng
  bộ lọc; kiểm thử dịch vụ, model và static analysis đều đạt.
- [x] Không còn che giấu tình trạng proxy mất kết nối bằng danh sách rỗng khi
  chưa có cache offline; màn hình chỉ cách khởi động backend.
- [x] Cho phép chọn đồng thời quán ăn, cà phê, nhà trọ, bến xe hoặc tổ hợp bất
  kỳ; các alias `bus_stop`, `bus_station`, `hotel` vẫn dùng bộ lọc mã chuẩn.

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

Các kiểm tra gần nhất (03/11/2026) đã đạt:

- `node --check backend/server.js`
- `flutter analyze`
- `flutter test test/nearby_screen_test.dart`
- `flutter test test/place_category_filter_test.dart test/place_deduplication_test.dart test/nearby_places_service_test.dart`
- Kiểm thử lỗi proxy không có cache và thông báo khởi động backend trên UI.
- Xác nhận trong SQLite có hai bến xe trong bán kính 5 km từ tâm mặc định.
- Nạp SQL vào SQLite thử nghiệm và xác nhận mã danh mục của xe buýt, nhà trọ,
  ký túc xá, công viên thiếu nhi và trung tâm giáo dục.
- Cập nhật map thật từ `osm-api`: 1.018 đối tượng, 16 ô dữ liệu.

## Hướng làm tiếp theo

1. Tải lại/rebuild Flutter Web để nhận các sửa đổi mới; xác nhận trên dữ liệu
   thật rằng lọc **Bến xe / điểm dừng** không làm mất quán ăn, cà phê hoặc nhà
   trọ đã chọn, kể cả khi có bản ghi trùng tên khác danh mục.
2. Nếu trang vẫn báo backend chưa chạy, khởi động bằng `run_web.bat`/`bat_app.bat`
   hoặc chạy `npm start` trong `backend/`, xác nhận `/health` trả `ok: true`.
3. Nếu dữ liệu khác với SQL, cập nhật map từ Admin, kiểm tra phân loại và đồng
   bộ snapshot SQL/JSON.
4. Trước khi triển khai Hosting, cấu hình proxy tương đương trên Cloud Run hoặc
   Firebase Functions; hoàn tất cấu hình Firestore/Auth và tích hợp Storage nếu
   các chức năng này cần cho bản production.

## Cách cập nhật tiến độ

Khi thêm hoặc thay đổi chức năng, cập nhật checklist này cùng tài liệu ở
[`README.md`](README.md) hoặc tài liệu module tương ứng trong `lib/features/`.
Tài liệu tiến độ phải luôn mô tả trạng thái hiện hành: đánh dấu việc hoàn tất,
ghi rõ việc còn chờ và thay thế hướng làm tiếp theo khi kế hoạch thay đổi.
