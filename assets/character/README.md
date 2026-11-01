# Bộ file dựng nhân vật – Clash of Dices: Bubble War 1.0.6

## Quan trọng: thiếu ảnh sprite thân/đầu/vũ khí
Nhân vật ghép từ các lớp body, head, weapon, back (mỗi set có thêm bản _shop).
APK chỉ chứa các file .plist (bản đồ khung hình) trong character_atlas/; ảnh sheet .png tương ứng
KHÔNG có trong APK mà được tải từ server khi chạy (xem docs/VersionContent*.plist).
Danh sách ảnh còn thiếu: docs/MISSING_character_png_sheets.txt.
Nếu còn cache của game trên máy cũ (thường ở Android/data/<package>/files/) thì chép ảnh vào cùng thư mục với plist.

Các PNG placeholder tạm cho những sheet còn thiếu được tạo trong `character/`.
Đây là hình minh họa hoa sen nguyên bản để thử bố cục/đọc atlas, không phải
ảnh gốc của game và không phải mascot Bé Sen. Có thể tạo lại bằng
`tools/generate_placeholders.ps1`; xem `placeholders/README.md`.

## Có trong gói
- character_atlas/boy|girl|common : plist từng set (frame dạng boy/set02_body/0_0_1_0000.png)
- npc/ : 3 sheet + plist NPC, đầy đủ ảnh
- effects/ : hiệu ứng cánh, bụi chạy, ngôi sao nhân vật (có ảnh)
- avatar_ui/ : khung avatar profile + giao diện phòng chỉnh sửa
- icons/ : icon trang bị theo mã (configId = gender(1)+set(01)+slot(01)+mau(05))
- sound/ : giọng nam/nữ (vui, khóc)
