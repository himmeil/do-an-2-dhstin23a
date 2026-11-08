# Tiến độ thực hiện

Tài liệu này ghi nhận trạng thái hiện hành của các chức năng trong mã nguồn ứng
dụng, các việc còn chờ và hướng làm tiếp theo. Cập nhật ngày 08/11/2026 08:40
(UTC+7).

## Quyết định hiện hành

- Tải thủ công dữ liệu bản đồ và route `/api/offline-places` đã được gỡ; splash
  không tải trước dữ liệu. Cache JSON cũ vẫn chỉ được đọc làm fallback.
- Bình luận địa điểm được đọc công khai và chỉ người đăng nhập mới có thể gửi.
  Firebase dùng `places/{placeId}/comments`; Web local dùng SQLite theo
  `backend/data/binhluan.sql`.
- Khách được xem bản đồ, chọn tâm bằng thao tác giữ bản đồ, lọc và đọc bình
  luận; GPS/tra địa chỉ, danh sách, ảnh vệ tinh, yêu thích và gửi bình luận cần
  đăng nhập.
- Các API local cập nhật/chọn snapshot OSM xác minh Firebase ID token và quyền
  qua document `admins/{uid}`. Firestore Rules đã deploy lên project cá nhân
  ngày 04/11/2026.
- Firebase Function `nearbyApi` chưa deploy; tìm kiếm OSM qua API cloud chưa
  hoạt động. Không xem các route `/api/**` là khả dụng trên Hosting.
- Module `features/admin/` có trang quản lý riêng; tài khoản admin được xác
  thực qua `admins/{uid}` mới có lối vào. Admin chuyển qua lại giữa trang xem
  địa điểm và trang quản lý; người dùng thường không thấy hoặc truy cập được
  giao diện quản trị.
- Chế độ local được chọn bằng `AppEnvironment.isLocalMode` (host local hoặc
  `APP_MODE=local`): không khởi tạo Firebase/Auth, dùng SharedPreferences và
  proxy local. Chế độ online/Firebase mới khởi tạo Firebase và dùng AuthGate.

## Trạng thái hiện hành

- Bộ lọc danh mục đã tách thành module riêng; mã cũ `bus_stop`,
  `bus_station`, `hotel` được nhận diện tương ứng là `ben_xe` và `tro`.
- Kiểm thử alias, dịch vụ tìm kiếm và thao tác chọn bộ lọc trên màn hình đều
  đạt; `flutter analyze` không phát hiện vấn đề.
- Ảnh chụp trước lần làm sạch dữ liệu cho thấy web tĩnh ở cổng `5000` nhưng
  proxy `8787` không chạy. SQLite khi đó có 1.018 đối tượng OSM, gồm cả đường
  giao thông; lỗi kết nối trước đây bị đổi thành danh sách rỗng do chưa có cache.
- Đã sửa để báo rõ khi backend không chạy và chưa có cache, đồng thời hướng dẫn
  chạy `run_web.bat`/`bat_app.bat`. Nếu dùng static server, phải chạy `npm start`
  trong `backend/` riêng rồi tải lại trang.
- Điều tra hiện tượng chỉ thấy nhóm danh mục cuối cùng: nguyên nhân là giao diện
  dùng chọn đơn (`ChoiceChip`) và trạng thái chỉ lưu một mã, không phải dữ liệu
  danh mục bị ghi đè. Đổi sang chọn nhiều nhóm độc lập; kết quả là hợp của các
  nhóm đã chọn, còn **Tất cả** xóa lựa chọn.
- Kiểm tra SQL hiện có trong bán kính mặc định: 19 quán cà phê, 11 quán ăn,
  14 nơi lưu trú và 3 mục xe buýt; có dữ liệu nhiều nhóm để hiển thị đồng thời.
- Kiểm tra snapshot SQL phát hiện mã OSM thô như `museum`, `pitch`,
  `sports_centre`, `swimming_pool` chưa được quy về danh mục ứng dụng; một số
  địa điểm vui chơi vì vậy rơi vào **Khác**. Thêm migration SQLite một lần và
  chuẩn hóa cache client; bổ sung truy vấn OSM cho sân thể thao, hồ bơi, sân tập.
  Registry danh mục dùng chung nay nhận diện alias có dấu gạch dưới/gạch nối và
  dấu tiếng Việt như `nha_tro`, `khach_san`, `hotel`, `guest_house`, `bus_stop`
  khi tạo `Place` từ Firestore/cache hoặc lọc; backend cũng dùng cùng quy tắc.
- Bổ sung kiểm thử migration theo các bản ghi thực trong SQL và kiểm thử
  chuyển mã thô thành `vui_choi` ở luồng OSM/offline.
- Các kiểm tra toàn bộ trước đó: 69 Flutter tests, 7 backend tests,
  `flutter analyze` và Web release build đều đạt. Kiểm tra mới sau lần rà soát
  bản đồ được ghi riêng dưới đây.
- Kiểm thử màn hình hiện xác nhận kết hợp xe buýt/nhà trọ/quán ăn/cà phê, bỏ
  riêng một danh mục không làm mất nhóm còn lại, và **Tất cả** xóa bộ lọc.
- Đã xử lý nguyên nhân thứ hai khiến điểm xe buýt biến mất: gộp bản ghi trùng
  khác danh mục trước khi lọc có thể giữ lại bản ghi sai nhóm. Khi đang lọc,
  ứng dụng lọc danh mục trước rồi mới gộp; các danh mục chuẩn khác nhau được
  giữ riêng, còn alias cùng nhóm vẫn gộp.
- Bổ sung kiểm thử hồi quy cho bản ghi cùng tên/cùng vị trí có nhãn thư viện và
  `bus_stop`; bộ lọc xe buýt vẫn tìm được điểm dừng. Kiểm thử màn hình, dịch vụ,
  alias, gộp trùng và `flutter analyze` đều đạt.
- Sửa tiêu chí gộp theo địa chỉ: chỉ coi địa chỉ nhà có số nhà là khóa trùng;
  tên đường giống nhau không còn làm mất các chi nhánh xa nhau. Vẫn gộp theo
  khoảng cách tối đa 50 m và chuẩn hóa tiền tố `Số`; kiểm thử hồi quy đạt.
- Đã sửa fixture kiểm thử sắp xếp khoảng cách dùng tọa độ ngoài vùng thành điểm
  nằm trong Cao Lãnh, giữ nguyên các ngưỡng khoảng cách cần kiểm tra.
- Đã sửa nguồn kết nối Web: local tiếp tục gọi `localhost:8787`, còn Firebase
  Hosting dùng origin hiện tại và rewrite `/api/**` tới Firebase Function
  `nearbyApi`. Function seed SQLite tạm từ SQL đã theo dõi trong Git.
- Tìm kiếm gần đây được phục vụ bởi backend local; endpoint thay đổi snapshot
  bản đồ cũng chỉ chạy local vì filesystem của Functions không bền vững.
- Đã sửa hợp đồng giữa parser nhập địa điểm và Firestore Rules: Rules cho phép
  mã `ben_xe` và tên tối đa 200 ký tự, khớp giới hạn parser. Trước đó thiếu mã
  này hoặc tên dài 151–200 ký tự có thể làm Firestore từ chối batch publish.
- Bổ sung kiểm thử hồi quy cho loại `ben_xe` và giới hạn tên 200/201 ký tự;
  kiểm thử parser và bộ lọc danh mục đều đạt.
- Firestore Rules đã deploy lên Firebase project cá nhân ngày 04/11/2026.
- Flutter Web release đã deploy lên site mặc định của project; URL gốc trả
  HTTP 200.
- Project chưa có Function `nearbyApi`; tìm kiếm OSM qua API cloud chưa hoạt
  động. Endpoint tải offline đã bị gỡ khỏi backend; Hosting cũng không có
  endpoint này.
- Cấu hình riêng không còn được theo dõi trong Git; file
  `ca_nhan/dulieucanhan.env` nằm trong thư mục bị bỏ qua và người fork cần
  cung cấp Firebase config của họ.
- Đã tách `features/gps`, `features/nap_du_lieu` và `features/tim_kiem` khỏi
  `features/dia_diem`; miền địa điểm giữ model, repository contracts, adapters,
  bản đồ và chi tiết.
- Tách contract `PlaceService`/`FavoriteService` khỏi adapter Firebase và local.
  Màn tìm kiếm chỉ phụ thuộc contract; `main.dart` là composition root inject
  implementation.
- Chia Flutter tests thành `test/unit/` và `test/widget/`; giữ backend deploy
  source duy nhất tại `backend/` theo `firebase.json`, không tạo Functions package
  trùng lặp.
- Tách tạo/duyệt bản nháp, quản lý snapshot local và xem mã lỗi thành trang
  quản lý riêng trong `features/admin/`; màn tìm kiếm chỉ còn lối vào cho admin.
- Tách khởi động local khỏi Firebase bằng hàm kiểm tra chế độ; local không tạo
  Firebase Auth/Firestore service.
- Xác minh sau refactor: `flutter analyze` không có vấn đề, toàn bộ 69 Flutter
  tests và 7 backend tests đều đạt; `flutter build web --release` thành công.
- Cần phương án backend phù hợp giới hạn gói miễn phí hoặc người dùng chấp thuận
  Blaze trước khi deploy `nearbyApi`; sau đó xác minh `/health` và `/api/nearby`
  trên Hosting. Endpoint offline không còn thuộc API.

## Rủi ro hiệu năng đã xác nhận từ code

Các điểm dưới đây là giới hạn mở rộng quan sát được trong mã nguồn, không phải
bằng chứng rằng chúng đã gây ra sự cố production:

- Firestore `watchAll()` stream toàn collection `places`; màn hình nhận toàn bộ
  tài liệu người dùng được phép đọc theo `orderBy('name')`, không đặt `limit`
  hay phân trang. Vì vậy dữ liệu Firestore trong mỗi snapshot có thể lọc đầy đủ
  phía client; snapshot ban đầu vẫn có thể bắt đầu từ cache trước khi đồng bộ
  máy chủ. Không thêm `limit` đơn lẻ vì sẽ âm thầm bỏ sót kết quả; muốn mở rộng
  cần thiết kế phân trang/truy vấn địa lý và cập nhật hợp đồng giao diện cùng lúc.
- Tra cứu OSM là nguồn riêng, truy vấn theo tâm/bán kính và tập tag POI được
  hỗ trợ; không tạo cache offline mới. Cache cũ có thể còn trên thiết bị. Vì vậy
  "lọc tất cả" có nghĩa là lọc toàn bộ bản ghi đã nhận từ Firestore và OSM, không
  phải toàn bộ đối tượng OSM trên thế giới hay các tag ngoài truy vấn hiện tại.
- Cache offline trong SharedPreferences là JSON; mỗi lần fallback đều decode,
  dựng lại `Place` và sắp xếp theo khoảng cách. Đây là chi phí lặp lại, nhưng
  chưa có số đo cho thấy quy mô hiện tại làm trễ đáng kể; cân nhắc SQLite trên
  thiết bị khi dữ liệu tăng và đã đo được ngưỡng.
- Bản đồ dựng tối đa 300 marker đang nằm trong viewport, chưa clustering.
  Marker ngoài viewport không được dựng; kết quả đầy đủ vẫn có trong danh sách.
- Không có trace thời gian khởi động/render hoặc heap profile để kết luận hiện
  tượng zoom đơ hay rò rỉ bộ nhớ. Cơ sở SQLite local và query plan được kiểm tra,
  nhưng chưa có backend đang chạy để xác nhận `/health` từ runtime.
- Kiểm kê file Git đang theo dõi không thấy file nào từ 100 MiB; `places.sqlite`
  runtime 184.320 byte, snapshot SQL 88.342 byte và JSON 119.691 byte sau lần
  lọc đường thuần. Chưa xác nhận được file 3xx MB trong repo; nếu người dùng
  thấy file lớn, cần xác định chính xác đường dẫn trước khi xóa hoặc tối ưu.

## Tối ưu độ trễ bộ lọc và zoom bản đồ

Người dùng báo ngày 04/11/2026 rằng chọn tiêu chí lọc bị trễ và lần zoom đầu
trên bản đồ khựng, nhưng mượt hơn sau khi chuyển chế độ rồi quay lại. Đã sửa và
kiểm tra cơ chế dữ liệu:

- Không còn lọc, gộp và sắp xếp toàn bộ địa điểm để tạo gợi ý tìm kiếm khi ô
  tìm kiếm rỗng; phần này chỉ chạy khi có truy vấn.
- Khi dữ liệu nguồn thay đổi, chuẩn bị danh sách gộp/khử trùng một lần cho cả
  hai chế độ category hiện có; chuẩn hóa category/từ khóa, tính khoảng cách và
  sắp xếp một lần theo vị trí. Chọn category/bán kính/yêu thích chỉ quét index,
  không lặp lại khử trùng, Haversine và sắp xếp toàn bộ danh sách.
- Cache kết quả lọc theo danh sách nguồn và trạng thái lọc/tìm kiếm/yêu thích/
  vị trí. Việc mở/đóng điều khiển hoặc đổi chế độ không tính lại kết quả; đổi
  tiêu chí vẫn cập nhật kết quả chính xác. Không đặt giới hạn kết quả.
- Khi zoom đủ gần để hiện marker, chỉ dựng marker nằm trong khung nhìn hiện tại;
  lọc viewport trước khi áp dụng giới hạn 300, cập nhật sau 100 ms kể từ thay
  đổi camera cuối để tránh tạo hàng trăm widget trong lúc zoom/pan. Hủy timer
  khi bản đồ bị dispose.
- Đồng bộ zoom khởi tạo nội bộ với zoom thực khi bản đồ bắt đầu chưa có dữ liệu.
- Thêm **Cài đặt hiển thị** trong menu tài khoản/khách: bật/tắt chuyển cảnh và
  chọn đồ họa bản đồ **Cao/Trung bình/Thấp**. Lưu cục bộ trên thiết bị bằng
  SharedPreferences; chất lượng điều chỉnh bộ đệm tile, không bỏ dữ liệu/marker.
  Mặc định **Trung bình** giảm tải trước tile để ưu tiên lần mở đầu; animation
  bật. Bản đồ inset tĩnh cũng không tải tile đệm ngoài khung nhìn.

Kiểm thử widget lọc, cài đặt và bản đồ đạt; analyzer không phát hiện lỗi. Chưa
profile trên thiết bị thật, do đó chưa thể định lượng mức giảm frame jank hoặc
khẳng định mọi khựng do tải/giải mã tile đã được giải quyết.

Việc còn lại là đo trên thiết bị/nền tảng nơi đã gặp lỗi: so sánh thời gian chọn
lọc và frame jank khi mở/zoom bản đồ lần đầu; nếu vẫn khựng, profile riêng tải/
giải mã tile và kiểm tra tốc độ mạng/cache tile.

## Rà soát và cập nhật danh sách bản đồ

- Snapshot OSM trước rà soát có 1.018 đối tượng, trong đó 688 là đường có tên
  (`highway=*`) nhưng không mang thẻ POI. Bộ fallback OSM API trước đó chỉ kiểm
  tra có tên, khác với truy vấn Overpass và làm các đoạn đường lọt vào danh sách.
- Đã sửa backend và cache Flutter để giữ địa điểm có tên, giữ trạm xe buýt và
  POI chưa biết loại, nhưng bỏ đối tượng chỉ là đường. Snapshot SQL/JSON hiện
  còn 330 mục; SQL được đồng bộ lại, JSON cũ được lưu làm bản backup. Số đếm
  theo loại: `ben_xe` 13, `tro` 14, `vui_choi` 19, `khac` 201; mã lạ vẫn ở
  **Khác**, không tự gán.
- Danh sách transit trong snapshot: 2 `amenity=bus_station`, 11
  `highway=bus_stop`. OSM API hiện vẫn ghi nhận [Bến xe Cao Lãnh](https://www.openstreetmap.org/way/169422508)
  và [Bến xe tải Cao Lãnh](https://www.openstreetmap.org/way/169959572).
- Hai stop [quán nem](https://www.openstreetmap.org/node/4935721121) và
  [quán nem.nguyen binh](https://www.openstreetmap.org/node/5279142122) cách
  nhau khoảng 7,3 m. Chưa xóa/gộp: khoảng cách gần có thể là hai phía đường;
  chưa có nguồn vận tải xác nhận chúng là bản ghi trùng.
- Google Maps trả trang động không đọc được kết quả địa điểm; tìm nguồn chính
  thức không cho danh sách có thể kiểm chứng trong phiên này. Vì vậy cập nhật
  trên chỉ làm sạch loại đối tượng chắc chắn là đường và đồng bộ danh mục, không
  tuyên bố đã tìm đủ điểm mới hoặc xác nhận toàn bộ 13 bến/trạm. Cần đối chiếu
  thủ công với nguồn vận tải/Google trước khi thêm hoặc xóa transit.

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
- [x] Cho phép khách xem bản đồ, lọc và đọc bình luận; yêu cầu đăng nhập để gửi
  bình luận, đổi tâm/GPS, xem danh sách, ảnh vệ tinh và lưu yêu thích.
- [x] Admin có thể nhập dữ liệu vào bản nháp cục bộ riêng, xem lại và xác nhận publish lên Firestore; dữ liệu local cũ được giữ nguyên, không tự chuyển lên cloud.
- [x] Khai báo Firestore Rules trong cấu hình Firebase; client không thể tự cấp quyền admin.
- [x] Ghi nhận kiến trúc demo: Firebase dùng để minh họa khả năng vận hành web
  thực tế; dữ liệu bản đồ được phục vụ qua server local để tránh CORS khi gọi
  nguồn OpenStreetMap trực tiếp từ trình duyệt.
- [x] Cấu hình Firestore/Auth cho project cá nhân và deploy Firestore Rules ngày
  04/11/2026; document `/admins/{uid}` vẫn cần được cấp riêng trên Firebase
  Console cho từng tài khoản quản trị.
- [ ] Tích hợp Firebase Storage để lưu ảnh địa điểm; hiện chức năng này chưa có.
- [x] Tạo proxy/server local trong `backend/` cho dữ liệu OpenStreetMap, ưu tiên
  Overpass và tự fallback sang OpenStreetMap API khi Overpass timeout.
- [x] Tải toàn bộ dữ liệu có tên trong bbox Cao Lãnh theo nhiều ô, ghép loại
  trùng và lưu vào SQLite; chức năng tải bản sao offline đã được gỡ.
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
- [x] Đồng bộ Firestore Rules với dữ liệu nhập: cho phép `ben_xe` và tên địa
  điểm dài tối đa 200 ký tự; bổ sung kiểm thử ranh giới 200/201 ký tự.
- [x] Tạo module trang quản lý riêng cho admin, có thể quay lại chế độ người
  xem; tài khoản không có document `/admins/{uid}` không có lối vào trang này.

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
- `flutter test test/widget/nearby_screen_test.dart`
- `flutter test test/unit/place_category_filter_test.dart test/unit/place_deduplication_test.dart test/unit/nearby_places_service_test.dart`
- `flutter test test/unit/place_import_parser_test.dart test/unit/place_category_filter_test.dart`
  (10 kiểm thử đạt; gồm kiểm tra `ben_xe` và ranh giới tên 200/201 ký tự).
- Kiểm thử lỗi proxy không có cache và thông báo khởi động backend trên UI.
- Xác nhận trong SQLite có hai bến xe trong bán kính 5 km từ tâm mặc định.
- Nạp SQL vào SQLite thử nghiệm và xác nhận mã danh mục của xe buýt, nhà trọ,
  ký túc xá, công viên thiếu nhi và trung tâm giáo dục.
- Cập nhật map thật từ `osm-api`: 1.018 đối tượng, 16 ô dữ liệu.

## Hướng làm tiếp theo

1. Xác nhận tài khoản quản trị có document `/admins/{uid}` rồi kiểm tra publish
   địa điểm `ben_xe` và tên 151–200 ký tự trên project.
2. Nếu trang vẫn báo backend chưa chạy, khởi động bằng `run_web.bat`/`bat_app.bat`
   hoặc chạy `npm start` trong `backend/`, xác nhận `/health` trả `ok: true`.
3. Nếu dữ liệu khác với SQL, cập nhật map từ Admin, kiểm tra phân loại và đồng
   bộ snapshot SQL/JSON.
4. Chọn hạ tầng cho API OSM động trên cloud (ví dụ Cloud Run hoặc nâng cấp gói
   Firebase rồi triển khai Functions). Hiện Hosting dùng snapshot tĩnh; duy trì
   tác vụ cập nhật snapshot trên backend local cho tới khi có kho lưu trữ cloud
   bền vững và kiểm soát quyền admin ở backend.

## Cách cập nhật tiến độ

Khi thêm hoặc thay đổi chức năng, cập nhật checklist này cùng tài liệu ở
[`README.md`](README.md) hoặc tài liệu module tương ứng trong `lib/features/`.
Tài liệu tiến độ phải luôn mô tả trạng thái hiện hành: đánh dấu việc hoàn tất,
ghi rõ việc còn chờ và thay thế hướng làm tiếp theo khi kế hoạch thay đổi.
