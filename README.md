# Ngưng Tụ STEM

App Flutter riêng cho dự án **máy ngưng tụ hơi nước ESP32** (STEM).

- MQTT realtime qua `wss://mqtt.duynguyen.io.vn/mqtt`
- Chip ID mặc định: `789` (khớp firmware `NgungTu_ESP32.ino`)
- Hiển thị: nhiệt độ KK, độ ẩm, điểm sương, mặt lạnh, mục tiêu, % sò, trạng thái
- Nút Bật/Tắt hệ thống qua MQTT

## Chạy local

```bash
flutter pub get
flutter run
```

## GitHub Actions

Push lên `main` sẽ tự:

1. Build **APK release** (artifact `ngungtu-apk`)
2. Build **iOS --no-codesign** (artifact `ngungtu-ios-unsigned`)

Tải artifact tại tab **Actions** của repo.

> iOS artifact chưa ký certificate — dùng để kiểm tra CI. Cài lên máy thật cần Apple Developer signing.

## Kết nối ESP32

1. Nạp firmware ngưng tụ (chipId `789`)
2. Cấu hình WiFi qua AP `NgungTu` → `http://192.168.4.1`
3. Mở app — khi MQTT + ESP online sẽ thấy số realtime
