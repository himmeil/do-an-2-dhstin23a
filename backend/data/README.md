# Dữ liệu backend

Thư mục chứa schema SQLite và snapshot SQL dùng để khôi phục dữ liệu bản đồ.
Các JSON/SQLite runtime có thể bị Git ignore; không chỉnh trực tiếp snapshot
được sinh tự động nếu chưa đồng bộ với dữ liệu nguồn.
Flutter Web production dùng bản sao đã đóng gói tại
`assets/data/osm_places.json`. Backend local đồng bộ asset này sau khi admin
cập nhật hoặc chọn snapshot; commit asset và deploy Hosting để phát hành dữ
liệu mới. Project dùng Firebase Spark nên không dùng Firebase Functions.
Schema tạo index tọa độ `(latitude, longitude)` để tăng tốc truy vấn vùng lân
cận; truy vấn vẫn áp dụng khoảng cách chính xác sau bước lọc chỉ mục.
SQLite chạy migration một lần để đổi các mã OSM thô (ví dụ `museum`, `pitch`,
`sports_centre`) sang mã danh mục ứng dụng trước khi API phục vụ dữ liệu.
Snapshot hiện có 330 mục từ OSM; thời điểm dữ liệu nguồn là
`2026-11-02T10:00:08.757Z` (17:00:08 UTC+7, ngày 02/11/2026). Thời điểm ghi
file mới hơn không đồng nghĩa dữ liệu OSM đã được làm mới. Khi nhập dữ liệu,
backend bỏ các đoạn đường chỉ có tên (`highway=*`) nhưng giữ trạm xe buýt và
địa điểm có thẻ POI; mã OSM chưa có quy tắc vẫn giữ trong **Khác**, không tự
gán thành điểm vui chơi. Dữ liệu OSM được phân phối theo ODbL; cần ghi công
“© OpenStreetMap contributors” khi hiển thị hoặc phân phối dữ liệu.

Đối chiếu transit trên snapshot cho thấy 2 đối tượng `amenity=bus_station` và
11 đối tượng `highway=bus_stop`. Đây là số liệu OSM, không phải danh mục chính
thức của đơn vị vận tải. Hai điểm tên gần nhau cách 7,3 m được giữ nguyên vì
có thể là hai phía/tuyến dừng khác nhau; không gộp nếu chưa xác minh độc lập.
Google Maps và nguồn chính thức chưa cho kết quả có thể đối chiếu máy đọc được
trong lần rà soát này, nên chưa thêm hoặc xóa các điểm transit chưa xác nhận.

## Nhật ký chỉnh sửa

- Chỉ giữ tối đa 10 mục nhật ký gần nhất; thêm mục mới ở cuối và xóa mục cũ nhất khi vượt giới hạn.
- 2026-11-03 08:12 (UTC+7): Chuẩn hóa mã `bus_stop`/`bus_station` thành `ben_xe`, mã lưu trú thành `tro`, và đồng bộ phân loại JSON theo SQL.
- 2026-11-03 08:28 (UTC+7): Áp dụng quy ước lưu 10 lần chỉnh sửa gần nhất cho nhật ký dữ liệu.
- 2026-11-03 15:19 (UTC+7): Thêm index tọa độ cho truy vấn địa điểm trong bán kính.
- 2026-11-03 15:29 (UTC+7): Chuẩn hóa danh mục OSM cũ trong SQLite trước khi phục vụ API.
- 2026-11-03 16:06 (UTC+7): Loại 688 đoạn đường chỉ có tên khỏi snapshot 1.018 mục; giữ 330 POI/địa danh chưa xác minh, chuẩn hóa alias danh mục và giữ nguyên các cặp trạm chưa đủ căn cứ gộp.
