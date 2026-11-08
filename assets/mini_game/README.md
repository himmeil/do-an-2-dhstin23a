# Mini game - NPC

## NPC atlas

- `assets/npc_1.png` (`assets/npc_1.plist`): thầy giáo.
- `assets/npc_3.png` (`assets/npc_3.plist`): rương kho báu.
- Các ảnh atlas được khai báo riêng trong `pubspec.yaml`; widget
  `NpcAtlasAnimation` cắt khung theo tọa độ atlas, bao gồm cả khung bị xoay.

## Hành động trong quiz

- Khi chọn một đáp án, thầy giáo phát animation phản hồi và hiển thị lời khen
  hoặc gợi ý tùy kết quả.
- Sau khi hoàn thành 5 câu, thầy giáo phát animation dẫn người chơi tới rương.
- Nhấn vào rương để phát chuỗi animation mở rương; trạng thái mở được giữ đến
  khi rời màn kết quả hoặc chơi lại.
- Hai khung thầy giáo trong `characters/teacher/` tiếp tục được dùng cho trạng
  thái chờ trong lúc trả lời câu hỏi.
