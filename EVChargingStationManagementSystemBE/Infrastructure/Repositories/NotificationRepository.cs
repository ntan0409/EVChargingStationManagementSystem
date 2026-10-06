using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class NotificationRepository(EVCSMSContext context) : GenericRepository<Notification>(context), INotificationRepository
    {
    }
}
