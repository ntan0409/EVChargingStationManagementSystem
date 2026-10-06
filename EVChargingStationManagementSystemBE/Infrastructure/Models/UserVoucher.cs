using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class UserVoucher
    {
        [Key]
        public Guid Id { get; set; }
        // Khóa chính cho bản ghi UserVoucher

        [ForeignKey("EVDriver")]
        public Guid EVDriverId { get; set; }
        // Id người dùng (EVDriverProfile) sở hữu voucher này

        [ForeignKey("Voucher")]
        public Guid VoucherId { get; set; }
        // Id voucher được phát/sử dụng

        [ForeignKey("Station")]
        public Guid? StationId { get; set; }
        // Id trạm sạc nơi voucher được áp dụng
        // Null nếu voucher chưa được dùng

        public DateTime AssignedDate { get; set; }
        // Ngày hệ thống phát voucher cho user (tự động phát)
        // Nếu user không chọn redeem → voucher vẫn còn trạng thái Assigned

        public DateTime? RedeemDate { get; set; }
        // Ngày user thực sự đổi voucher (click "Redeem")
        // Khi redeem → trừ điểm thưởng tương ứng

        public DateTime? UsedDate { get; set; }
        // Ngày voucher được áp dụng vào thanh toán
        // Chỉ gán khi thực sự sử dụng tại trạm sạc

        public DateTime ExpiryDate { get; set; }
        // Ngày hết hạn voucher
        // Background job có thể tự set Status = "Expired" khi quá hạn

        public string Status { get; set; } = "Assigned";
        // Trạng thái hiện tại của voucher:
        // "Assigned" → đã phát cho user nhưng chưa redeem
        // "Redeemed" → user chọn áp voucher (trừ điểm)
        // "Used" → đã áp voucher vào thanh toán
        // "Expired" → quá hạn, không còn giá trị

        public string? Note { get; set; }
        // Ghi chú thêm, ví dụ:
        // "Used during promotion", "Auto-expired", hoặc các lưu ý khác

        // --- Navigation properties ---
        public EVDriverProfile EVDriver { get; set; }
        // Liên kết ngược tới EVDriverProfile để truy xuất thông tin user

        public Voucher Voucher { get; set; }
        // Liên kết ngược tới Voucher để truy xuất chi tiết voucher

        //public ChargingStation? Station { get; set; }
        //// Liên kết ngược tới ChargingStation nếu voucher được áp dụng
        [ForeignKey("ChargingSession")]
        public Guid? SessionId { get; set; }
        public ChargingSession? Session { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        // Thời điểm bản ghi được tạo

        public DateTime UpdatedAt { get; set; } = DateTime.Now;
        // Thời điểm bản ghi được cập nhật gần nhất


    }
}
