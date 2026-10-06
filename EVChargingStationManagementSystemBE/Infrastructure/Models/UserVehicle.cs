using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Models
{
    [PrimaryKey(nameof(DriverId), nameof(VehicleModelId))]
    public class UserVehicle
    {
        public Guid DriverId { get; set; }
        public EVDriverProfile EVDriver { get; set; }
        public Guid VehicleModelId { get; set; }
        public VehicleModel VehicleModel { get; set; }
        public ICollection<ChargingSession> ChargingSessions { get; set; } = [];
    }
}
