# Feature nạp dữ liệu

`services/place_import_parser.dart` phân tích CSV/TSV/JSON thành model địa
điểm và báo lỗi theo từng dòng. `screens/import_screen.dart` thu thập xác nhận
của người dùng rồi gọi `PlaceService`; lưu trữ được inject từ composition root.

Parser không truy cập Firestore, SharedPreferences hay UI.
