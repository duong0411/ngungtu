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

1. Build **Android APK** → `ngungtu-stem.apk`
2. Build **iOS IPA** → `ngungtu-stem.ipa`
3. Tạo **GitHub Release** và đính kèm 2 file trên

Tải tại tab **Releases** của repo.

> IPA trên CI chưa codesign. Cài lên iPhone thật cần ký bằng Apple Developer / Xcode.

## Kết nối ESP32

1. Nạp firmware ngưng tụ (chipId `789`)
2. Cấu hình WiFi qua AP `NgungTu` → `http://192.168.4.1`
3. Mở app — khi MQTT + ESP online sẽ thấy số realtime
