# Nearby places API

API phục vụ Flutter Web local. Firebase Hosting dùng snapshot OSM được đóng
gói trong Flutter asset, không gọi API này hay Firebase Functions. Proxy local
nhận vị trí từ Flutter, đọc dữ liệu SQLite để tránh lỗi CORS, rồi trả về các
phần tử có tên.
Proxy truy vấn các đối tượng có tên trong khu vực Cao Lãnh và thử nhiều máy
chủ Overpass nếu một máy chủ bị quá tải. Nếu tất cả Overpass không kết nối
được, proxy tự chuyển sang cơ sở dữ liệu SQLite tại `data/places.sqlite`, là cơ sở dữ liệu dự phòng của khu
vực Cao Lãnh. Cơ sở dữ liệu không còn chứa các tọa độ mẫu từ CSV; chỉ các bản ghi
Overpass nhận thành công mới được lưu. Mỗi truy vấn Overpass được cấp tối đa
25 giây xử lý và proxy chờ thêm 5 giây để nhận phản hồi, tránh tự hủy request
trước khi Overpass hoàn tất.

- quán cà phê, nhà hàng, quán ăn nhanh, quán bar, rạp phim;
- công viên, sân chơi, khu vui chơi, công viên nước, trung tâm thể thao;
- cửa hàng;
- bảo tàng, điểm tham quan, sở thú và công viên chủ đề;
- trường học, cao đẳng và đại học;
- nhà khách, nhà nghỉ, khách sạn, nhà trọ, ký túc xá và các điểm lưu trú;
- bến xe và các điểm dừng xe buýt có tên trong OpenStreetMap.

Bộ điều khiển Zoom và lớp ảnh vệ tinh thuộc Flutter Web, không chạy qua proxy
backend. Proxy chỉ cung cấp dữ liệu địa điểm; tile bản đồ được trình duyệt tải
trực tiếp từ OpenStreetMap HOT hoặc Esri.

## Chạy local

Cần Node.js 22.5 trở lên vì backend sử dụng `node:sqlite`:

```powershell
cd backend
npm start
```

Kiểm tra proxy:

```text
http://localhost:8787/health
```

Sau đó chạy Flutter Web:

```powershell
flutter run -d web-server --web-port 5000 --dart-define-from-file=ca_nhan/dulieucanhan.env
```

Backend tại `http://localhost:8787` phải đang chạy để tìm địa điểm gần đây;
nếu chỉ mở Flutter Web mà thiếu backend, dữ liệu SQL sẽ không được truy vấn.
`run_web.bat` tự kiểm tra và khởi động backend trước khi build; `bat_app.bat`
cũng khởi động backend rồi mới mở web. Nếu cổng `5000` đã có web đang chạy,
sau khi backend khởi động hãy tải lại trang bằng `F5`.

Mở `http://localhost:5000` bằng Edge/Chrome. Với demo ổn định, có thể build
trước rồi chạy static server:

```powershell
flutter build web --dart-define-from-file=ca_nhan/dulieucanhan.env
python -m http.server 5000 --directory build\web --bind 127.0.0.1
```

Static server này chỉ phục vụ giao diện, không tự khởi động proxy Node.js. Nếu
dùng cách chạy trên, mở một terminal khác và chạy backend trước:

```powershell
cd backend
npm start
```

Sau khi `http://localhost:8787/health` trả về `ok: true`, tải lại trang
`http://localhost:5000`. Nếu backend không chạy và chưa tải dữ liệu offline,
ứng dụng sẽ hiện hướng dẫn khởi động; cache JSON cũ (nếu có) chỉ làm fallback.

Chế độ `web-server` phù hợp khi cần hot reload nhưng có thể mất thời gian chờ
debug service ở lần chạy đầu.
Nếu cổng `5000` đã được sử dụng, chạy `tat_app.bat` ở thư mục gốc rồi chạy
lại. Cách đơn giản nhất là chạy `bat_app.bat`.

Flutter Web mặc định gọi `http://localhost:8787/api/nearby`. Có thể đổi địa chỉ
proxy trong `ca_nhan/dulieucanhan.env` bằng cách sửa `NEARBY_API_BASE_URL`.
Mỗi lần build, truyền file đó để Flutter nạp cả proxy, URL dịch vụ và cấu
hình Firebase:

```powershell
flutter run -d edge --dart-define-from-file=ca_nhan/dulieucanhan.env
```

Android không dùng proxy local; Android tiếp tục gọi nguồn bản đồ trực tiếp.

## Firebase Hosting

Ứng dụng build cho Firebase không gọi `localhost` và không tải snapshot bản đồ
offline. Firebase Hosting rewrite `/api/**` chỉ có tác dụng khi Function
`nearbyApi` được triển khai. Project dùng Firebase Spark nên không deploy
Functions; tra cứu OSM trên Hosting đọc snapshot `assets/data/osm_places.json`
đã đóng gói khi build. Các API quản trị và SQLite vẫn chỉ có trên backend local.

GitHub Actions deploy Hosting khi push lên `main`; workflow hiện không deploy
Functions. Khi admin cập nhật/chọn snapshot ở backend local, backend đồng bộ
asset Flutter. Commit asset đó rồi push lên `main` để Hosting nhận dữ liệu mới;
không tự gọi Overpass trong CI.

## Nhật ký chỉnh sửa

- 2026-11-03 15:05 (UTC+7): Từ chối JSON lỗi ở `/api/nearby` bằng HTTP 400 và giữ đúng bán kính khi dùng dữ liệu dự phòng.
- 2026-11-03 15:29 (UTC+7): Chuẩn hóa mã danh mục OSM cũ khi mở SQLite và bổ sung thẻ địa điểm thể thao vào truy vấn bản đồ.
- 2026-11-03 12:59 (UTC+7): Triển khai API production bằng Firebase Functions, seed SQLite từ SQL kèm theo và giữ endpoint quản trị chỉ chạy local.

Ứng dụng không còn tải bản sao dữ liệu địa điểm để dùng offline; endpoint
`/api/offline-places` đã bị gỡ. Cache JSON cũ trên thiết bị vẫn có thể được
đọc làm fallback khi proxy lỗi, nhưng không có chức năng tạo cache mới. Tile
nền bản đồ OpenStreetMap vẫn cần kết nối mạng trên Web nếu trình duyệt chưa cache tile.
Trên native, `flutter_map` cache tile theo header máy chủ tile trong thư mục
cache của thiết bị, giới hạn tối đa 128 MiB; cache có thể bị hệ điều hành xóa.
Không prefetch tile bằng HTTP client riêng vì tile đó không đi qua cache provider
của bản đồ.
Các widget bản đồ giải phóng `MapController` khi bị dispose; mỗi tile layer
cũng sở hữu provider riêng để đóng HTTP client đúng vòng đời.

## Cơ sở dữ liệu dự phòng

SQLite dùng bảng `places` với các cột:

```text
id,name,category,latitude,longitude,address,phone,hours,source,updated_at
```

Mỗi lần Admin cập nhật Overpass thành công, proxy thay tập bản ghi `overpass` trong
SQLite bằng kết quả mới, tránh trộn dữ liệu cũ với dữ liệu hiện tại.
Các bản ghi cũ có `source = local-seed` sẽ bị xóa khi proxy khởi động để tránh
hiển thị lại tọa độ mẫu không chính xác.
Schema `data/binhluan.sql` tạo bảng `comments` và chỉ mục theo địa điểm/ngày.
`GET /api/places/{placeId}/comments` cho phép đọc công khai; POST yêu cầu
Firebase ID token hợp lệ, lấy `user_id`/tên tài khoản từ token và giới hạn
nội dung 1–1000 ký tự. Dữ liệu bình luận local nằm trong cùng SQLite database.

Các API quản trị yêu cầu Firebase ID token và tài khoản phải có document
`admins/{uid}` trong Firestore. Admin có thể gọi `POST /api/admin/update-map`
để tải lại toàn bộ dữ liệu Cao Lãnh. Backend ưu tiên Overpass, chia khu vực thành các ô bán kính 1 km, tải
tối đa 3 ô song song, rồi gộp và loại trùng theo `type/id`. Mỗi ô cũng thử
các máy chủ Overpass đồng thời và dùng phản hồi thành công đầu tiên. Khi cập nhật thành
công, `dia_diem_cao_lanh.json` trở thành bản mới
và bản cũ được đổi tên thành `backup_dia_diem_cao_lanh.json`. Nếu Overpass lỗi,
hai file không bị thay đổi.

Trong menu Công cụ quản trị của ứng dụng, mục **Chọn dữ liệu bản đồ Cao Lãnh**
gọi `GET /api/admin/map-sources` để hiển thị các snapshot hiện có, gồm bản mới
`dia_diem_cao_lanh.json` và bản cũ `backup_dia_diem_cao_lanh.json` (nếu tồn tại),
kèm số địa điểm, ngày cập nhật và trạng thái đang dùng. Sau khi xác nhận,
`POST /api/admin/select-map` áp dụng snapshot đã chọn vào SQLite. Lựa chọn đang
dùng được lưu tại `data/active_map_source.json` và tự nạp lại khi backend khởi
động; thao tác chọn không ghi đè hai file snapshot. Cập nhật dữ liệu Overpass
mới sẽ tạo bản mới, lưu bản hiện tại thành backup và chuyển lựa chọn đang dùng
sang bản mới.

Các file snapshot này nằm trong `backend/data` và được tạo sau lần cập nhật
bản đồ thành công từ Overpass hoặc OpenStreetMap API; các file JSON runtime có
thể bị Git ignore. Riêng `assets/data/osm_places.json` là bản triển khai được
commit để Hosting Spark có dữ liệu mà không cần Functions. Backend đồng bộ
asset này mỗi khi cập nhật/chọn snapshot local; commit thay đổi asset để phát
hành dữ liệu mới.
Mỗi lần cập nhật thành công, backend cũng tạo
`data/dia_diem_cao_lanh.sql` chứa schema dữ liệu và các lệnh `INSERT` để có
thể khôi phục/chuyển toàn bộ địa điểm sang SQLite khác. File SQL cũ được lưu
thành `backup_dia_diem_cao_lanh.sql`.
Khi proxy khởi động, proxy nạp `dia_diem_cao_lanh.json` vào SQLite. Endpoint
`POST /api/nearby` chỉ truy vấn SQLite theo tọa độ và bán kính, không gọi
Overpass trực tiếp. SQLite dùng index `(latitude, longitude)` để thu hẹp tập
ứng viên theo bounding box; backend tiếp tục lọc chính xác bằng khoảng cách
Haversine trước khi trả kết quả. Vì vậy thanh tìm kiếm không bị treo khi
Overpass timeout, và truy vấn không phải quét toàn bảng khi dữ liệu tăng.
Mã danh mục OSM cũ như `museum`, `pitch`, `sports_centre` được migrate một lần
sang mã ứng dụng (`vui_choi`); registry danh mục dùng chung của Flutter cũng
chuẩn hóa dữ liệu offline, Firestore và bộ lọc khi gặp các mã OSM cũ.

Nếu toàn bộ máy chủ Overpass lỗi hoặc timeout, backend tự chuyển sang
OpenStreetMap API chính thức (`api.openstreetmap.org`), chia toàn bộ bbox Cao
Lãnh thành các ô nhỏ. Backend chỉ giữ đối tượng có tên không phải đoạn đường
thuần (`highway=*`); vẫn giữ trạm xe buýt và đối tượng có thẻ POI. Mã OSM chưa
có quy tắc vẫn vào **Khác**, không tự suy diễn thành vui chơi. Cách này tránh
đưa hàng loạt tên đường vào danh sách địa điểm mà không loại bỏ POI chưa biết.
Có thể chỉnh thời gian chờ nguồn này
bằng `OSM_API_TIMEOUT_MS` (mặc định 60.000 mili giây).

Có thể điều chỉnh khi máy chủ Overpass chậm bằng biến môi trường
`OVERPASS_QUERY_TIMEOUT_SECONDS` và `OVERPASS_TIMEOUT_MS`. Mặc định là `25`
giây xử lý và `30.000` mili giây chờ phản hồi.

## Quy trình chạy và cập nhật đầy đủ

Mở PowerShell tại thư mục dự án:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh
flutter pub get
flutter analyze
flutter test
```

Mở PowerShell thứ hai để chạy backend:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh\backend
npm.cmd start
```

Mở PowerShell thứ ba để chạy app web:

```powershell
cd C:\Users\Admin\Desktop\Do_AN_2\app-tim-dia-diem-xung-quanh
flutter run -d edge --web-port 5000 --dart-define-from-file=ca_nhan/dulieucanhan.env
```

Hoặc chạy `bat_app.bat` ở thư mục gốc để tự mở backend và Flutter Web.
Khi kết thúc, chạy `tat_app.bat` để dừng các tiến trình đang dùng cổng `8787`
và `5000`, đồng thời đóng hai cửa sổ CMD.

Trong cửa sổ Backend hoặc Flutter Web:

- Bấm `R` để reload/restart tiến trình tương ứng.
- Bấm `Q` để đóng cửa sổ đó.
- `run_web.bat` build Flutter Web rồi phục vụ thư mục `build\web` bằng Python
  tại `http://localhost:5000`; khi thấy dòng “Dang phuc vu build\web” là đã
  chạy thành công.

Kiểm tra backend:

```powershell
Invoke-RestMethod http://localhost:8787/health
```

Tải lại toàn bộ dữ liệu Cao Lãnh:

```powershell
Invoke-RestMethod `
  -Uri http://localhost:8787/api/admin/update-map `
  -Method Post `
  -Headers @{Authorization = "Bearer <Firebase ID token>"} `
  -TimeoutSec 300
```

Mỗi lần cập nhật thành công, dữ liệu được ghi đồng thời vào SQLite, JSON và
SQL. Nếu nguồn mạng thất bại, bản hiện tại và các file backup không bị xóa.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Ghi nhận chuẩn hóa danh mục SQL/OSM và bổ sung khởi động backend tự động khi chạy Flutter Web.
- 2026-11-03 08:36 (UTC+7): Nêu rõ static server không tự bật proxy; bổ sung hướng chạy backend và tải lại trang.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký backend.
