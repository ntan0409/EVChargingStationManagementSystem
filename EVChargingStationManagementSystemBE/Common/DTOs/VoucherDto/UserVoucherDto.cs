using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common.DTOs.VoucherDto
{
    public class UserVoucherDto
    {
        public Guid Id { get; set; }
        public Guid EVDriverId { get; set; }
        public Guid VoucherId { get; set; }
        public Guid? StationId { get; set; }
        public DateTime AssignedDate { get; set; }
        public DateTime? RedeemDate { get; set; }
        public DateTime? UsedDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public string Status { get; set; }
        public string? Note { get; set; }

        // Thông tin bổ sung để hiển thị
        public string VoucherName { get; set; }
        public decimal VoucherValue { get; set; }
        public string VoucherType { get; set; }
    }
}