using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class UserVehicleRepository(EVCSMSContext context)
        : GenericRepository<UserVehicle>(context), IUserVehicleRepository
    {
    }
}
