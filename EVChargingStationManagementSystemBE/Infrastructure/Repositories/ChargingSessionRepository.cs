using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class ChargingSessionRepository(EVCSMSContext context) : GenericRepository<ChargingSession>(context), IChargingSessionRepository
    {
    }
}
