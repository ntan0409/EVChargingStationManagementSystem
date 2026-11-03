# EVCSMS Team Setup

## Audit và quyết định

- API dùng một appsettings.json. Các file trùng đã được bỏ trong thay đổi đang làm. Development đọc User Secrets và biến môi trường. Production giữ kiểm tra JWT và CORS hiện có.
- Backend cấp JWT sau khi đăng nhập. Script tự sinh khóa ngẫu nhiên cục bộ nếu thiếu. Khóa ký nằm ngoài Git.
- Script cũ khởi tạo EVCSMS và không seed tự động. Quy trình nhóm dùng EVCSMS_TeamDemo cho cả migrations, seed và khi chạy API.
- Cash dùng quyền Staff/operator và các kiểm tra amount, owner chain, trạng thái và chống ghi trùng hiện có.
- VNPAY chỉ dùng Sandbox. Cấu hình merchant và IPN thuộc backend dùng chung. Flutter nhận URL từ API_BASE_URL. URL khi build được ưu tiên khi khởi động app.
- Seed gồm trạm, trụ, cổng, xe, Staff và tài xế mẫu. Setup đổi thông tin nhận dạng của các tài khoản seed legacy đã biết trong TeamDemo sang định danh giả và thiết lập mật khẩu cho các tài khoản demo. Migrations lịch sử được giữ nguyên.

## Cài đặt và file cần nhận

.NET SDK có runtime .NET 9, dotnet-ef 9.0.9, SQL Server Express LocalDB, sqlcmd và Flutter 3.47.6 với Dart 3.13.5. Chạy theo README. Luồng local dùng file trong repo và không cần nhận file bí mật. Để dùng VNPAY, thành viên cần một URL API HTTPS từ người quản lý. Người quản lý nhập terminal và khóa ký tại backend test, lưu trong User Secrets hoặc biến môi trường, rồi đăng ký IPN với VNPAY SIT. Các file cấu hình cá nhân .env.local và appsettings.Local.json được Git bỏ qua.

## Kiểm tra trên máy phát triển

- SetupOnly đã tạo EVCSMS_TeamDemo mới từ migrations, seed 12 mẫu xe, 10 trạm, 30 trụ, 60 cổng, 10 Staff và 10 tài xế. Chạy lại setup thành công.
- Kestrel chạy ở cổng test 5068, API trả 12 trạm gồm 2 trạm legacy. Tài xế demo và Staff demo đều đăng nhập và nhận JWT thật.
- Bộ kiểm thử tích hợp hiện có đã xác minh Cash và lịch sử giao dịch trên một LocalDB tạm riêng với 167 kiểm tra đạt. Bộ Flutter sau đổi cấu hình đạt 244 test. Kiểm tra HTTP thật thực hiện tại máy chạy backend. Chưa kiểm tra Flutter giao tiếp với backend từ máy thành viên khác.
- Quy trình này dùng database riêng. Dữ liệu thanh toán được tạo trong fixture tạm bởi API thật.

## BLOCKED

VNPAY Sandbox dùng chung chưa thể xác minh vì chưa có endpoint HTTPS chung với IPN đăng ký cho cả nhóm. Cash local đã sẵn sàng. Sau khi có endpoint, cần chạy giao dịch bằng thẻ test và đối chiếu Payment, phiên Paid và đúng một Transaction trên database test. Không triển khai cloud trong lượt này.
# Cập nhật setup tự động

Đặt file riêng `appsettings.Local.json` ở thư mục gốc rồi chạy project `APIs` với profile `http`. Backend tự chạy migration và seed trước khi mở cổng. Thành viên cần .NET SDK, Flutter và SQL Server Express LocalDB. EF CLI và sqlcmd không cần cho luồng khởi động này.

Kiểm tra bản Git sạch có bản sửa trên một instance LocalDB riêng với database chưa có bảng. Backend áp dụng 14 migration, nạp 12 trạm và 20 tài khoản có mật khẩu. Đăng nhập driver và staff đều nhận JWT. API bật Cash và SePay Test Mode. Flutter đạt 244/244 bài test. Lượt này chưa chạy lại giao dịch SePay mô phỏng đến trạng thái Paid hoặc Google Sign-In Android.
