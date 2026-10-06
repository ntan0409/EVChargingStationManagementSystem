using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class VehicleModelRepository (EVCSMSContext context) : GenericRepository<VehicleModel>(context), IVehicleModelRepository
    {
    }
}
