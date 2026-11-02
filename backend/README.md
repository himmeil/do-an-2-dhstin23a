# Local map proxy

Proxy này phục vụ demo Flutter Web. Nó nhận vị trí từ Flutter, gọi Overpass
server-side để tránh lỗi CORS, rồi trả về các phần tử OpenStreetMap có tên.
Proxy chỉ truy vấn đối tượng có tên để tránh tải quá lớn và thử lần lượt nhiều
máy chủ Overpass nếu một máy chủ bị quá tải. Nếu tất cả Overpass không kết nối
được, proxy tự chuyển sang cơ sở dữ liệu SQLite tại `data/places.sqlite`, là cơ sở dữ liệu dự phòng của khu
vực Cao Lãnh. Cơ sở dữ liệu không còn chứa các tọa độ mẫu từ CSV; chỉ các bản ghi
Overpass nhận thành công mới được lưu. Mỗi máy chủ upstream mặc định được chờ tối đa 4 giây để fallback không
làm treo màn hình demo quá lâu.

- quán cà phê, nhà hàng, quán ăn nhanh, quán bar, rạp phim;
- công viên, sân chơi, khu vui chơi, công viên nước, trung tâm thể thao;
- cửa hàng;
- bảo tàng, điểm tham quan, sở thú và công viên chủ đề;
- trường học, cao đẳng và đại học.

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
flutter run -d edge --web-port 5000
```

Flutter Web mặc định gọi `http://localhost:8787/api/nearby`. Có thể đổi địa chỉ
proxy khi build bằng:

```powershell
flutter run -d edge --dart-define=NEARBY_API_BASE_URL=http://localhost:8787
```

Android không dùng proxy local; Android tiếp tục gọi Overpass trực tiếp.

Ứng dụng Flutter có thể tải bản sao dữ liệu SQLite qua menu tài khoản, nên có
thể xem các địa điểm Cao Lãnh ngay cả khi không chạy proxy. Tile nền bản đồ
OpenStreetMap vẫn cần kết nối mạng nếu chưa có cơ chế cache tile riêng.

## Cơ sở dữ liệu dự phòng

SQLite dùng bảng `places` với các cột:

```text
id,name,category,latitude,longitude,address,phone,hours,source,updated_at
```

Mỗi lần Overpass trả dữ liệu thành công, proxy thay tập bản ghi `overpass` trong
SQLite bằng kết quả mới, tránh trộn dữ liệu cũ với dữ liệu hiện tại.
Các bản ghi cũ có `source = local-seed` sẽ bị xóa khi proxy khởi động để tránh
hiển thị lại tọa độ mẫu không chính xác.
Endpoint `GET /api/offline-places` trả toàn bộ dữ liệu đã lưu để người dùng
tải xuống dùng offline.
