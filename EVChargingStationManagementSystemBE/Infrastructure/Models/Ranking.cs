#nullable disable

using System.ComponentModel.DataAnnotations;

namespace Infrastructure.Models
{
    public class Ranking
    {
        [Key]
        public Guid Id { get; set; }

        [Required, MaxLength(100)]
        public string RankName { get; set; }
        public int DiscountPercentage { get; set; }
        public string Description { get; set; }
        public int MinPoints { get; set; }

        public ICollection<EVDriverProfile> EVDrivers { get; set; } = [];
    }
}