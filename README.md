# Địa điểm quanh đây

App Flutter chỉ làm một việc: **tìm địa điểm xung quanh vị trí người dùng chọn**.

- Tiến độ chức năng: [tiendothuchien.md](tiendothuchien.md).
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
- Lọc theo loại (quán ăn, cà phê, trường học, nhà trọ, vui chơi, mua sắm, khác), bán kính (1 / 5 / 10 km / tất cả) và từ khóa (tìm không dấu được). Bộ lọc loại và bán kính chỉ mở khi bấm **Lọc** cạnh ô tìm kiếm.
- GPS không tự bật khi mở app. Người dùng có thể giữ trên bản đồ để chọn một điểm làm tâm tìm kiếm, không cần cấp quyền vị trí; cũng có thể bấm thanh vị trí để nhập địa chỉ (Nominatim/OpenStreetMap) hoặc chọn địa điểm đã nạp. Nút GPS chỉ lấy vị trí khi người dùng chủ động chọn.
- App truy vấn SQLite local theo bán kính 1/5/10 km. Admin cập nhật dữ liệu từ Overpass; nếu Overpass timeout, backend tự dùng OpenStreetMap API, lưu dữ liệu Cao Lãnh vào SQLite. Lựa chọn “Tất cả” gồm địa điểm đã lưu và dữ liệu bản đồ local.
- **Web local:** Flutter Web mặc định gọi proxy trong thư mục `backend/`, vì vậy trình duyệt không gọi Overpass trực tiếp và tránh lỗi CORS. Khi chạy trên Hosting, cần triển khai proxy tương đương bằng Firebase Functions hoặc Cloud Run.
- **Chế độ offline:** danh sách địa điểm Cao Lãnh được đóng gói trong
  bộ nhớ cục bộ sau khi người dùng bấm tải trong menu tài khoản. Khi Overpass
  hoặc proxy không phản hồi, Flutter đọc dữ liệu đã tải, lọc theo bán kính và
  vẫn hiển thị danh sách/ghim địa điểm.
  Dữ liệu nền bản đồ OpenStreetMap vẫn cần mạng nếu tile chưa được tải trước.
- **Mô hình chạy demo local:** Flutter Web chạy trên trình duyệt, còn server
  local làm lớp trung gian gọi Overpass và trả dữ liệu cửa hàng, quán cà phê,
  rạp phim, công viên và khu vui chơi về cho ứng dụng. Khi triển khai chính
  thức, server local có thể thay bằng Firebase Functions hoặc Cloud Run.
- Xem dạng danh sách hoặc bản đồ; dùng nút góc trên bên phải để chuyển giữa bản đồ đường phố OpenStreetMap và ảnh vệ tinh Esri. Trang chi tiết cũng có nút chuyển lớp bản đồ và nút **Chỉ đường** (mở Google Maps).
- Trên bản đồ có thể xem ranh giới phường Cao Lãnh (dữ liệu OpenStreetMap).
- Khách có thể vào xem danh sách, chi tiết và bản đồ đường phố không cần tài khoản. Đăng nhập bằng email/mật khẩu để tìm kiếm/lọc, tra vị trí thủ công, xem ảnh vệ tinh và lưu địa điểm yêu thích; quản trị viên có thể tạo bản nháp trên thiết bị, xem lại rồi xác nhận đăng lên Firestore.
- Màn tạo bản nháp có 3 cách: dán CSV/JSON (hoặc copy từ Excel/Google Sheets), thêm tay từng điểm, hoặc tạo dữ liệu mẫu quanh bạn để thử. Dữ liệu cũ trong bộ nhớ trên thiết bị được giữ nguyên và không tự tải lên.
- Firebase Core đã được cấu hình cho Android, iOS và Web bằng FlutterFire; cấu hình nền tảng nằm trong `lib/firebase_options.dart`. Chạy lại `flutterfire configure --project=do-an-2-b1f35 --platforms=android,ios,web` khi thêm nền tảng hoặc cấu hình Firebase.
- Bản Web được cấu hình deploy lên Firebase Hosting tại `https://do-an-2-b1f35.web.app`. GitHub Actions build và deploy tự động khi có push lên `main`; Pull Request nội bộ có thể tạo bản preview. Thiết lập hosting nằm trong `firebase.json`, workflow trong `.github/workflows/`.
- Dữ liệu bản đồ Cao Lãnh đã được nạp lên Firestore project `do-an-2-b1f35`,
  collection `places` (1.018 địa điểm). Hosting và Firestore là hai phần
  riêng: deploy web không tự nạp SQLite local lên cloud.

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

Nên chạy `tat_app.bat` khi kết thúc demo để giải phóng hai cổng này.
Trong cửa sổ Backend và Flutter Web, bấm `R` để reload tương ứng; bấm `Q` để
đóng từng cửa sổ. `tat_app.bat` sẽ đóng cả hai cửa sổ và các tiến trình con.
`run_web.bat` là script build Flutter Web rồi chạy web server tĩnh bằng Python;
thông báo `Dang phuc vu build\web` nghĩa là app đã chạy, không phải bị treo.

Sau đó chạy Flutter Web:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh
flutter build web --no-pub
python -m http.server 5000 --directory build\web --bind 127.0.0.1
# Mở http://localhost:5000 bằng trình duyệt
# Chế độ debug nếu cần hot reload:
flutter run -d web-server --web-port 5000
flutter run               # máy thật hoặc emulator Android
```

Nếu báo lỗi cổng `5000` đã được sử dụng, chạy `tat_app.bat` trước rồi chạy
lại. Cách đơn giản hơn là chỉ chạy `bat_app.bat`; file này tự build và mở web
server đúng cấu hình.

Khi dùng server local cho dữ liệu bản đồ, khởi động server trước rồi chạy
Flutter Web. Proxy mặc định ở `http://localhost:8787`.

### Deploy web và Firestore

Sau khi cập nhật giao diện hoặc Rules, chạy:

```powershell
firebase.cmd deploy --only hosting,firestore:rules --project do-an-2-b1f35
```

Kiểm tra nhanh dữ liệu cloud:

```powershell
Invoke-RestMethod `
  -Uri "https://firestore.googleapis.com/v1/projects/do-an-2-b1f35/databases/(default)/documents/places?pageSize=1"
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
- Firebase Core, Authentication và Firestore được cấu hình cho Android, iOS và Web bằng FlutterFire; cấu hình nền tảng nằm trong `lib/firebase_options.dart`.
- App gọi mạng tới OpenStreetMap (ô bản đồ, tìm địa chỉ qua Nominatim và
  tra cứu địa điểm qua proxy local), Esri (ô ảnh vệ tinh khi bạn chọn lớp
  vệ tinh) và Firebase (xác thực, địa điểm, danh sách yêu thích).
- `firebase_options.dart` và `google-services.json` là cấu hình client dùng để kết nối Firebase, không phải khóa bí mật. Không đưa service-account JSON, private key hoặc thông tin Firebase Admin vào ứng dụng hay repository.
- Workflow GitHub dùng secret `FIREBASE_SERVICE_ACCOUNT_DO_AN_2_B1F35`; secret được lưu trong GitHub Actions Secrets, không lưu trong mã nguồn. Để thiết lập lại liên kết repository: chạy `firebase init hosting:github` và làm theo hướng dẫn đăng nhập GitHub.
- Chạy web mỗi lần ở một cổng khác (`localhost:xxxx`) sẽ có kho dữ liệu riêng. Muốn giữ dữ liệu giữa các lần chạy, đặt cổng cố định: `flutter run -d edge --web-port 5000` hoặc `flutter run -d web-server --web-port 5000`.
- Xóa dữ liệu: xóa dữ liệu của app, hoặc xóa dữ liệu trang trong trình duyệt.
- Bộ lọc khoảng cách chạy trên máy, phù hợp vài nghìn địa điểm.
