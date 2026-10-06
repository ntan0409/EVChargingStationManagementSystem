using BusinessLogic.IServices;
using Common;
using Common.Helper;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationController(INotificationRecipientService notificationRecipientService) : ControllerBase
    {
        private readonly INotificationRecipientService _service = notificationRecipientService;


        [HttpGet]
        public async Task<IActionResult> GetUserNotifications([FromQuery] int page = 1,[FromQuery] int pageSize = 10)
        {
            try
            {
                Guid userId = User.GetUserId();
                var result = await _service.GetUserNotificationsAsync(userId, page, pageSize);

                if (result.Status == Const.SUCCESS_READ_CODE)
                    return Ok(result.Data);

                if (result.Status == Const.WARNING_NO_DATA_CODE)
                    return NotFound(result.Message);

                return StatusCode(500, result.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi hệ thống: " + ex.Message);
            }
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            try
            {
                Guid userId = User.GetUserId();
                var result = await _service.GetUnreadCountAsync(userId);

                if (result.Status == Const.SUCCESS_READ_CODE)
                    return Ok(new { count = result.Data });

                return StatusCode(500, result.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi hệ thống: " + ex.Message);
            }
        }

        [HttpPatch("{notificationId}/read")]
        public async Task<IActionResult> MarkAsRead(Guid notificationId)
        {
            try
            {
                Guid userId = User.GetUserId();
                var result = await _service.MarkAsReadAsync(notificationId, userId);

                if (result.Status == Const.SUCCESS_UPDATE_CODE)
                    return Ok(result.Message);

                if (result.Status == Const.WARNING_NO_DATA_CODE)
                    return NotFound(result.Message);

                return StatusCode(500, result.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi hệ thống: " + ex.Message);
            }
        }

        [HttpPatch("mark-all-read")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            try
            {
                Guid userId = User.GetUserId();
                var result = await _service.MarkAllAsReadAsync(userId);

                if (result.Status == Const.SUCCESS_UPDATE_CODE)
                    return Ok(result.Message);

                return StatusCode(500, result.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi hệ thống: " + ex.Message);
            }
        }

        [HttpGet("{notificationId}")]
        public async Task<IActionResult> GetNotificationById(Guid notificationId)
        {
            try
            {
                Guid userId = User.GetUserId();
                var result = await _service.GetNotificationByIdAsync(notificationId, userId);

                if (result.Status == Const.SUCCESS_READ_CODE)
                    return Ok(result.Data);

                if (result.Status == Const.WARNING_NO_DATA_CODE)
                    return NotFound(result.Message);

                return StatusCode(500, result.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi hệ thống: " + ex.Message);
            }
        }
    }
}
