using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileEVDriverDto
{
    public class EVDriverUpdateSelfDto
    {
        [Required(ErrorMessage = "DriverId là bắt buộc")]
        public Guid DriverId { get; set; }

        public string? Name { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public string? ProfilePictureUrl { get; set; }

        public List<Guid>? VehicleModelIds { get; set; }
    }
}
