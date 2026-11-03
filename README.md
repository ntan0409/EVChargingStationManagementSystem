# EV Charging Station Management System

Hệ thống quản lý trạm sạc xe điện thông minh (EV Charging Station Management System) bao gồm toàn bộ mã nguồn **Frontend Mobile (Flutter)** và **Backend Web API (ASP.NET Core)**.

---

## 📂 Cấu Trúc Dự Án (Repository Structure)

```
EVChargingStationManagementSystem/
├── EVChargingStationManagementSystemMobile/   # 📱 Ứng dụng di động Flutter (iOS, Android, Web, Windows)
│   ├── lib/                                  # Source code Flutter (Provider, Dio, OSM Map, QR Scanner, Telemetry)
│   ├── android/                              # Cấu hình Android Native
│   ├── ios/                                  # Cấu hình iOS Native
│   ├── web/                                  # Giao diện Web
│   ├── windows/                              # Giao diện Windows Desktop
│   └── pubspec.yaml                          # Danh sách thư viện và cấu hình Flutter
│
└── EVChargingStationManagementSystemBE/       # ⚙️ Hệ thống Backend Web API (ASP.NET Core)
    ├── APIs/                                 # RESTful API Controllers & Swagger
    ├── BusinessLogic/                        # Services, DTOs & Xử lý nghiệp vụ
    ├── Infrastructure/                       # Entity Framework Core, DbContext, Repositories, Migrations
    ├── Common/                               # Enums, Helpers, Exceptions
    └── EVChargingStationManagementSystemBE.sln
```

---

## Chạy demo trên Windows

Cần Flutter SDK, .NET SDK hỗ trợ dự án net9.0 và SQL Server LocalDB. Tài khoản Windows đã thiết lập dự án có thể dùng lại cấu hình .NET User Secrets hiện có. Dữ liệu phát triển lưu trong LocalDB qua các buổi học.

Mở PowerShell tại thư mục gốc của repo và chạy backend bằng profile HTTP:

```powershell
sqllocaldb start MSSQLLocalDB
dotnet run --project .\EVChargingStationManagementSystemBE\APIs --launch-profile http
```

Nếu backend đã chạy, dùng lại cửa sổ đang mở. Chờ backend chạy tại `http://localhost:5058`. Swagger ở `http://localhost:5058/swagger`. Mở PowerShell thứ hai tại thư mục gốc:

```powershell
cd EVChargingStationManagementSystemMobile
flutter pub get --enforce-lockfile
flutter run -d chrome --web-hostname localhost --web-port 5387
```

Nếu cổng 5387 đã có Web demo, mở lại trang đang chạy. Để nạp code mới, dừng tiến trình Flutter cũ rồi chạy lại lệnh trên.

Để demo trên Android emulator, dùng `flutter devices` rồi chạy `flutter run -d <device-id>`. Flutter mặc định dùng `http://10.0.2.2:5058/api` trên Android emulator và `http://localhost:5058/api` trên Web. Nếu từng lưu URL API khác trong app, đặt lại URL trong phần cài đặt trước khi đăng nhập.

Để tạo APK debug trên Windows, chạy `powershell -ExecutionPolicy Bypass -File .\tool\build_android_debug.ps1` từ thư mục Flutter. APK nằm tại `build/app/outputs/flutter-apk/app-debug.apk`.

### Demo VNPAY Sandbox

Chạy trên database test riêng. Tạo tunnel HTTPS cho bộ nhận callback cổng 5398, cập nhật URL trong VNPAY SIT rồi chạy harness với origin của tunnel theo [hướng dẫn Sandbox](EVChargingStationManagementSystemMobile/audit/PHASE6_VNPAY_SANDBOX_RESULT.md). Mỗi phiên harness tạo đơn thử và tự dọn database tạm. Dùng thẻ test do VNPAY cung cấp. Nếu mở lại demo với tunnel mới, cập nhật IPN trước khi thanh toán.