# App đo tốc độ GPS - Hướng dẫn build & cài lên iPhone 6s (jailbreak, không cần Mac)

## 1. Cài Flutter trên máy Windows/Linux
- Tải Flutter SDK: https://docs.flutter.dev/get-started/install
- Chạy `flutter doctor` để kiểm tra môi trường (bỏ qua cảnh báo về Xcode vì không có Mac)
- Test app trên máy Android hoặc emulator trước: `flutter run`

## 2. Thêm quyền truy cập vị trí cho iOS

**Vì sao cần bước này:** Trên iOS, app muốn dùng GPS thì bắt buộc phải khai báo
trước lý do xin quyền vị trí. Nếu không khai báo, app sẽ **tự crash ngay lập tức**
khi cố lấy vị trí, thay vì hiện hộp thoại xin quyền như bình thường. Khai báo này
nằm trong một file cấu hình tên là `Info.plist` — coi như "lý lịch" của app, khai
báo tên app, quyền cần dùng, v.v.

**Cách làm:**
1. File `ios/Runner/Info.plist` chưa tồn tại ngay từ đầu — nó chỉ được tự sinh ra
   sau khi bạn chạy lệnh `flutter create .` trong thư mục project (lệnh này tạo
   toàn bộ khung project, gồm cả thư mục `ios/`).
2. Sau khi chạy xong, mở file `ios/Runner/Info.plist` bằng bất kỳ trình soạn thảo
   text nào (VS Code, Notepad++...). File này có dạng XML, nội dung chính nằm
   trong cặp thẻ `<dict> ... </dict>`. Dán 2 dòng dưới đây vào **bên trong** cặp
   thẻ đó (chèn vào giữa, trước dòng `</dict>` đóng cuối cùng là được):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần vị trí để đo tốc độ di chuyển</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ứng dụng cần vị trí để đo tốc độ di chuyển</string>
```

3. **Quan trọng:** khi commit code (bước 3 bên dưới), nhớ đưa cả thư mục `ios/`
   lên GitHub cùng — nếu bỏ sót, workflow trên GitHub sẽ tự tạo `ios/` mới tinh
   (không có quyền GPS bạn vừa thêm) và app sẽ bị crash khi build xong đem cài.

## 3. Đẩy code lên GitHub
Trên máy Windows/Linux của bạn, trong thư mục project (đã có main.dart, pubspec.yaml,
.gitignore, .github/workflows/build-ios.yml):
```
git init
git add .
git commit -m "speedo app"
git branch -M main
git remote add origin https://github.com/<tên-bạn>/speedo_app.git
git push -u origin main
```

## 4. GitHub tự động build ra file .ipa — bạn không cần làm gì thêm
File `.github/workflows/build-ios.yml` đã cấu hình sẵn: mỗi lần bạn `git push`,
GitHub tự cấp 1 máy macOS ảo (miễn phí) để build app, build xong đóng gói thành
`.ipa` không cần chữ ký (vì máy đích đã jailbreak, không cần Apple ID).

Cách xem kết quả:
1. Vào repo trên GitHub → tab **Actions**
2. Chờ workflow "Build iOS IPA" chạy xong (khoảng 5-10 phút), thấy dấu tích xanh ✅
3. Bấm vào lần chạy đó → kéo xuống mục **Artifacts** → tải file `speedo_app-ipa.zip`
4. Giải nén ra được file `speedo_app.ipa`

## 5. Cài AppSync Unified trên iPhone (một lần duy nhất)
- Mở Cydia/Sileo → thêm nguồn AppSync Unified phù hợp với bản jailbreak đang dùng
- Cài gói AppSync Unified → cho phép cài .ipa không cần chữ ký

## 6. Cài .ipa lên iPhone qua USB
Trên Windows/Linux:
```
pip install --user libimobiledevice   # hoặc cài qua trình quản lý gói của distro
ideviceinstaller -i speedo_app.ipa
```
Hoặc dùng công cụ GUI như 3uTools (Windows) → kéo thả file .ipa vào mục "Cài ứng dụng".

## 7. Chạy thử
Mở app trên iPhone, cấp quyền vị trí khi được hỏi, ra ngoài trời (GPS trong nhà kém chính xác) để test tốc độ di chuyển thực tế.

## Ghi chú
- `position.speed` từ package geolocator trả về m/s, độ chính xác phụ thuộc tín hiệu GPS,
  thường sai số vài km/h ở tốc độ thấp.
- iPhone 6s tối đa chạy iOS 15.x — đảm bảo bản Flutter/geolocator bạn dùng tương thích
  (bản trong pubspec.yaml đính kèm đã test ổn với iOS 12+).
