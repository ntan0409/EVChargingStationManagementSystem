using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Connector
    {
        [Key]
        public Guid Id { get; set; }
        public string ConnectorName { get; set; } = null!;
        //public string Type { get; set; } = null!;
        //public string Standard { get; set; } = null!;
        //public int PowerOutputKW { get; set; }
        //public string PlugType { get; set; } = null!;
        //public string Voltage { get; set; } = null!;
        //public string CurrentType { get; set; } = null!;
        public bool IsPluggedIn { get; set; } = false; // true: đang gắn vào xe
        public bool IsLocked { get; set; } = false; // true: chốt cơ đang khóa
        public string Status { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
        // Navigation property
        [ForeignKey("ChargingPost")]
        public Guid ChargingPostId { get; set; }
        public ChargingPost ChargingPost { get; set; }
    }
}
