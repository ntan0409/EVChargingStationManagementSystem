# Phase 6 — VNPay Sandbox

Phạm vi triển khai là VNPAY Sandbox với database test riêng.

## Kiểm thử VNPAY Sandbox ngày 03/11/2026

- Portal SIT báo cập nhật IPN thành công cho terminal 0OKXR8XD.
- Callback IPN công khai qua HTTPS trả RspCode 97 cho yêu cầu thiếu chữ ký.
- Đơn test 24.750 VND tạo qua API trên SQL LocalDB tạm. VNPAY mở checkout Test và chuyển trình duyệt về Return URL.
- Harness đọc trạng thái Payment từ API và ghi nhận Successed. Tiến trình thoát mã 0 rồi xóa database tạm.
- URL đăng ký trên SIT là Quick Tunnel của phiên kiểm thử. Cần chạy lại bộ nhận callback và cập nhật IPN nếu tạo tunnel mới. Chưa kiểm thử các ca hủy, lỗi hoặc hết hạn qua VNPAY trong phiên này.

## Cấu hình chạy bản Sandbox

Backend chỉ cung cấp phương thức VNPAY khi cấu hình đủ các khóa sau trên môi trường test.

| Khóa | Giá trị |
| --- | --- |
| VnPay__Enabled | true |
| VnPay__Mode | Sandbox |
| VnPay__PaymentUrl | https://sandbox.vnpayment.vn/paymentv2/vpcpay.html |
| VnPay__TmnCode | Mã terminal Sandbox |
| VnPay__HashSecret | Khóa ký từ kho bí mật backend |
| VnPay__ReturnUrl | HTTPS công khai của backend test, đường dẫn /api/Payment/vnpay/return |
| VnPay__IpnUrl | HTTPS công khai của backend test, đường dẫn /api/Payment/vnpay/ipn |

Đăng ký cùng IPN URL trên VNPAY SIT. Dùng database test riêng. Chế độ test nhanh trong harness nhận HTTPS origin của Quick Tunnel chuyển tiếp đến cổng 5398. Từ thư mục backend, chạy lệnh bên dưới với origin mới.

```powershell
dotnet run -c Release --project ../EVChargingStationManagementSystemMobile/audit/phase5_api_integration/Phase5Integration.csproj -- https://YOUR-TUNNEL.trycloudflare.com
```

Payment mới được gắn phương thức VNPaySandbox để callback của Sandbox chỉ xử lý đơn test tương ứng. Trạng thái của các Payment đã có vẫn đọc được. Đơn Sandbox tạo từ bản kiểm thử cũ cần được tạo lại khi kiểm tra với bản này.

Bản triển khai cập nhật đã chạy trên LocalDB tạm với IPN đã đăng ký trong SIT. Backend tạo đơn Sandbox mới, IPN HTTPS từ chối yêu cầu thiếu chữ ký và Return URL phản hồi. Giao dịch thành công đã được xác minh trong lần chạy SIT trước đó. Đơn tạo từ bản cập nhật đang chờ thanh toán. Hồi quy sau cập nhật đạt 167 kiểm tra backend/SQL/HMAC và 244 test Flutter.

## Xác nhận trên bản cập nhật

Đơn Sandbox 24.750 VND đã hoàn tất và API trả trạng thái Payment Successed. Harness xóa database tạm sau khi đọc kết quả. Truy vấn đối chiếu ledger độc lập bị lỗi cú pháp nên chưa có kết quả đối chiếu SQL cho đơn này. Harness đã được bổ sung kiểm tra đúng một ledger Completed, cùng số tiền và phiên sạc Paid trước khi dọn database. Build của harness đã PASS, kiểm tra ledger mới cần một lượt thanh toán Sandbox tiếp theo.
