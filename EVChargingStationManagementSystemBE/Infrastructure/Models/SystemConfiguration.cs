using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class SystemConfiguration
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string Name { get; set; }

        public string Description { get; set; }
        [Precision(18, 2)]
        public decimal? MinValue { get; set; }
        [Precision(18, 2)]
        public decimal? MaxValue { get; set; }

        public string Unit { get; set; }

        //public bool IsActive { get; set; } = false;

        public DateTime EffectedDateFrom { get; set; }

        public DateTime? EffectedDateTo { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        public bool IsDeleted { get; set; }

        //public string TargetEntity { get; set; }

        //public string TargetField { get; set; }

        //public string Operator { get; set; }

        //public string ScopeType { get; set; }

        //public string Severity { get; set; }

        //public string RuleGroup { get; set; }

        public int? VersionNo { get; set; }

        [ForeignKey("UserAccount")]
        public Guid? CreatedBy { get; set; }

        [InverseProperty("SystemConfigurationsCreator")]
        public UserAccount SystemConfigurationCreatedByNavigation { get; set; }

        [ForeignKey("UserAccount")]
        public Guid? UpdatedBy { get; set; }

        [InverseProperty("SystemConfigurationsUpdater")]
        public UserAccount SystemConfigurationUpdatedByNavigation { get; set; }
    }
}
