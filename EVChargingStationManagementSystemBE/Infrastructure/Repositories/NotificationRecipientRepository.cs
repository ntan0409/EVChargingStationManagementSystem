using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class NotificationRecipientRepository (EVCSMSContext context) : GenericRepository<NotificationRecipient>(context), INotificationRecipientRepository
    {
    }
}
