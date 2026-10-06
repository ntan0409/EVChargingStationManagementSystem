using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface INotificationRecipientService
    {
        Task<IServiceResult> GetUserNotificationsAsync(Guid userId, int page, int pageSize);
        Task<IServiceResult> GetUnreadCountAsync(Guid userId);
        Task<IServiceResult> MarkAsReadAsync(Guid notificationId, Guid userId);
        Task<IServiceResult> MarkAllAsReadAsync(Guid userId);
        Task<IServiceResult> GetNotificationByIdAsync(Guid notificationId, Guid userId);
    }
}
