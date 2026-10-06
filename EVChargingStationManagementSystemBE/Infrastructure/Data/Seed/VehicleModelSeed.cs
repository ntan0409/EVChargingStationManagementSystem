using Infrastructure.Models;
using Microsoft.AspNetCore.Identity;

namespace Infrastructure.Data.Seed
{
    public static class VehicleModelSeed
    {
        public static List<VehicleModel> GetVehicleModels() =>
        [
                new (){
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    ModelName = "VF8",
                    Brand = "VinFast",
                    VehicleType = "Car",
                    Status = "Active",
                    ImageUrl = "string",
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                }
        ];
    }
}
