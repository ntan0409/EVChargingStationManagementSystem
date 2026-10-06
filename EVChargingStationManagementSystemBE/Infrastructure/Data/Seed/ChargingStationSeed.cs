using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class ChargingStationSeed
    {
        public static List<ChargingStation> GetChargingStations() =>
        [
            new ChargingStation
            {
                Id = Guid.Parse("55555555-5555-5555-5555-555555555555"),
                StationName = "VinFast Station Hanoi",
                Location = "Hanoi",
                Province = "Hanoi",
                Latitude = "21.0285N",
                Longitude = "105.8542E",
                TotalBikeChargingPosts = 5,
                AvailableBikeChargingPosts = 5,
                TotalBikeConnectors = 10,
                AvailableBikeConnectors = 10,
                TotalCarChargingPosts = 3,
                AvailableCarChargingPosts = 3,
                TotalCarChargingConnectors = 6,
                AvailableCarConnectors = 6,
                Status = "Active",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                OperatorId = Guid.Parse("22222222-2222-2222-2222-222222222222")
            },
            new ChargingStation
            {
                Id = Guid.Parse("66666666-6666-6666-6666-666666666666"),
                StationName = "VinFast Station HCM",
                Location = "Ho Chi Minh City",
                Province = "HCM",
                Latitude = "10.7769N",
                Longitude = "106.7009E",
                TotalBikeChargingPosts = 0,
                AvailableBikeChargingPosts = 0,
                TotalBikeConnectors = 0,
                AvailableBikeConnectors = 0,
                TotalCarChargingPosts = 0,
                AvailableCarChargingPosts = 0,
                TotalCarChargingConnectors = 0,
                AvailableCarConnectors = 0,
                Status = "Active",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
               OperatorId = Guid.Parse("77777777-7777-7777-7777-777777777777")
            }
        ];
    }
}
