using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class UserVehicleSeed
    {
        public static List<UserVehicle> GetUserVehicles() =>
        [
            new UserVehicle
            {
                DriverId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                VehicleModelId = Guid.Parse("11111111-1111-1111-1111-111111111111")
            }
        ];
    }
}
