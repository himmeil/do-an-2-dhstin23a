# Địa điểm quanh đây

App Flutter chỉ làm một việc: **tìm địa điểm xung quanh vị trí người dùng chọn**.

- Tiến độ chức năng: [tiendothuchien.md](tiendothuchien.md).
- Dùng GPS theo lựa chọn của người dùng hoặc chọn vị trí thủ công; liệt kê địa điểm gần nhất trước và hiện khoảng cách.
- Lọc theo loại (quán ăn, cà phê, nhà trọ, vui chơi, mua sắm, khác), bán kính (1 / 2 / 5 / 10 km / tất cả) và từ khóa (tìm không dấu được). Bộ lọc loại và bán kính chỉ mở khi bấm **Lọc** cạnh ô tìm kiếm.
- GPS không tự bật khi mở app. Người dùng có thể bấm thanh vị trí ở đầu màn để nhập địa chỉ (chỉ tìm trong TP. Cao Lãnh, dùng Nominatim/OpenStreetMap) hoặc chọn một địa điểm đã nạp làm điểm xuất phát mà không cần cấp quyền vị trí; nút GPS trên thanh công cụ chỉ lấy vị trí khi người dùng chủ động chọn.
- Xem dạng danh sách hoặc bản đồ; dùng nút góc trên bên phải để chuyển giữa bản đồ đường phố OpenStreetMap và ảnh vệ tinh Esri. Trang chi tiết cũng có nút chuyển lớp bản đồ và nút **Chỉ đường** (mở Google Maps).
- Trên bản đồ có thể xem ranh giới phường Cao Lãnh (dữ liệu OpenStreetMap).
- Lần đầu chưa có dữ liệu: app mời **Nạp dữ liệu**. Màn nạp có 3 cách: dán CSV/JSON (hoặc copy từ Excel/Google Sheets), thêm tay từng điểm, hoặc tạo dữ liệu mẫu quanh bạn để thử.
- Firebase Core đã được cấu hình cho Android, iOS và Web bằng FlutterFire; cấu hình nền tảng nằm trong `lib/firebase_options.dart`. Chạy lại `flutterfire configure --project=do-an-2-b1f35 --platforms=android,ios,web` khi thêm nền tảng hoặc cấu hình Firebase.
- Bản Web được cấu hình deploy lên Firebase Hosting tại `https://do-an-2-b1f35.web.app`. GitHub Actions build và deploy tự động khi có push lên `main`; Pull Request nội bộ có thể tạo bản preview. Thiết lập hosting nằm trong `firebase.json`, workflow trong `.github/workflows/`.

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
`category` là một trong `quan_an, cafe, tro, vui_choi, mua_sam, khac` hoặc tên tiếng Việt ("Cà phê", "nhà trọ"...).
Nạp lại cùng tên + tọa độ thì ghi đè, không bị nhân đôi.

## Chạy thử trên máy (localhost)

```
flutter pub get
flutter analyze && flutter test
flutter run -d edge    # bản web, nhanh nhất để thử
# Nếu Flutter không mở được Chrome/Edge, dùng web-server rồi mở URL thủ công:
flutter run -d web-server --web-port 5000
flutter run               # máy thật hoặc emulator Android
```

## Dữ liệu và quyền riêng tư

- Địa điểm được **lưu ngay trên máy** (localStorage khi chạy web, SharedPreferences trên Android/iOS); hiện ứng dụng chưa đồng bộ dữ liệu lên máy chủ và chưa yêu cầu người dùng đăng nhập.
- Firebase Core được khởi tạo khi mở app, nhưng dữ liệu địa điểm hiện vẫn chỉ lưu trên máy; Firebase Authentication, Firestore và Storage chưa được tích hợp.
- App gọi mạng tới OpenStreetMap (ô bản đồ đường phố và tìm địa chỉ qua Nominatim) và Esri (ô ảnh vệ tinh khi bạn chọn lớp vệ tinh); Firebase SDK đã sẵn sàng để dùng khi tích hợp các dịch vụ Firebase.
- `firebase_options.dart` và `google-services.json` là cấu hình client dùng để kết nối Firebase, không phải khóa bí mật. Không đưa service-account JSON, private key hoặc thông tin Firebase Admin vào ứng dụng hay repository.
- Workflow GitHub dùng secret `FIREBASE_SERVICE_ACCOUNT_DO_AN_2_B1F35`; secret được lưu trong GitHub Actions Secrets, không lưu trong mã nguồn. Để thiết lập lại liên kết repository: chạy `firebase init hosting:github` và làm theo hướng dẫn đăng nhập GitHub.
- Chạy web mỗi lần ở một cổng khác (`localhost:xxxx`) sẽ có kho dữ liệu riêng. Muốn giữ dữ liệu giữa các lần chạy, đặt cổng cố định: `flutter run -d edge --web-port 5000` hoặc `flutter run -d web-server --web-port 5000`.
- Xóa dữ liệu: xóa dữ liệu của app, hoặc xóa dữ liệu trang trong trình duyệt.
- Bộ lọc khoảng cách chạy trên máy, phù hợp vài nghìn địa điểm.
