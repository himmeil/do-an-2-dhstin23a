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
- Đã tích hợp Firebase Authentication (email/mật khẩu) và Cloud Firestore cho
  tài khoản và danh sách địa điểm; Storage chưa được tích hợp.
- Quy tắc tại `firestore.rules` cho phép đọc địa điểm công khai, chỉ admin ghi
  địa điểm và mỗi người dùng chỉ thao tác danh sách yêu thích của chính mình.
  Quyền admin được xác định qua document `/admins/{uid}` và không thể tự cấp
  từ ứng dụng.
- Admin nhập dữ liệu vào bản nháp lưu cục bộ bằng storage key riêng, kiểm tra
  rồi xác nhận đăng lên Firestore. Dữ liệu địa điểm local cũ được giữ nguyên,
  không tự động di chuyển lên cloud.
- Cần bật Firestore API, tạo database ở `asia-southeast1` và bật nhà cung cấp
  Email/Password trong Firebase Authentication trước khi chạy luồng backend
  trên project thật. Admin cần được cấp document `/admins/{uid}` từ Firebase
  Console.
- Cấu hình Firebase Hosting phục vụ bản Flutter Web tại
  `https://do-an-2-b1f35.web.app`. GitHub Actions build ứng dụng và deploy bản
  chính khi có push lên `main`, đồng thời tạo preview cho Pull Request nội bộ.
- GitHub Actions đọc service-account từ secret
  `FIREBASE_SERVICE_ACCOUNT_DO_AN_2_B1F35`; không lưu khóa service-account trong
  repository.

## Nội dung đã thay đổi

- Không tự gọi GPS khi mở màn hình tìm kiếm; GPS chỉ được gọi khi người dùng
  chọn nút **Dùng GPS** hoặc lựa chọn GPS trong bảng chọn vị trí.
- Mở ứng dụng ở chế độ bản đồ, lấy tâm và đường biên Phường Cao Lãnh làm mặc
  định thay vì tự xin quyền GPS. Có thể chuyển sang danh sách hoặc đổi vị trí
  bằng GPS/tra cứu địa chỉ; bộ lọc mặc định là 5 km, cho chọn 1 km, 5 km,
  10 km hoặc tất cả. Vòng tròn bán kính và ghim địa điểm thay đổi theo lựa chọn;
  kết quả dựa trên dữ liệu địa điểm đã có trong ứng dụng.
- Tự tra cứu quán cà phê và trường học có tên quanh tâm bản đồ bằng Overpass API
  (dữ liệu OpenStreetMap); kết quả tạm thời được gộp vào danh sách/bản đồ, không
  ghi vào Firestore. Nếu không bật GPS, người dùng có thể nhấn giữ một điểm trên
  bản đồ để làm tâm tìm kiếm. Dữ liệu tùy khu vực và có thể không đầy đủ; đây
  không phải Google Places API. Lựa chọn “Tất cả” vẫn giới hạn tra cứu tự động
  trong 10 km; dữ liệu địa điểm đã lưu vẫn được lọc theo lựa chọn này. Tìm kiếm
  được gắn attribution OpenStreetMap. Trên web local, ứng dụng gọi proxy trong
  thư mục `backend/` để tránh việc trình duyệt gọi Overpass trực tiếp và bị
  CORS. Khi triển khai Hosting, proxy này cần được chuyển sang Firebase
  Functions hoặc Cloud Run.
- Thêm nút thu gọn/mở bộ tìm kiếm khi đang ở chế độ bản đồ; mặc định thu gọn để
  dành thêm diện tích hiển thị bản đồ. Trạng thái lỗi tra cứu và trạng thái
  không có kết quả hiển thị gọn phía trên bản đồ, không che khu vực bản đồ và
  không hiển thị “không có kết quả” khi dịch vụ đang lỗi.
- Giữ banner khám phá, thanh vị trí và bộ lọc khi mở danh sách kể cả lúc chưa
  có dữ liệu; vùng danh sách hiển thị trạng thái rỗng theo bán kính/bộ lọc.
  Admin vẫn tạo bản nháp từ menu công cụ quản trị.
- Đưa nút “Lọc” cạnh ô tìm kiếm; ẩn các chip loại địa điểm và bán kính cho đến
  khi người dùng chủ động mở bộ lọc.
- Thêm inset bản đồ tham khảo Hoàng Sa, Trường Sa trên nền OpenStreetMap, đánh
  dấu vị trí gần đúng và ghi attribution; người dùng có thể ẩn/hiện inset.
  Inset không thêm đường biên hoặc khẳng định ranh giới địa lý mới.
- Chuyển nút hiện/thu gọn thanh tìm kiếm sang vùng actions cố định của AppBar
  để nút không bị khuất trong hàng công cụ cuộn ngang.
- Bổ sung tùy chọn “Đơn giản hóa nước ngoài” trong menu quản trị. Khi mở màn
  hình bằng tài khoản quản trị, chế độ này mặc định bật; các nước ngoài Việt
  Nam được tô nền xám nhạt và gắn tên nước, trong khi Việt Nam vẫn giữ nền bản
  đồ chi tiết. Lớp giản lược vẫn được duy trì khi chuyển sang ảnh vệ tinh.
  Admin có thể tắt tùy chọn để xem bản đồ không có lớp phủ này.
  Biên giới khái quát lấy từ bộ dữ liệu Natural Earth 1:110m Admin 0 Countries
  (public domain); nguồn dữ liệu được khai báo trong README.
- Thanh vị trí cho phép chọn một địa điểm đã lưu hoặc tìm địa chỉ trong TP. Cao
  Lãnh qua Nominatim/OpenStreetMap. Vị trí thủ công được dùng để tính khoảng
  cách, sắp xếp và lọc địa điểm theo bán kính như vị trí GPS.
- Bảo vệ lựa chọn thủ công khỏi bị ghi đè nếu kết quả một yêu cầu GPS đang chạy
  trả về muộn.
- Thêm đăng ký/đăng nhập email-mật khẩu, phân quyền quản trị qua Firestore,
  hiển thị danh sách địa điểm cloud và lưu/lọc địa điểm yêu thích.
- Cho phép khách xem địa điểm, chọn tâm tìm kiếm bằng cách nhấn giữ bản đồ và
  xem bản đồ đường phố; yêu cầu đăng nhập khi tìm kiếm/lọc bằng thanh công cụ,
  tra vị trí thủ công bằng địa chỉ hoặc chuyển sang ảnh vệ tinh. Có thể vào màn
  đăng nhập từ lời nhắc để tiếp tục lưu yêu thích.
- Chuyển chức năng nhập địa điểm thành bản nháp local dành riêng cho admin;
  cung cấp bước xác nhận trước khi ghi các bản nháp lên Firestore.
- Khai báo Firestore Rules trong `firebase.json`, giới hạn quyền đọc/ghi theo
  vai trò và giữ nguyên dữ liệu cũ trên thiết bị.
- Cập nhật mô tả tính năng trong `README.md` và `tiendothuchien.md`.

## Tận dụng assets cho giao diện web

> Ghi chú: các mô tả về `assets/source_game/` và `assets/character/` bên dưới
> là lịch sử xử lý tài nguyên. Hai thư mục nguồn này đã được xoá vì không được
> khai báo hoặc sử dụng trực tiếp trong ứng dụng; các asset đang dùng nằm trong
> `assets/mini_game/` và các nhóm được khai báo trong `pubspec.yaml`.

- Dùng `assets/splash/launch.jpg` làm ảnh nền màn hình khởi động và banner khám
  phá trên màn danh sách địa điểm; banner có lớp phủ tối để nội dung dễ đọc và
  tự điều chỉnh chiều cao theo kích thước màn hình.
- Dùng `assets/illustrations/nearby_map.png` minh họa trạng thái chưa có dữ liệu.
- Asset trò chơi chỉ được chọn lọc theo chức năng để tránh tải toàn bộ bộ tài
  nguyên không sử dụng. Một số thẻ chibi và thẻ đáp án từ
  `assets/source_game/graphics/` tạo mini game hỏi đáp 5 câu về Cao Lãnh; trả
  lời đúng được 10 xu, hoàn thành lượt được thêm 20 xu. Xu và vật phẩm được
  mua/trang bị lưu tạm trên thiết bị bằng SharedPreferences/localStorage, không
  phải tiền thật và chưa đồng bộ Firebase.
- Tách mini game thành module độc lập `lib/features/mini_game/` (screens,
  services, widgets); màn khám phá chỉ điều hướng đến module này. Gom các ảnh
  nhân vật, thẻ đáp án, xu và âm thanh đang sử dụng vào `assets/mini_game/`;
  thư viện character gốc/atlas không dùng trực tiếp vẫn được giữ nguyên trong
  `assets/character/`.
- Shop dùng icon có tên dễ nhận biết tại
  `assets/mini_game/characters/shop_icons/` và hoạt ảnh nhân vật hoa sen 6
  khung tại `assets/mini_game/characters/lotus/idle/`, có bộ ảnh riêng cho
  từng trang phục. Nhân vật trong shop và quiz dùng chung widget animation;
  icon vật phẩm vẫn hiển thị dưới dạng thẻ trang bị, không ghép sai tỉ lệ lên
  sprite. Giá thử nghiệm được hạ còn 4–12 xu để dễ mua và kiểm tra.
- Tách hai khung nhân vật thầy giáo từ atlas NPC trong
  `assets/mini_game/characters/teacher/` và dùng làm nhân vật hướng dẫn hoạt
  ảnh trong quiz. Bố cục câu hỏi đặt thầy giáo ở trên, mascot hoa sen đã mặc
  trang phục bên trái và khu câu hỏi/thẻ đáp án bên phải; thẻ đáp án xếp dạng
  lưới để tiện thao tác trên màn hình nhỏ.
- Thêm hiệu ứng âm thanh trả lời đúng/sai và mua vật phẩm từ
  `assets/mini_game/audio/fx/`; có thể tắt/bật âm thanh trong màn mini game.
  Không tự phát nhạc nền để tránh vi phạm giới hạn phát tự động của trình duyệt.
- Đã khảo sát gói tài nguyên nhân vật và đổi tên thư mục
  `assets/character-assets/` thành `assets/character/`. Gói gồm atlas mô tả
  trang phục nam/nữ, 3 sprite sheet NPC kèm plist, hiệu ứng, icon trang bị,
  giao diện avatar và âm thanh. Ảnh gốc của các sprite sheet PNG trong atlas
  trang phục còn thiếu theo danh sách tại
  `assets/character/docs/MISSING_character_png_sheets.txt`; đã tạo 176 ảnh
  placeholder hoa sen nguyên bản tại `assets/character/character/` theo khung
  trong plist để thử nghiệm đọc atlas. Đây không phải ảnh gốc và chưa thay thế
  được thiết kế trang phục thật. Có thể tạo lại bằng
  `assets/character/tools/generate_placeholders.ps1`; chi tiết tại
  `assets/character/placeholders/README.md`. Các tài nguyên được dùng trong shop
  được khai báo chọn lọc trong Flutter bundle để tránh tải toàn bộ gói.
- Làm mới màn hình đăng nhập/đăng ký bằng banner ảnh di tích Cao Lãnh có lớp
  phủ màu xanh trời và hồng dịu, nền chuyển sắc sky/blush, họa tiết hoa sen,
  icon cho ô email/mật khẩu và thẻ đăng nhập bo góc. Giữ nguyên xác thực
  Firebase, thông báo và luồng tiếp tục với tư cách khách.
- Đồng bộ shop và quiz theo màu xanh trời làm chủ đạo, hồng sen làm điểm nhấn;
  thay nguồn ảnh cũ bằng nhân vật hoa sen hoạt ảnh cùng icon trong
  `assets/character/`. Dùng font UVN Van từ `assets/fonts/UVNVan.ttf` làm font
  giao diện ứng dụng trong cấu hình Flutter.

## Kiểm kê và sắp xếp assets

- Gom tài nguyên game nguồn cũ vào `assets/source_game/`: `data/` (trước đây
  là `assets/asset/`), `graphics/` (trước đây là `assets/static/`) và `audio/`
  (trước đây là `assets/sound/`). Cấu trúc con bên trong được giữ nguyên để
  bảo toàn các atlas, plist, âm thanh và đường dẫn tương đối của gói nguồn.
- Tách font UVN Van đang dùng vào `assets/fonts/UVNVan.ttf`; `pubspec.yaml`
  tham chiếu font tại vị trí này. Các nhóm app đang tải vẫn nằm riêng trong
  `assets/mini_game/`, `assets/character/`, `assets/splash/` và
  `assets/illustrations/`.
- Thêm chú thích “Hoàng Sa, Trường Sa là của Việt Nam” trên bản đồ tìm địa
  điểm và bản đồ chi tiết. Chú thích là lớp giao diện của ứng dụng; nhãn tile
  nền vẫn do OpenStreetMap/Esri cung cấp và không bị chỉnh sửa.
- Kiểm tra 2.901 file trước khi sắp xếp bằng SHA-256: có 330 nhóm trùng byte
  (755 file thuộc các nhóm đó). Gộp 12 file trong
  `assets/source_game/graphics/gui/npc/` vì toàn bộ tên và nội dung đều trùng
  với `assets/character/npc/`. Các bản trùng còn lại được giữ nguyên: nhiều
  file thuộc các gói nguồn hoặc ngữ cảnh UI khác nhau, nên chỉ giống byte chưa
  đủ căn cứ để xóa đường dẫn mà gói có thể tham chiếu.
- Không đổi tên các frame animation hoặc biến thể màu/trang phục. Các thư mục
  asset được khai báo chọn lọc trong Flutter bundle vẫn giữ nguyên.

## Kiểm thử

- Bổ sung kiểm thử đảm bảo người dùng có thể tìm địa chỉ hoặc chọn địa điểm đã
  lưu mà không gọi dịch vụ GPS.
- Cập nhật kiểm thử để xác nhận GPS chỉ được gọi sau thao tác chủ động của người
  dùng, đồng thời luồng sắp xếp và lọc theo vị trí GPS vẫn hoạt động.
- Thêm kiểm thử giao diện xác nhận chỉ admin mới có thể tạo bản nháp.
- `flutter test`: 42 kiểm thử thành công; có kiểm thử tra cứu địa điểm OpenStreetMap,
  chọn tâm bằng nhấn giữ bản đồ không cần GPS, lọc địa điểm/bán kính 1, 5, 10 km,
  tích lũy xu, lưu tiến trình local, mua/trang bị nhiều slot, hoạt ảnh nhân vật
  từ module mini game, đổi palette đăng nhập và mở shop từ mini game.
- `flutter analyze`: không còn cảnh báo hoặc lỗi.
- `flutter build web`: build thành công, gồm icon trang bị, khung hoạt ảnh
  character và hiệu ứng
  âm thanh. Kiểm thử kết nối Firestore thật và
  triển khai Firestore Rules đang chờ bật Firestore API trong project.

## Định hướng phát triển: Điểm vui chơi

Phần này ghi nhận phạm vi đề xuất cho phiên bản mở rộng. Các nội dung dưới đây
chưa được xem là chức năng đã triển khai trong ứng dụng hiện tại.

### Kiến trúc phục vụ demo và khả năng triển khai

- **Firebase:** dùng để chứng minh khả năng triển khai web thực tế, gồm
  Firebase Authentication, Cloud Firestore và Firebase Hosting. Firebase là
  backend cloud minh họa cho tài khoản, dữ liệu địa điểm, yêu thích và quy
  trình publish.
- **Server local:** dùng trong buổi demo để quản lý phần truy vấn dữ liệu bản
  đồ và làm proxy gọi Overpass. Flutter Web gọi server local thay vì gọi
  Overpass trực tiếp, nhờ đó tránh giới hạn CORS và chủ động phục vụ dữ liệu
  cửa hàng, quán cà phê, rạp phim, công viên và khu vui chơi.
- **Khả năng triển khai sau demo:** server local có thể chuyển sang Firebase
  Functions hoặc Cloud Run khi cần vận hành thực tế; giao diện Flutter Web và
  mô hình dữ liệu Firebase vẫn được giữ lại.
- **Trình tự demo:** khởi động server local, chạy Flutter Web, kiểm tra bản
  đồ và các điểm vui chơi quanh vị trí chọn; sau đó trình bày Firebase project
  để chứng minh khả năng xác thực, lưu dữ liệu và triển khai web.

### Các giai đoạn phát triển

1. **Chuẩn bị phần cứng:** chuẩn bị máy tính phát triển, thiết bị Android/iOS
   để kiểm thử và các thiết bị cần thiết cho quá trình triển khai.
2. **Thiết lập Firebase:** đã tạo project và cấu hình FlutterFire cho Android,
   iOS, Web; phần Auth/Firestore đã có trong mã nguồn. Cần bật API, tạo
   database và bật Email/Password trên project.
3. **Thiết lập Flutter project:** đã kết nối Firebase Core, Authentication và
   Firestore cho quy trình tài khoản, tìm kiếm, yêu thích và quản trị địa điểm.
4. **Phát triển backend logic:** đã có backend cho tài khoản, quyền admin,
   danh sách địa điểm và yêu thích; sự kiện, ưu đãi, đánh giá và phản hồi vẫn
   là phạm vi phát triển tiếp theo.
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
