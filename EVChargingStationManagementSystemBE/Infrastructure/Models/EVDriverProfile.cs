using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class EVDriverProfile
    {
        [Key]
        public Guid Id { get; set; }
        public int Point { get; set; } = 0;
        public string Status { get; set; } = "Active";
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        //  Số lần bị auto-cancel do trễ (BR14)
        public int MissedBookingCount { get; set; } = 0;

        //  Tạm khóa quyền đặt chỗ (BR19)
        public bool IsBookingLocked { get; set; } = false;

        public bool IsDeleted { get; set; } = false;

        [ForeignKey("UserAccount")]
        public Guid AccountId { get; set; }
        public UserAccount UserAccount { get; set; }

        //[ForeignKey("Ranking")]
        //public Guid? RankingId { get; set; }
        //public Ranking Ranking { get; set; }

        public ICollection<UserVehicle> UserVehicles { get; set; } = [];
        public ICollection<UserVoucher> UserVouchers { get; set; } = [];
    }
}
