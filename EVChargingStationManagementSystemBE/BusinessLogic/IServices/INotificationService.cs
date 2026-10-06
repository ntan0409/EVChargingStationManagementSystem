using Infrastructure.Models;

namespace BusinessLogic.IServices
{
    public interface INotificationService
    {
        Task<Notification> NotifyStaffOffLinePaymentRecord(Guid recipientId, Guid senderId, string content);
    }
}
