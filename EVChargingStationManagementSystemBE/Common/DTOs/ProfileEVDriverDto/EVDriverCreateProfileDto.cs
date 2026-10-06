using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileEVDriverDto
{
    public class EVDriverCreateProfileDto
    {
        [Required(ErrorMessage = "AccountId là bắt buộc")]
        public Guid AccountId { get; set; }

        public Guid? RankingId { get; set; }

        public List<Guid>? VehicleModelIds { get; set; }

        public int Score { get; set; } = 0;

        public string Status { get; set; } = "Active";
    }
}
