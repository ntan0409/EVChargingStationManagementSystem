using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class ChargingPostRepository(EVCSMSContext context) : GenericRepository<ChargingPost>(context), IChargingPostRepository
    {
    }
}
