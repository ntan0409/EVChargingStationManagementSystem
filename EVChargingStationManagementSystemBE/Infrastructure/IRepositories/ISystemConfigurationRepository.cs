using Infrastructure.Base;
using Infrastructure.Models;

namespace Infrastructure.IRepositories
{
    public interface ISystemConfigurationRepository : IGenericRepository<SystemConfiguration>
    {
        bool Validate(SystemConfiguration configuration);
    }
}
