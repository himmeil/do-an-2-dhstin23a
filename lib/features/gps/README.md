# Feature GPS

`services/location_service.dart` định nghĩa `LocationService` và adapter
`GeolocatorLocationService`. UI nhận abstraction qua constructor; xin quyền,
kiểm tra trạng thái GPS và mở cài đặt nằm trong adapter.

Không yêu cầu vị trí tự động khi mở ứng dụng. Luồng xin GPS chỉ chạy sau thao
tác chủ động của người dùng.
