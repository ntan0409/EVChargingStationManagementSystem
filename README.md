# EV Charging Station Management System

Hệ thống quản lý trạm sạc xe điện thông minh (EV Charging Station Management System) bao gồm toàn bộ mã nguồn **Frontend Mobile (Flutter)** và **Backend Web API (ASP.NET Core)**.

**Bắt đầu tại [DEMO_GUIDE.md](DEMO_GUIDE.md):** cài công cụ một lần, nhận file cấu hình riêng của nhóm rồi bấm **RUN_DEMO.cmd**. Hướng dẫn gồm Booking → Check-in → sạc demo → SePay thẻ thử ngay trong Android, Cash, tài khoản và xử lý lỗi.

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

Sau khi cài các công cụ và đặt `appsettings.Local.json` ở thư mục gốc, bấm đúp `RUN_DEMO.cmd` để mở backend, Android Emulator và app. Lần đầu chuẩn bị APK. Những lần sau dùng lại APK đã cài, chỉ build lại khi mã nguồn thay đổi. Giữ cửa sổ báo lỗi nếu có để xem bước nào chưa chạy được. Nhật ký backend nằm trong `.artifacts/demo-launcher` và có mật khẩu demo cục bộ.

1. Cài .NET SDK 9 hoặc SDK mới hơn có runtime .NET 9.
2. Cài Flutter stable 3.47.6 (Dart 3.13.5), phiên bản đã dùng để kiểm thử.
3. Cài SQL Server Express LocalDB với instance mặc định `MSSQLLocalDB`.
4. Clone repo và chép file riêng `appsettings.Local.json` vào thư mục gốc, cạnh README. Git bỏ qua file này.
5. Mở solution backend trong Visual Studio, chọn startup project `APIs` và profile `http`, rồi bấm Run. Backend tự khôi phục gói khi build, tạo JWT cục bộ khi cần, áp dụng migration và nạp dữ liệu cho `EVCSMS_TeamDemo` trước khi mở cổng 5058. Cửa sổ log in tài khoản và mật khẩu demo. Chạy bằng terminal tương đương với `dotnet run --project EVChargingStationManagementSystemBE/APIs` từ thư mục gốc.
6. Mở thư mục Flutter trong Android Studio, chọn Android Emulator và bấm Run. Flutter dùng API local mặc định. Nếu chạy Web để thử Google Sign-In, dùng `flutter run -d chrome --web-hostname localhost --web-port 5387` để khớp origin đã đăng ký.

Flutter dùng API local mặc định. Nếu đã lưu URL từ dự án khác, đặt lại URL trong màn hình cài đặt. Cash dùng backend local. Dùng tài khoản Staff trong Swagger/API để xác nhận tiền mặt.

Backend nạp cấu hình demo từ một file riêng khi chạy Development. File chứa cấu hình Google, CORS, cơ sở dữ liệu, JWT issuer và audience, Cloudinary và thanh toán. Backend luôn chọn LocalDB `EVCSMS_TeamDemo` và tắt VNPay trong chế độ này. Khóa ký JWT được tạo và lưu riêng trên máy khi cần. Production dùng cấu hình riêng.

Dữ liệu mẫu được khai báo trong `Infrastructure/Data/Seed/TeamDemoSeed.cs`. Backend dùng EF Core để thêm các bản ghi còn thiếu sau migration, giữ nguyên các bản ghi demo đã có khi chạy lại.

Swagger local ở `http://localhost:5058/swagger`. Để build APK debug trên Windows,
chạy `powershell -ExecutionPolicy Bypass -File .\tool\build_android_debug.ps1` từ thư mục Flutter.

Xem [hướng dẫn VNPAY Sandbox](EVChargingStationManagementSystemMobile/audit/PHASE6_VNPAY_SANDBOX_RESULT.md)
và [báo cáo team setup](EVChargingStationManagementSystemMobile/audit/TEAM_SETUP_RESULT.md).
### Demo sạc không cần thiết bị

Backend TeamDemo mô phỏng tín hiệu cắm xe sau khi check-in đúng lịch. Flutter đọc chế độ từ phiên sạc và hiển thị nút dừng demo tự động. Backend tính kWh theo thời gian phiên và giới hạn dung lượng xe.

### Thanh toán bằng thẻ thử SePay Sandbox (demo trên lớp)

File riêng `appsettings.Local.json` của nhóm cần có `SePay.Enabled=true`,
`SePay.GatewayMerchantId` (bắt đầu bằng `SP-TEST-`) và `SePay.GatewaySecretKey`
(bắt đầu bằng `spsk_test_`). Chủ dự án đã cấu hình file này; thành viên nhận file qua kênh riêng,
không tự đăng ký lại. Không đưa file lên Git hoặc vào APK.

1. Dừng phiên sạc rồi chọn **SePay Sandbox — thẻ thử (tiền giả)**.
2. Trên Android, app tự mở trang thẻ thử ngay trong màn hình thanh toán (WebView), không chuyển sang Chrome. Các nền tảng khác dùng trình duyệt. Chỉ nhập dữ liệu giả: tên `DEMO USER`,
   số thẻ `4111111111111111`, hạn `12/30`, CVV `123` (đã kiểm tra trên Sandbox).
3. Bấm Thanh toán và chọn kết quả mô phỏng trên trang SePay.
4. Trên Android, app kiểm tra backend mỗi 5 giây và tự đóng màn hình thẻ khi backend xác nhận Paid. Có nút trở về hóa đơn và nút Back của Android nếu muốn đóng sớm; đóng trang không hủy hoặc xác nhận đã thanh toán.
   Có nút mở lại trang thẻ; liên kết hết hạn sau 15 phút và được cấp mới khi mở lại.

Backend chỉ ghi nhận khi API SePay Sandbox xác nhận đúng mã hóa đơn, chủ hóa đơn,
số tiền, VND, trạng thái CAPTURED và giao dịch PAYMENT/APPROVED.
Không cần dashboard tạo chuyển khoản, IPN public hay tunnel cho luồng tra cứu này.
Trạng thái ở trang chuyển hướng không tự làm hóa đơn thành Paid. Không dùng thẻ thật.

Hóa đơn đã tạo bằng phương thức cũ giữ nguyên phương thức; không tự chuyển hóa đơn đang chờ sang thẻ.

### SePay Test Mode chuyển khoản (phương thức cũ)

1. Người quản lý cung cấp file `appsettings.Local.json` đã có token Test Mode và UUID tài khoản test.
2. Chọn SePay Test Mode trên hóa đơn. App hiển thị số tiền và mã giao dịch.
3. Tạo giao dịch tiền vào mô phỏng trong dashboard cho đúng tài khoản test. Nhập đúng số tiền và dùng nguyên mã của đơn làm nội dung giao dịch. Backend tự kiểm tra trong lúc app chờ xác nhận.

Luồng này gọi API Sandbox từ localhost và dùng dữ liệu mô phỏng của SePay.

Người quản lý có thể cấp riêng `appsettings.Local.json` cho thành viên được phép dùng cùng tài khoản SePay Test Mode. Đặt file tại thư mục gốc repo. File chứa token Test Mode và được Git bỏ qua. Chia sẻ file qua kênh riêng của nhóm.
