using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class SCStaffRepository(EVCSMSContext context) : GenericRepository<SCStaffProfile>(context), ISCStaffRepository
    {
    }
}
