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

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

### 1. ⚙️ Chạy Backend (ASP.NET Core)
```bash
cd EVChargingStationManagementSystemBE/APIs
dotnet restore
dotnet run
```
> API Swagger UI mặc định tại: `https://localhost:7252/swagger`

---

### 2. 📱 Chạy Mobile App (Flutter)
```bash
cd EVChargingStationManagementSystemMobile
flutter pub get

# Chạy trên thiết bị kết nối / máy ảo Android:
flutter run

# Hoặc chạy bản Windows Desktop:
flutter run -d windows
```

