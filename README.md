# Địa điểm quanh đây

App Flutter chỉ làm một việc: **tìm địa điểm xung quanh vị trí người dùng chọn**.

- Tiến độ chức năng: [tiendothuchien.md](tiendothuchien.md).
- Dùng GPS theo lựa chọn của người dùng hoặc chọn vị trí thủ công; liệt kê địa điểm gần nhất trước và hiện khoảng cách.
- Mặc định mở bản đồ quanh tâm Phường Cao Lãnh với ranh giới phường, bán kính 5 km và các ghim quán cà phê/trường học tìm được; có thể đổi 1/5/10 km hoặc chọn tâm khác bằng cách nhấn giữ trên bản đồ.
- Bộ tìm kiếm có thể thu gọn bằng nút kính lúp trên thanh công cụ để dành thêm diện tích cho bản đồ. Trạng thái lỗi và rỗng được hiển thị gọn phía trên bản đồ, không chồng lên vùng thao tác.
- Trong công cụ quản trị, lớp “Đơn giản hóa nước ngoài” mặc định bật khi vào bằng tài khoản quản trị; các quốc gia ngoài Việt Nam được tô xám/trắng và gắn nhãn tên nước thay vì hiện chi tiết đường phố. Có thể tắt lớp ngay trong menu quản trị. Ranh giới tham khảo lấy từ Natural Earth 1:110m; Việt Nam giữ lớp bản đồ chi tiết.
- Bản đồ tìm kiếm có inset định vị Hoàng Sa và Trường Sa trên nền OpenStreetMap; có thể ẩn/hiện inset. Inset dùng ghim vị trí tham khảo, không vẽ đường biên hay ranh giới chủ quyền.
- Lọc theo loại (quán ăn, cà phê, trường học, nhà trọ, vui chơi, mua sắm, khác), bán kính (1 / 5 / 10 km / tất cả) và từ khóa (tìm không dấu được). Bộ lọc loại và bán kính chỉ mở khi bấm **Lọc** cạnh ô tìm kiếm.
- GPS không tự bật khi mở app. Người dùng có thể giữ trên bản đồ để chọn một điểm làm tâm tìm kiếm, không cần cấp quyền vị trí; cũng có thể bấm thanh vị trí để nhập địa chỉ (Nominatim/OpenStreetMap) hoặc chọn địa điểm đã nạp. Nút GPS chỉ lấy vị trí khi người dùng chủ động chọn.
- App tự tra cứu quán cà phê và trường học có tên quanh tâm bản đồ trong bán kính 1/5/10 km từ dữ liệu OpenStreetMap (Overpass API); kết quả chỉ hiển thị tạm, không ghi vào Firestore. Lựa chọn “Tất cả” gồm địa điểm đã lưu và dữ liệu bản đồ trong tối đa 10 km. Độ đầy đủ tùy dữ liệu OpenStreetMap từng khu vực. Đây không phải Google Places; muốn dữ liệu Google Maps Places cần cấu hình API key, bật Places API và thanh toán theo chính sách Google.
- **Giới hạn hiện tại trên web:** một số máy chủ Overpass không cho trình duyệt gọi trực tiếp do chính sách CORS hoặc tình trạng quá tải. Khi xảy ra, app hiện lỗi ngắn kèm nút thử lại, không hiện nội dung exception và không nhầm lỗi thành kết quả rỗng. Muốn tra cứu tự động ổn định trên Hosting cần proxy phía máy chủ; cấu hình Firebase Functions/Cloud Run chưa được triển khai.
- Xem dạng danh sách hoặc bản đồ; dùng nút góc trên bên phải để chuyển giữa bản đồ đường phố OpenStreetMap và ảnh vệ tinh Esri. Trang chi tiết cũng có nút chuyển lớp bản đồ và nút **Chỉ đường** (mở Google Maps).
- Trên bản đồ có thể xem ranh giới phường Cao Lãnh (dữ liệu OpenStreetMap).
- Quản trị viên có thể bật chế độ giản lược các nước ngoài Việt Nam; lớp này vẫn hiển thị trên cả bản đồ đường phố và ảnh vệ tinh. Ranh giới quốc gia lấy từ Natural Earth, dữ liệu public domain: [Natural Earth 1:110m Admin 0 Countries](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/).
- Khách có thể vào xem danh sách, chi tiết và bản đồ đường phố không cần tài khoản. Đăng nhập bằng email/mật khẩu để tìm kiếm/lọc, tra vị trí thủ công, xem ảnh vệ tinh và lưu địa điểm yêu thích; quản trị viên có thể tạo bản nháp trên thiết bị, xem lại rồi xác nhận đăng lên Firestore.
- Màn tạo bản nháp có 3 cách: dán CSV/JSON (hoặc copy từ Excel/Google Sheets), thêm tay từng điểm, hoặc tạo dữ liệu mẫu quanh bạn để thử. Dữ liệu cũ trong bộ nhớ trên thiết bị được giữ nguyên và không tự tải lên.
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
`category` là một trong `quan_an, cafe, truong_hoc, tro, vui_choi, mua_sam, khac` hoặc tên tiếng Việt ("Cà phê", "trường học", "nhà trọ"...).
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

- Danh sách địa điểm công khai được đọc từ Firestore. Chỉ tài khoản có document tương ứng trong `/admins/{uid}` mới được ghi địa điểm; tài khoản người dùng chỉ đọc/ghi danh sách yêu thích của chính mình.
- Bản nháp do quản trị viên tạo được lưu cục bộ với khóa riêng `admin_place_drafts_v1`. Dữ liệu cũ `places_v1` không bị xóa, chuyển đổi hoặc tải lên tự động.
- Tạo tài khoản/đăng nhập dùng Firebase Authentication email/mật khẩu. Quyền quản trị không dựa trên email hard-code trong app: cần tạo tài khoản trong Authentication, sau đó thêm document `/admins/{uid}` từ Firebase Console. Firestore Rules chặn client tự cấp quyền admin.
- Quy tắc bảo vệ dữ liệu nằm trong `firestore.rules`, được tham chiếu ở cấp gốc `firebase.json`. Trước khi dùng cần bật Firestore API, tạo database ở `asia-southeast1` và bật nhà cung cấp Email/Password trong Firebase Authentication của project.
- Firebase Core, Authentication và Firestore được cấu hình cho Android, iOS và Web bằng FlutterFire; cấu hình nền tảng nằm trong `lib/firebase_options.dart`.
- App gọi mạng tới OpenStreetMap (ô bản đồ, tìm địa chỉ qua Nominatim và tra cứu quán/trường qua Overpass), Esri (ô ảnh vệ tinh khi bạn chọn lớp vệ tinh) và Firebase (xác thực, địa điểm, danh sách yêu thích).
- `firebase_options.dart` và `google-services.json` là cấu hình client dùng để kết nối Firebase, không phải khóa bí mật. Không đưa service-account JSON, private key hoặc thông tin Firebase Admin vào ứng dụng hay repository.
- Workflow GitHub dùng secret `FIREBASE_SERVICE_ACCOUNT_DO_AN_2_B1F35`; secret được lưu trong GitHub Actions Secrets, không lưu trong mã nguồn. Để thiết lập lại liên kết repository: chạy `firebase init hosting:github` và làm theo hướng dẫn đăng nhập GitHub.
- Chạy web mỗi lần ở một cổng khác (`localhost:xxxx`) sẽ có kho dữ liệu riêng. Muốn giữ dữ liệu giữa các lần chạy, đặt cổng cố định: `flutter run -d edge --web-port 5000` hoặc `flutter run -d web-server --web-port 5000`.
- Xóa dữ liệu: xóa dữ liệu của app, hoặc xóa dữ liệu trang trong trình duyệt.
- Bộ lọc khoảng cách chạy trên máy, phù hợp vài nghìn địa điểm.
