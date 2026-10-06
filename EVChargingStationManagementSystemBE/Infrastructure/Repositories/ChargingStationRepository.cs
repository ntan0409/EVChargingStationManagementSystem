using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class ChargingStationRepository(EVCSMSContext context) : GenericRepository<ChargingStation>(context), IChargingStationRepository
    {
    }
}
