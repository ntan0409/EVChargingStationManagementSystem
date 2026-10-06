using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class ConnectorRepository(EVCSMSContext context) : GenericRepository<Connector>(context), IConnectorRepository
    {
    }
}
