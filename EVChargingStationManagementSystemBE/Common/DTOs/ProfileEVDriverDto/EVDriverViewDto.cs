using System;
using System.Collections.Generic;

namespace Common.DTOs.ProfileEVDriverDto
{
    public class EVDriverViewDto
    {
        public Guid Id { get; set; }
        public Guid AccountId { get; set; }
        public Guid? RankingId { get; set; }
        public string? RankingName { get; set; }

        public int Score { get; set; }
        public string Status { get; set; } = "Active";
        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Từ UserAccount
        public string? Name { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public string? ProfilePictureUrl { get; set; }

        // Danh sách xe
        public List<Guid> VehicleModelIds { get; set; } = new();
    }
}
