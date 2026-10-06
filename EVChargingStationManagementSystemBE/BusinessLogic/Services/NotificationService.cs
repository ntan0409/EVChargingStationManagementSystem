using BusinessLogic.IServices;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;

namespace BusinessLogic.Services
{
    public class NotificationService(IUnitOfWork unitOfWork) : INotificationService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<Notification> NotifyStaffOffLinePaymentRecord(
        Guid recipientId, Guid senderId, string content)
        {
            var title = "Đã có người dùng chọn phương thức thanh toán offline";

            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                NotificationCode = $"NOTI-{DateTime.Now:yyyyMMddHHmmss}-{Guid.NewGuid().ToString()[..8]}",
                Title = title,
                Message = content,
                Type = "OffLinePayment",
                CreatedAt = DateTime.Now
            };

            if (senderId != Guid.Empty)
                notification.CreatedBy = senderId;

            await _unitOfWork.NotificationRepository.CreateAsync(notification);

            var recipient = new NotificationRecipient
            {
                Id = Guid.NewGuid(),
                NotificationId = notification.Id,
                RecipientId = recipientId,
                IsRead = false,
                ReadAt = null
            };

            await _unitOfWork.NotificationRecipientRepository.CreateAsync(recipient);

            return notification;
        }

        // Thông báo cho staff khi admin thay đổi profile của staff

        // 
    }
}
