using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.NotificationDto;
using Infrastructure.IUnitOfWork;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class NotificationRecipientService(IUnitOfWork unitOfWork) : INotificationRecipientService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> GetUserNotificationsAsync(Guid userId, int page, int pageSize)
        {
            try
            {
                var query = _unitOfWork.NotificationRecipientRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(r => r.RecipientId == userId && !r.IsDeleted)
                    .Include(r => r.Notification)
                    .OrderByDescending(r => r.Notification.CreatedAt);

                var totalCount = await query.CountAsync();

                var notifications = await query
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ProjectToType<NotificationDto>()
                    .ToListAsync();

                var payload = new
                {
                    Data = notifications,
                    TotalCount = totalCount,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
                };

                return new ServiceResult(
                    Const.SUCCESS_READ_CODE,
                    Const.SUCCESS_READ_MSG,
                    payload
                );
            }
            catch (Exception ex)
            {
                return new ServiceResult(
                    Const.ERROR_EXCEPTION,
                    "Lỗi hệ thống: " + ex.Message
                );
            }
        }

        public async Task<IServiceResult> GetUnreadCountAsync(Guid userId)
        {
            try
            {
                var count = await _unitOfWork.NotificationRecipientRepository.GetQueryable()
                    .Where(r => r.RecipientId == userId && !r.IsDeleted && (r.IsRead == null || r.IsRead == false))
                    .CountAsync();

                return new ServiceResult(
                    Const.SUCCESS_READ_CODE,
                    Const.SUCCESS_READ_MSG,
                    count);
            }
            catch (Exception ex)
            {
                return new ServiceResult(
                    Const.ERROR_EXCEPTION,
                    "Lỗi hệ thống: " + ex.Message
                );
            }
        }

        public async Task<IServiceResult> MarkAsReadAsync(Guid notificationId, Guid userId)
        {
            try
            {
                var recipient = await _unitOfWork.NotificationRecipientRepository.GetQueryable()
                    .FirstOrDefaultAsync(r => r.NotificationId == notificationId && r.RecipientId == userId && !r.IsDeleted);

                if (recipient == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy thông báo.");

                recipient.IsRead = true;
                recipient.ReadAt = DateTime.Now;


                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(
                    Const.SUCCESS_UPDATE_CODE,
                    "Đã đánh dấu thông báo đã đọc."
                );
            }
            catch (Exception ex)
            {
                return new ServiceResult(
                    Const.ERROR_EXCEPTION,
                    "Lỗi hệ thống: " + ex.Message
                );
            }
        }

        public async Task<IServiceResult> MarkAllAsReadAsync(Guid userId)
        {
            try
            {
                var unreadRecipients = await _unitOfWork.NotificationRecipientRepository.GetQueryable()
                    .Where(r => r.RecipientId == userId && !r.IsDeleted && (r.IsRead == null || r.IsRead == false))
                    .ToListAsync();

                foreach (var recipient in unreadRecipients)
                {
                    recipient.IsRead = true;
                    recipient.ReadAt = DateTime.Now;
                }

                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(
                    Const.SUCCESS_UPDATE_CODE,
                    $"Đã đánh dấu {unreadRecipients.Count} thông báo đã đọc."
                );
            }
            catch (Exception ex)
            {
                return new ServiceResult(
                    Const.ERROR_EXCEPTION,
                    "Lỗi hệ thống: " + ex.Message
                );
            }
        }

        public async Task<IServiceResult> GetNotificationByIdAsync(Guid notificationId, Guid userId)
        {
            try
            {
                var notification = await _unitOfWork.NotificationRecipientRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(r => r.NotificationId == notificationId && r.RecipientId == userId && !r.IsDeleted)
                    .Include(r => r.Notification)
                    .ProjectToType<NotificationDto>()
                    .FirstOrDefaultAsync();

                if (notification == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy thông báo.");

                return new ServiceResult(
                    Const.SUCCESS_READ_CODE,
                    Const.SUCCESS_READ_MSG,
                    notification
                );
            }
            catch (Exception ex)
            {
                return new ServiceResult(
                    Const.ERROR_EXCEPTION,
                    "Lỗi hệ thống: " + ex.Message
                );
            }
        }
    }
}
