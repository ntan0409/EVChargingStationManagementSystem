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

## Setup cho cả nhóm trên Windows

1. Cài .NET SDK 9 hoặc SDK mới hơn có runtime .NET 9.
2. Cài Flutter stable 3.47.6 (Dart 3.13.5), phiên bản đã dùng để kiểm thử.
3. Cài SQL Server Express LocalDB và sqlcmd. Cài EF CLI bằng `dotnet tool install --global dotnet-ef --version 9.0.9` nếu thiếu.
4. Clone repo và mở PowerShell tại thư mục gốc.
5. Vào thư mục Flutter chạy `flutter pub get --enforce-lockfile`, rồi quay lại thư mục gốc.
6. Chạy `powershell -ExecutionPolicy Bypass -File .\run_backend_local.ps1 -SetupOnly` để tạo JWT cục bộ, migrate và seed EVCSMS_TeamDemo. Terminal in thông tin đăng nhập demo.
7. Chạy `powershell -ExecutionPolicy Bypass -File .\run_backend_local.ps1`. Chờ API cổng 5058. Có thể gộp bước 6 và 7 bằng `-InitializeDatabase`.
8. Trong thư mục Flutter chạy `flutter run -d chrome --web-hostname localhost --web-port 5387`, hoặc `flutter run -d <device-id>` với Android Emulator.

Flutter dùng API local mặc định. Nếu đã lưu URL từ dự án khác, đặt lại URL trong màn hình cài đặt. Cash dùng backend local. Dùng tài khoản Staff trong Swagger/API để xác nhận tiền mặt.

Khi người quản lý có backend Sandbox dùng chung, cung cấp cho nhóm duy nhất URL API HTTPS. Chạy Flutter với `--dart-define=API_BASE_URL=https://<team-host>/api`. Người quản lý cấu hình merchant, khóa ký, JWT và IPN trên backend dùng chung. Các thành viên chỉ cần địa chỉ API. Script local chạy Cash và dùng database EVCSMS_TeamDemo riêng.

File tùy chọn chứa cấu hình riêng của quản trị viên phải giữ ngoài Git. Có thể dùng .NET User Secrets cho Development hoặc biến môi trường trên máy chủ. Production yêu cầu JWT và CORS được cấu hình riêng.

Swagger local ở `http://localhost:5058/swagger`. Để build APK debug trên Windows,
chạy `powershell -ExecutionPolicy Bypass -File .\tool\build_android_debug.ps1` từ thư mục Flutter.

Xem [hướng dẫn VNPAY Sandbox](EVChargingStationManagementSystemMobile/audit/PHASE6_VNPAY_SANDBOX_RESULT.md)
và [báo cáo team setup](EVChargingStationManagementSystemMobile/audit/TEAM_SETUP_RESULT.md).
### Demo sạc không cần thiết bị

Backend chạy qua `run_backend_local.ps1` bật mô phỏng trên EVCSMS_TeamDemo.
Sau khi check-in đúng lịch, backend mô phỏng tín hiệu cắm xe. Để dừng sạc không cần nhập kWh,
khởi chạy Flutter với hai tham số demo. Nếu API dùng cổng 5058, Android Emulator chạy:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:5058/api --dart-define=EVCSMS_CHARGING_DEMO=true
```

Backend tính kWh mô phỏng theo thời gian phiên và giới hạn dung lượng xe. Demo này dùng Cash.

### Thanh toán SePay Test Mode

1. Trong dashboard SePay, bật Test Mode, tạo tài khoản ngân hàng test và API Access token.
2. Trên máy chạy backend, chạy `powershell -ExecutionPolicy Bypass -File .\configure_sepay_test.ps1 -TestBankAccountId <UUID>`. Nhập token khi được hỏi. Script kiểm tra tài khoản bằng API Sandbox và lưu token vào User Secrets.
3. Khởi động lại backend TeamDemo. Chọn SePay Test Mode trên hóa đơn. App hiển thị số tiền và mã giao dịch.
4. Tạo giao dịch tiền vào mô phỏng trong dashboard cho đúng tài khoản test. Nhập đúng số tiền và dùng nguyên mã của đơn làm nội dung giao dịch. Backend tự kiểm tra trong lúc app chờ xác nhận.

Luồng này gọi API Sandbox từ localhost và dùng dữ liệu mô phỏng của SePay.

Người quản lý có thể cấp riêng `appsettings.Local.json` cho thành viên được phép dùng cùng tài khoản SePay Test Mode. Đặt file tại thư mục gốc repo. Script `run_backend_local.ps1` tự đọc ba mục SePay trong file, tự tạo JWT riêng trên mỗi máy và dùng LocalDB TeamDemo. File này chứa token Test Mode và được Git bỏ qua. Chia sẻ file qua kênh riêng của nhóm.
