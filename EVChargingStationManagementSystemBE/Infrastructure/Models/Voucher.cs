using System.ComponentModel.DataAnnotations;

namespace Infrastructure.Models
{
    public class Voucher
    {
        [Key]
        public Guid Id { get; set; }
        [Required, MaxLength(100)]
        public string Name { get; set; }
        //  Tên của voucher (ví dụ: “Giảm 10% phí thuê xe”, “Tặng 1 tháng miễn phí”).

        [MaxLength(255)]
        public string Description { get; set; }
        //  Mô tả chi tiết về voucher (điều kiện sử dụng, phạm vi áp dụng, v.v.).

        [Required]
        public int RequiredPoints { get; set; }
        //  Số điểm cần thiết để người dùng quy đổi được voucher này (liên quan đến điểm thưởng trong EVDriverProfile).

        [Required]
        public decimal Value { get; set; }
        //  Giá trị thực tế của voucher (ví dụ: 10.00 = giảm 10%, hoặc 100000 = giảm 100,000 VND).

        [Required, MaxLength(50)]
        public string VoucherType { get; set; }
        //  Loại voucher — giúp hệ thống xác định cách áp dụng, ví dụ:
        // “Discount” (giảm giá), “FreeMonth” (tháng miễn phí), “Cashback” (hoàn tiền), ...

        public DateTime ValidFrom { get; set; }
        public DateTime ValidTo { get; set; }
        //  Thời gian hiệu lực của voucher. 
        // Hệ thống chỉ cho phép sử dụng voucher nếu nằm trong khoảng thời gian này.

        public bool IsActive { get; set; } = true;
        //  Trạng thái voucher (Active = còn hiệu lực, false = đã hết hạn hoặc bị vô hiệu hóa).

        public ICollection<UserVoucher> UserVouchers { get; set; } = [];
        //  Quan hệ 1–n (Voucher – UserVoucher)
        // Một voucher có thể được nhiều người dùng quy đổi (UserVoucher là bảng trung gian).
    }
}
