# Chạy và demo EV Charging trên Android

## Chuẩn bị một lần

1. Cài .NET SDK 9 và runtime .NET 9. Đã kiểm thử với SDK mới hơn có runtime 9.
2. Cài Flutter stable 3.47.6 / Dart 3.13.5; thêm `flutter` vào PATH.
3. Cài SQL Server Express LocalDB, có instance `MSSQLLocalDB`.
4. Cài Android Studio, Android SDK, Platform Tools, Command-line Tools và Android Emulator. Chạy `flutter doctor --android-licenses`, chấp nhận giấy phép sau khi đọc. Tạo một thiết bị ảo **có Google Play** trong Device Manager.
5. Clone repository. Nhận **appsettings.Local.json mới nhất** từ chủ dự án qua kênh riêng và đặt cạnh `RUN_DEMO.cmd` ở thư mục gốc. Không đặt file vào Flutter, không đưa lên Git. Mẫu không có secret là `team-settings.example.json`; mẫu này chưa bật payment.
6. Bấm đúp **RUN_DEMO.cmd**. Lần đầu cần Internet để tải dependencies và build. Script mở Backend, emulator rồi app; các lần sau dùng lại APK nếu source không đổi.

Backend tự tạo database **EVCSMS_TeamDemo**, apply migration và seed bản ghi còn thiếu bằng EF Core. Không cần `dotnet ef database update`, tự tạo JWT, nhập lại merchant credentials hay sửa URL trong source. Không chạy đồng thời một Backend khác trên cổng 5058.

`appsettings.Local.json` là file có secrets của môi trường demo, chỉ chia sẻ cho thành viên được phép. Khóa JWT được Backend tự tạo/lưu trên từng máy khi chưa có; người dùng nhận JWT riêng sau khi đăng nhập. Không có token đăng nhập dùng chung trong source.

## Tài khoản và thiết bị

- Google: dùng tài khoản được Google Cloud project cho phép. OAuth phải khớp package `com.fptu.prm.ev_charging_station`, SHA-1 của APK và Web Client ID. Máy mới có debug keystore khác sẽ cần chủ project thêm Android OAuth client với SHA-1 đó; copy appsettings không tự đăng ký chữ ký mới trên Google. Có thể dùng email demo ngay nếu chưa chuẩn bị Google OAuth.
- Email demo: `driver1@evcsms-demo.invalid` đến `driver10@evcsms-demo.invalid`.
- Staff: `staff1@evcsms-demo.invalid` đến `staff10@evcsms-demo.invalid`; mỗi nhân viên được gán trạm demo tương ứng.
- Mật khẩu demo được Backend in khi khởi động, trong `.artifacts/demo-launcher/backend.log` nếu dùng launcher. Không đưa log này lên Git. Dùng đúng mật khẩu của máy đó.
- Android Emulator dùng Backend `http://10.0.2.2:5058/api`. Swagger: `http://localhost:5058/swagger`.
- Điện thoại thật cần kết nối tới máy chạy Backend qua LAN; APK cấu hình cho emulator không tự kết nối được tới PC từ điện thoại thật.

## Luồng demo chính (không cần trụ sạc thật)

1. Đăng nhập Google hoặc email demo.
2. Nếu app yêu cầu: hoàn tất tên, số điện thoại hợp lệ và chọn xe trong catalog (ưu tiên VinFast). Nút xác nhận ở cuối màn hình cố định.
3. Chọn **Đặt lịch sạc**, chọn trạm đang hoạt động và xe trong hồ sơ. Đặt giờ cách hiện tại ít nhất **5 phút** (ví dụ +6 phút); có thể check-in từ 15 phút trước giờ đặt. Không chọn trạm bảo trì.
4. Vào **Lịch đặt**, mở lịch vừa tạo và dùng **Mã Check-in**. Tiếp tục tới cổng được cấp cho đúng lịch/xe; không lấy GUID của cổng khác để thử.
5. Chọn **Bắt đầu sạc**. Chế độ demo tự mô phỏng cắm xe sau check-in; không sửa trạng thái SQL bằng tay. Nếu chưa sẵn sàng, bấm Thử lại và kiểm tra lịch/xe/cổng.
6. Chờ ít nhất **10–20 giây** để có điện năng khác 0. Màn hình tự đọc số điện và chi phí demo. Bấm **Dừng sạc (demo)**; Backend chốt số đo và số tiền. Không cần nhập kWh bằng tay.
7. Nếu có voucher hợp lệ đã đổi, áp dụng **trước khi tạo yêu cầu thanh toán**. Backend snapshot số tiền khi chọn phương thức.
8. Chọn một phương thức bên dưới. Sau khi Backend xác nhận Paid, mở **Tài khoản → Lịch sử giao dịch & Hóa đơn** để kiểm tra. Có thể đặt lịch mới khi luồng cũ đã hoàn tất.

## SePay Sandbox — nhập thẻ trực tiếp trong app Android

Chọn **SePay Sandbox — thẻ thử (tiền giả)**. WebView mở ngay trong ứng dụng, không cần Chrome, tunnel hay HTTPS public cho luồng tra cứu kết quả này. Cần Internet và merchant Sandbox còn hiệu lực trong file riêng.

| Ô | Dữ liệu giả đã thử |
| --- | --- |
| Tên chủ thẻ | `DEMO USER` |
| Số thẻ | `4111111111111111` |
| Ngày hết hạn | `12/30` |
| CVV | `123` |

Bấm Thanh toán, rồi người demo chọn **Thanh toán thành công** hoặc **Thanh toán thất bại** trong hộp kết quả mô phỏng của SePay. Chỉ dùng dữ liệu giả.

App tự tra cứu Backend mỗi 5 giây. Chỉ khi API SePay xác nhận đúng hóa đơn, chủ sở hữu, số tiền, VND và giao dịch được duyệt thì Backend mới ghi thanh toán và lịch sử. Không tin riêng chữ “thành công” trên trang web.

Nút Back hoặc **Trở về hóa đơn / Kiểm tra kết quả** đóng trang thẻ; thao tác này không tự hủy hoặc xác nhận thanh toán. Có thể mở lại cùng yêu cầu đang chờ. Không bấm tạo một yêu cầu mới để xử lý phản hồi chậm. Hóa đơn cũ dùng SePayTest chuyển khoản vẫn giữ phương thức cũ, không tự chuyển sang thẻ.

Hiện kết quả mô phỏng thất bại chưa tự hủy hóa đơn trong app; hóa đơn chưa có xác nhận CAPTURED vẫn chờ. Không dùng tình huống thất bại cho lượt demo thành công chính nếu chưa chuẩn bị cách xử lý hóa đơn chờ.

## Cash — đúng nhân viên xác nhận

Chọn **Thanh toán tại quầy**. Hóa đơn vẫn đang chờ, chưa Paid.

Trên Swagger, đăng nhập tài khoản Staff được gán trạm qua `POST /api/Auth/login`, dùng JWT trả về trong Authorize. Xem yêu cầu tại `GET /api/Payment?pendingOnly=true`, rồi gọi `PATCH /api/Payment/offline-status?paymentId=...` với body `{"receivedAmount":<đúng số tiền hóa đơn>}` sau khi giả lập nhận tiền tại quầy. Không dùng tài khoản tài xế hoặc Staff trạm khác; không sửa Paid trực tiếp trong SQL.

Flutter Phase hiện tại dành cho tài xế; không đăng nhập Staff vào Flutter để nhận tiền. UI quản trị web của nhóm là thành phần riêng; Swagger/API là cách demo Cash đã xác định ở đây.

## Chức năng phụ

- Garage: chọn xe trong catalog có thông số hợp lệ; không đổi xe khi còn lịch/phiên/hóa đơn đang hoạt động.
- Bản đồ/trạm: xem trạm hoạt động, cổng trống. GPS emulator và bản đồ cần vị trí/Internet; lỗi tile không có nghĩa Backend đã ngừng.
- Quét QR: quét GUID thật của cổng; nếu emulator không quét được, dùng **Tiếp tục tới cổng sạc** từ lịch đã check-in. Nhập mã cổng chỉ là lựa chọn bổ sung.
- Voucher/điểm: xem danh sách, đổi khi đủ điểm, áp dụng trước payment; điểm có thể bằng 0 trên database mới.
- Hồ sơ/lịch sử: thông tin và giao dịch thuộc người đang đăng nhập. Các mục chưa có dữ liệu hiển thị rỗng; seed không tạo giao dịch Paid mẫu.

## Khi gặp lỗi

| Hiện tượng | Cách kiểm tra |
| --- | --- |
| Không kết nối Backend | Mở `http://localhost:5058/`, xem log launcher; trong emulator đặt API về `http://10.0.2.2:5058/api`. |
| LocalDB không khởi động | Kiểm tra `sqllocaldb info MSSQLLocalDB`, cài đúng LocalDB; không hardcode pipe `LOCALDB#...` vì pipe thay đổi mỗi lần chạy. |
| Google lỗi trên máy mới | Kiểm tra Web Client ID, package, SHA-1 debug keystore của máy và Audience/Test Users phía Google Cloud. Email demo vẫn dùng được. |
| SePay thẻ thử bị mờ | Cần file cấu hình riêng mới nhất có GatewayMerchantId/GatewaySecretKey Sandbox. Không dùng token User API thay secret của Gateway. |
| Cổng Preparing/đang sạc | Kiểm tra đúng lịch check-in/xe; mở lại phiên hiện tại nếu đã có phiên, không bắt đầu lần nữa. |
| Không tạo được payment online 0đ | Đã dừng quá sớm; dùng một lượt demo có điện năng khác 0. Không sửa tiền trong SQL. |
| Hóa đơn chờ | Đóng trang và kiểm tra lại; Backend cần truy vấn SePay thành công. Không tự đổi trạng thái Paid. |

VNPay bị tắt trong chế độ TeamDemo này. Không cần đăng ký VNPay cho luồng SePay Sandbox.

Database demo được giữ qua các lần chạy; launcher không tự xóa lịch sử. Muốn dọn phải sao lưu và xác nhận đúng database trước. Không chia sẻ `.bak`, JWT, logs, appsettings hay dữ liệu cá nhân lên repository.
