using Infrastructure.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Data.Seed
{
    public static class ChargingPostSeed
    {
        public static List<ChargingPost> GetChargingPosts() =>
        [
            new ChargingPost
        {
            Id = Guid.Parse("99999999-9999-9999-9999-999999999999"),
            PostName = "Post A1",
            ConnectorType = "Type2",
            VehicleTypeSupported = "Car",
            MaxPowerKw = 50,
            TotalConnectors = 2,
            AvailableConnectors = 2,
            Status = "Available",
            CreatedAt = new DateTime(2025, 1, 1),
            UpdatedAt = new DateTime(2025, 1, 1),
            IsDeleted = false,
            StationId = Guid.Parse("55555555-5555-5555-5555-555555555555") // VinFast Station Hanoi
        }
        ];
    }
}