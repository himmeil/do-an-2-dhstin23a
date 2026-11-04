# Địa điểm quanh đây

App Flutter chỉ làm một việc: **tìm địa điểm xung quanh vị trí người dùng chọn**.

- Tiến độ chức năng: [tiendothuchien.md](tiendothuchien.md).
- Cấu trúc source và quy tắc phụ thuộc: [lib/README.md](lib/README.md) và
  [lib/features/README.md](lib/features/README.md). Các feature GPS, tìm kiếm,
  nạp dữ liệu tách riêng; UI dùng repository contracts, adapters được inject
  từ `main.dart`.
- Kiến trúc demo: Firebase dùng để chứng minh khả năng triển khai web thực tế
  (Authentication, Firestore và Hosting); khi trình diễn, dịch vụ quản lý và
  proxy truy vấn bản đồ được chạy local để chủ động kiểm soát dữ liệu và tránh
  trình duyệt bị chặn khi gọi Overpass trực tiếp.
- Dùng GPS theo lựa chọn của người dùng hoặc chọn vị trí thủ công; liệt kê địa điểm gần nhất trước và hiện khoảng cách.
- Mặc định mở bản đồ quanh tâm Phường Cao Lãnh với ranh giới phường, bán kính 5 km và các ghim quán cà phê/trường học tìm được; có thể đổi 1/5/10 km hoặc chọn tâm khác bằng cách nhấn giữ trên bản đồ.
- Bộ tìm kiếm có thể thu gọn bằng nút kính lúp trên thanh công cụ để dành thêm diện tích cho bản đồ. Trạng thái lỗi và rỗng được hiển thị gọn phía trên bản đồ, không chồng lên vùng thao tác.
- Bản đồ chỉ hiện marker ping khi người dùng chọn/tìm vị trí mới; các địa điểm
  OpenStreetMap dùng icon nhỏ theo loại địa điểm và giới hạn số marker vẽ trên
  bản đồ để tránh lag. Các chấm địa điểm chỉ hiện khi zoom đạt khoảng 96%
  mức tối đa; danh sách kết quả vẫn giữ đầy đủ dữ liệu.
- Bản đồ được giới hạn trong khu vực Cao Lãnh; dữ liệu địa điểm không tải quốc gia ngoài vùng này.
- Bản đồ tìm kiếm có inset định vị Hoàng Sa và Trường Sa trên nền OpenStreetMap; có thể ẩn/hiện inset. Inset dùng ghim vị trí tham khảo, không vẽ đường biên hay ranh giới chủ quyền.
- Bản đồ chính và bản đồ chi tiết có nút **Zoom +** và **Zoom -** trên màn
  hình; người dùng không cần bấm hai lần vào bản đồ để phóng to/thu nhỏ.
  Nút chuyển **Xem vệ tinh** chỉ thay lớp tile nền, không ảnh hưởng marker hay
  bộ điều khiển zoom.
- Lọc theo loại (quán ăn, cà phê, trường học, nhà trọ, vui chơi, mua sắm, khác), bán kính (1 / 5 / 10 km / tất cả) và từ khóa (tìm không dấu được). Bộ lọc loại và bán kính chỉ mở khi bấm **Lọc** cạnh ô tìm kiếm.
- Nhập tên địa điểm rồi bấm nút mũi tên **Tìm** để lọc kết quả. Các tên
  trùng khớp sẽ hiện thành danh sách gợi ý; bấm một địa điểm để bản đồ tự
  phóng tới vị trí đó và đánh dấu bằng ghim đỏ.
- GPS không tự bật khi mở app. Người dùng có thể giữ trên bản đồ để chọn một điểm làm tâm tìm kiếm, không cần cấp quyền vị trí; cũng có thể bấm thanh vị trí để nhập địa chỉ (Nominatim/OpenStreetMap) hoặc chọn địa điểm đã nạp. Nút GPS chỉ lấy vị trí khi người dùng chủ động chọn.
- App truy vấn SQLite local theo bán kính 1/5/10 km. Admin cập nhật dữ liệu từ Overpass; nếu Overpass timeout, backend tự dùng OpenStreetMap API, lưu dữ liệu Cao Lãnh vào SQLite. Lựa chọn “Tất cả” gồm địa điểm đã lưu và dữ liệu bản đồ local.
- **Web local:** Flutter Web gọi proxy trong thư mục `backend/` tại
  `localhost:8787`; `run_web.bat` và `bat_app.bat` tự khởi động proxy.
  **Firebase Hosting:** app nhận biết môi trường production khi build với
  `APP_MODE=firebase`, không gọi `localhost` và không tải snapshot bản đồ
  offline. Endpoint `/api/**` chỉ hoạt động khi có backend Function được
  triển khai; hiện Function chưa được triển khai.
- Khi vào màn hình chính trên Web local, splash tải trước dữ liệu địa điểm
  Cao Lãnh qua backend để lưu cache cục bộ. Firebase Hosting bỏ qua bước này
  và ẩn thao tác tải offline. Tile raster chỉ tải theo vùng bản đồ đang nhìn;
  Web phụ thuộc HTTP cache của trình duyệt/nhà cung cấp tile.
- **Chế độ offline local:** sau khi đã tải dữ liệu trên Web local, khi
  Overpass hoặc proxy không phản hồi, Flutter dùng cache cục bộ để lọc theo
  bán kính và hiển thị địa điểm. Cache đã có vẫn được giữ; bản Firebase không
  tạo hoặc tải mới cache này.
  Dữ liệu địa lý dùng OpenStreetMap; nền bản đồ đường phố tải từ OpenStreetMap
  HOT để tránh các ô xám khi máy chủ tile OSM chính bị giới hạn hoặc lỗi kết
  nối. Tile raster vẫn cần mạng nếu chưa được cache; API offline chỉ lưu dữ
  liệu địa điểm, không tải gói ảnh bản đồ.
- **Mô hình chạy demo local:** Flutter Web chạy trên trình duyệt, còn server
  local làm lớp trung gian gọi Overpass và trả dữ liệu cửa hàng, quán cà phê,
  rạp phim, công viên và khu vui chơi về cho ứng dụng. Khi triển khai chính
  thức, server local có thể thay bằng Firebase Functions hoặc Cloud Run.
- Xem dạng danh sách hoặc bản đồ; dùng nút góc trên bên phải để chuyển giữa
  bản đồ đường phố OpenStreetMap HOT và ảnh vệ tinh Esri. Trang chi tiết
  cũng có nút chuyển lớp bản đồ và nút **Chỉ đường** (mở Google Maps).
- Trên bản đồ có thể xem ranh giới phường Cao Lãnh (dữ liệu OpenStreetMap).
- Khách có thể vào xem danh sách, chi tiết và bản đồ đường phố không cần tài khoản. Đăng nhập bằng email/mật khẩu để tìm kiếm/lọc, tra vị trí thủ công, xem ảnh vệ tinh và lưu địa điểm yêu thích; quản trị viên có thể tạo bản nháp trên thiết bị, xem lại rồi xác nhận đăng lên Firestore.
- Màn tạo bản nháp có 3 cách: dán CSV/JSON (hoặc copy từ Excel/Google Sheets), thêm tay từng điểm, hoặc tạo dữ liệu mẫu quanh bạn để thử. Dữ liệu cũ trong bộ nhớ trên thiết bị được giữ nguyên và không tự tải lên.
- Firebase Core, Authentication và Firestore nhận cấu hình client từ
  `dulieucanhan.env` khi build. Tạo file này bằng cách sao chép
  `dulieucanhan.env.example`, rồi điền cấu hình Firebase của dự án bạn.
  File cá nhân bị `.gitignore` loại khỏi Git; không commit hoặc gửi file này.
- Các link dịch vụ `NEARBY_API_BASE_URL`, `OVERPASS_API_URL`,
  `OVERPASS_FALLBACK_URLS`, `OSM_MAP_API_URL`, `NOMINATIM_SEARCH_URL`,
  `STREET_TILE_URL`, `SATELLITE_TILE_URL` và `DIRECTIONS_URL` cũng nằm trong
  file này; mã nguồn không đóng cứng địa chỉ máy chủ. GitHub Actions kiểm tra
  đủ các link trước khi build.
- Dùng `deploy_firebase.bat` để build production và deploy riêng Hosting.
  Build này đặt `APP_MODE=firebase`, tự tắt tải map offline và lấy project ID
  từ file cấu hình cá nhân. Endpoint tìm kiếm `/api/**` vẫn cần backend
  Function; không deploy Functions để tránh yêu cầu gói Blaze.
- Hosting và Firestore là hai phần riêng: deploy web không tự nạp SQLite
  local lên cloud.

## Tài nguyên đồ họa

- Ảnh `assets/splash/launch.jpg` được dùng cho splash khởi động và làm nền có phủ mờ ở màn hình chưa có dữ liệu.
- Minh họa bản đồ địa điểm `assets/illustrations/nearby_map.png` giúp màn hình khởi tạo dữ liệu sinh động hơn; đây là đồ họa riêng cho app, không dùng tài nguyên trò chơi không liên quan.
- Các nút chính dùng kiểu Material 3 thống nhất, bo góc và có vùng bấm đủ lớn; chưa cần ảnh riêng cho từng nút.
- Khi nạp địa điểm thành công, app phát âm báo hệ thống trung tính; không tự phát âm thanh khi mở app.
- Thêm ảnh splash vào `assets/splash/` hoặc minh họa vào `assets/illustrations/`; các thư mục đã được khai báo trong `pubspec.yaml`.

## Định dạng dữ liệu để dán

CSV, dòng đầu là tiêu đề (không bắt buộc, nếu bỏ thì đúng thứ tự cột này):

```
name,category,address,lat,lng,phone,hours
Cơm tấm Cô Ba,quan_an,"12 Nguyễn Trãi, P.1",10.4571,105.6332,0901234567,06:00 - 21:00
```

JSON: mảng các đối tượng cùng tên trường (`name`, `category`, `address`, `lat`, `lng`, `phone`, `hours`).
`category` là một trong `quan_an, cafe, truong_hoc, tro, vui_choi, mua_sam, khac` hoặc tên tiếng Việt ("Cà phê", "trường học", "nhà trọ"...).
Nạp lại cùng tên + tọa độ thì ghi đè, không bị nhân đôi.

## Chạy thử trên máy (localhost)

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh
flutter pub get
flutter analyze
flutter test
```

Khởi động proxy bản đồ ở một cửa sổ PowerShell khác:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh\backend
npm.cmd start
```

Có thể dùng nhanh các file Windows ở thư mục gốc:

```text
bat_app.bat   - bật backend và Flutter Web
tat_app.bat   - tắt tiến trình đang dùng cổng 8787 và 5000
```

Trước lần chạy đầu, sao chép `dulieucanhan.env.example` thành
`dulieucanhan.env` và điền cấu hình Firebase của dự án riêng. Đây là JSON được
Flutter đọc bằng `--dart-define-from-file`, không phải file dotenv dạng
`KEY=value`. Không đưa file cá nhân lên Git.

Nên chạy `tat_app.bat` khi kết thúc demo để giải phóng hai cổng này.
Trong cửa sổ Backend và Flutter Web, bấm `R` để reload tương ứng; bấm `Q` để
đóng từng cửa sổ. `tat_app.bat` sẽ đóng cả hai cửa sổ và các tiến trình con.
`run_web.bat` là script build Flutter Web rồi chạy web server tĩnh bằng Python;
thông báo `Dang phuc vu build\web` nghĩa là app đã chạy, không phải bị treo.

Sau đó chạy Flutter Web:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh
flutter build web --no-pub --dart-define-from-file=dulieucanhan.env
python -m http.server 5000 --directory build\web --bind 127.0.0.1
# Mở http://localhost:5000 bằng trình duyệt
# Chế độ debug nếu cần hot reload:
flutter run -d web-server --web-port 5000 --dart-define-from-file=dulieucanhan.env
flutter run --dart-define-from-file=dulieucanhan.env
```

Nếu báo lỗi cổng `5000` đã được sử dụng, chạy `tat_app.bat` trước rồi chạy
lại. Cách đơn giản hơn là chỉ chạy `bat_app.bat`; file này tự build và mở web
server đúng cấu hình.

Khi dùng server local cho dữ liệu bản đồ, khởi động server trước rồi chạy
Flutter Web. Proxy mặc định ở `http://localhost:8787`.

### Deploy web

Chạy file dưới đây để build production (tắt tải map offline) và deploy
Firebase Hosting:

```text
deploy_firebase.bat
```

Không deploy Firestore Rules hoặc Functions tự động qua lệnh này.

Kiểm tra nhanh dữ liệu cloud:

```powershell
$projectId = (Get-Content dulieucanhan.env -Raw | ConvertFrom-Json).FIREBASE_PROJECT_ID
Invoke-RestMethod `
  -Uri "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/places?pageSize=1"
```

Không xóa collection `places` khi chỉ deploy Hosting. Nếu cần nạp snapshot
địa điểm mới, dùng chức năng admin **Đăng địa điểm lên cloud** hoặc chạy quy
trình seed Firestore đã được cấp quyền; không đưa service-account JSON vào
ứng dụng hay repository.

### Cập nhật dữ liệu bản đồ Cao Lãnh

Đăng nhập bằng tài khoản admin, mở màn hình địa điểm và chọn **Cập nhật bản
đồ từ Overpass**. Backend sẽ thử Overpass trước, sau đó tự chuyển sang
OpenStreetMap API nếu Overpass lỗi. Dữ liệu được chia thành nhiều ô nhỏ, ghép
loại trùng và lưu vào:

- `backend/data/places.sqlite`: dữ liệu SQLite để tìm kiếm.
- `backend/data/dia_diem_cao_lanh.json`: bản sao JSON để offline.
- `backend/data/dia_diem_cao_lanh.sql`: các lệnh SQL để khôi phục/chuyển database.
- Các file `backup_*`: bản sao của lần cập nhật trước.

Admin cũng có thể mở **Công cụ quản trị → Chọn dữ liệu bản đồ Cao Lãnh** để
xem số lượng/ngày cập nhật và chuyển giữa file bản mới với file backup. Lựa
chọn đang dùng được giữ lại sau khi khởi động lại backend; thao tác này không
ghi đè các file snapshot.

Có thể gọi trực tiếp bằng PowerShell:

```powershell
Invoke-RestMethod `
  -Uri http://localhost:8787/api/admin/update-map `
  -Method Post `
  -TimeoutSec 300
```

Kiểm tra dữ liệu:

```powershell
Invoke-RestMethod http://localhost:8787/health
Invoke-RestMethod http://localhost:8787/api/offline-places
```

Nếu cần tăng thời gian chờ nguồn dữ liệu:

```powershell
$env:OVERPASS_QUERY_TIMEOUT_SECONDS = "25"
$env:OVERPASS_TIMEOUT_MS = "30000"
$env:OSM_API_TIMEOUT_MS = "60000"
```

Nếu chưa cấu hình proxy, ứng dụng có thể gọi nguồn bản đồ trực tiếp và gặp
lỗi CORS trên trình duyệt.

## Định hướng mở rộng: Điểm vui chơi

### Vai trò Địa điểm (người đăng)

Đối tượng gồm quán cà phê, rạp phim, khu vui chơi và các địa điểm tương tự.

- Tạo trang địa điểm gồm ảnh, mô tả, giờ hoạt động và giá vé/giá dịch vụ nếu có.
- Cập nhật sự kiện hoặc ưu đãi theo dịp như Giáng sinh, khai giảng.
- Trả lời đánh giá của người dùng.

### Vai trò Sinh viên tìm chỗ chơi (người tìm kiếm)

- Lọc theo loại hình: cà phê, rạp phim, công viên, khu giải trí, quán nhậu.
- Lọc theo dịp và nhu cầu: học nhóm, hẹn hò, đi nhóm bạn, giá rẻ.
- Xem đánh giá và ảnh thực tế từ người đã đến.
- Lưu địa điểm yêu thích để tham khảo hoặc rủ bạn bè đi sau.

## Dữ liệu và quyền riêng tư

- Danh sách địa điểm công khai được đọc từ Firestore. Chỉ tài khoản có document tương ứng trong `/admins/{uid}` mới được ghi địa điểm; tài khoản người dùng chỉ đọc/ghi danh sách yêu thích của chính mình.
- Bản nháp do quản trị viên tạo được lưu cục bộ với khóa riêng `admin_place_drafts_v1`. Dữ liệu cũ `places_v1` không bị xóa, chuyển đổi hoặc tải lên tự động.
- Tạo tài khoản/đăng nhập dùng Firebase Authentication email/mật khẩu. Quyền quản trị không dựa trên email hard-code trong app: cần tạo tài khoản trong Authentication, sau đó thêm document `/admins/{uid}` từ Firebase Console. Firestore Rules chặn client tự cấp quyền admin.
- Quy tắc bảo vệ dữ liệu nằm trong `firestore.rules`, được tham chiếu ở cấp gốc `firebase.json`. Trước khi dùng cần bật Firestore API, tạo database ở `asia-southeast1` và bật nhà cung cấp Email/Password trong Firebase Authentication của project.
- Firebase Core, Authentication và Firestore đọc cấu hình build từ
  `dulieucanhan.env`; file này được bỏ qua bởi Git. Người fork cần tạo file
  riêng từ `dulieucanhan.env.example` và điền cấu hình Firebase của họ.
- App gọi mạng tới OpenStreetMap HOT (ô bản đồ, tìm địa chỉ qua Nominatim và
  tra cứu địa điểm qua proxy local), Esri (ô ảnh vệ tinh khi bạn chọn lớp
  vệ tinh) và Firebase (xác thực, địa điểm, danh sách yêu thích).
- Firebase client config/API key được đóng gói vào ứng dụng khi build để kết
  nối Firebase; đây không phải bí mật và không thể ẩn khỏi người dùng web.
  Quyền truy cập phải được bảo vệ bằng Firebase Rules và giới hạn API key.
  Tuyệt đối không đưa service-account JSON, private key hoặc thông tin
  Firebase Admin vào file cấu hình phía client hay repository.
- GitHub Actions cần secrets `DULIEUCANHAN_ENV` (JSON cấu hình ứng dụng) và
  `FIREBASE_SERVICE_ACCOUNT` (service account của dự án riêng). Lưu chúng trong
  GitHub Actions Secrets, không trong mã nguồn. Để thiết lập lại liên kết
  repository: chạy `firebase init hosting:github` và làm theo hướng dẫn.
- GitHub Actions cần secret `DULIEUCANHAN_ENV` chứa toàn bộ JSON cấu hình trong
  `dulieucanhan.env`; các workflow dùng nó để build Hosting và không deploy
  Functions.
- Chạy web mỗi lần ở một cổng khác (`localhost:xxxx`) sẽ có kho dữ liệu riêng. Muốn giữ dữ liệu giữa các lần chạy, đặt cổng cố định: `flutter run -d edge --web-port 5000` hoặc `flutter run -d web-server --web-port 5000`.
- Xóa dữ liệu: xóa dữ liệu của app, hoặc xóa dữ liệu trang trong trình duyệt.
- Bộ lọc khoảng cách chạy trên máy, phù hợp vài nghìn địa điểm.

## Nhật ký chỉnh sửa

Mỗi thư mục có thay đổi ghi một dòng trong `README.md` của thư mục đó theo giờ
Việt Nam (`UTC+7`, `YYYY-MM-DD HH:mm`). Giữ tối đa 10 mục lịch sử; khi thêm
mục thứ 11, xóa mục cũ nhất. Mỗi mục ghi ngắn gọn thời gian và nội dung đổi.
Quy tắc này áp dụng cho mọi file Markdown có mục nhật ký: chỉ giữ 10 lần chỉnh
sửa gần nhất, xếp theo thời gian tăng dần và xóa mục cũ nhất khi vượt giới hạn.
Các tài liệu báo cáo, thông báo và tiến độ phải phản ánh trạng thái hiện hành,
bao gồm việc đã hoàn thành, việc đang chờ và hướng làm tiếp theo; không chỉ lưu
lịch sử thay đổi.

- 2026-11-03 08:12 (UTC+7): Thiết lập nhật ký thay đổi theo thư mục và định dạng thời gian UTC+7.
- 2026-11-03 08:28 (UTC+7): Chuẩn hóa nhật ký Markdown còn tối đa 10 lần chỉnh sửa; quy định tài liệu tiến độ/báo cáo lưu trạng thái hiện hành.
- 2026-11-03 09:43 (UTC+7): Sửa bộ lọc tìm quanh đây để có thể kết hợp nhiều danh mục cùng lúc.
- 2026-11-03 12:59 (UTC+7): Chuyển API production từ localhost sang Firebase Functions và rewrite `/api/**` qua Hosting.
- 2026-11-04 16:04 (UTC+7): Tách cấu hình Firebase/API vào env cá nhân; tắt tải bản đồ offline trên Firebase Hosting.
