using BusinessLogic.IServices;
using Common;
using Common.DTOs.BookingDto;
using Common.Helper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookingController : ControllerBase
    {
        private readonly IBookingService _service;

        public BookingController(IBookingService service)
        {
            _service = service;
        }

        // 1️ Tạo booking mới
        [HttpPost]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> CreateBooking([FromBody] BookingCreatedDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            Guid userId;
            try { userId = User.GetUserId(); }
            catch { return Unauthorized(new { message = "Không xác định được userId từ token." }); }

            var result = await _service.CreateBooking(dto, userId);

            if (result.Status == Const.SUCCESS_CREATE_CODE)
                return Created("", new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 2️ Lấy danh sách toàn bộ booking (Admin)
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetBookingList()
        {
            var result = await _service.GetBookingList();

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 3️ Lấy chi tiết một booking
        [HttpGet("{bookingId}")]
        [Authorize(Roles = "EVDriver,Admin")]
        public async Task<IActionResult> GetBookingDetail(Guid bookingId)
        {
            var result = await _service.GetBookingDetail(bookingId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 4️ Check-in booking (EVDriver nhập mã check-in)
        [HttpPatch("checkin")]

        public async Task<IActionResult> CheckInBooking([FromBody] BookingCheckInDto dto)
        {
           

            var result = await _service.CheckInBooking(dto);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 5️ Hoàn tất booking
        [HttpPatch("{bookingId}/complete")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> CompleteBooking(Guid bookingId)
        {
            var result = await _service.CompleteBookingAsync(bookingId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 6️Hủy booking
        [HttpPatch("{bookingId}/cancel")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> CancelBooking(Guid bookingId)
        {
            Guid userId;
            try { userId = User.GetUserId(); }
            catch { return Unauthorized(new { message = "Không xác định được userId từ token." }); }

            var result = await _service.CancelBooking(bookingId, userId);

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return NoContent();

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // 7️ Lấy danh sách booking của người dùng hiện tại
        [HttpGet("my-bookings")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> GetMyBookings()
        {
            Guid userId;
            try { userId = User.GetUserId(); }
            catch { return Unauthorized(new { message = "Không xác định được userId từ token." }); }

            var result = await _service.GetBookingList(userId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

    
        // 9️ Auto Reserve - Tự động khóa trụ trước giờ sạc 5 phút
        [HttpPost("auto-reserve-before-start")]
        [Authorize]
        public async Task<IActionResult> AutoReserveConnectorBeforeStart()
        {
            await _service.AutoReserveConnectorBeforeStart();
            return Ok(new { message = "Đã tự động khóa các trụ có booking sắp bắt đầu trong 5 phút tới." });
        }

        // 10 Auto Cancel - Tự động hủy booking hết hạn
        [HttpPost("auto-cancel-expired")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AutoCancelExpiredBookings()
        {
            await _service.AutoCancelExpiredBookings();
            return Ok(new { message = "Đã xử lý hủy các booking hết hạn." });
        }

        // 11 Auto Reassign - Chuyển booking khỏi trạm lỗi
        //[HttpPost("auto-reassign-error-stations")]
        //[Authorize(Roles = "Admin")]
        //public async Task<IActionResult> AutoReassignBookingsForErrorStations()
        //{
        //    await _service.AutoReassignBookingsForErrorStations();
        //    return Ok(new { message = "Đã xử lý chuyển các booking khỏi trạm lỗi." });
        //}
        // 8️ Lấy danh sách booking của trạm mà nhân viên đang quản lý
        [HttpGet("station-bookings")]
        [Authorize(Roles = "Staff")]
        public async Task<IActionResult> GetBookingsByStationOfStaff()
        {
            Guid staffId;
            try { staffId = User.GetUserId(); }
            catch { return Unauthorized(new { message = "Không xác định được userId từ token." }); }

            var result = await _service.GetBookingsByStaff(staffId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }


        // 1️2 Auto Lock - Khóa tài khoản có nhiều no-show
        [HttpPost("lock-no-show-accounts")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> LockAccountsWithTooManyNoShows()
        {
            await _service.LockAccountsWithTooManyNoShows();
            return Ok(new { message = "Đã khóa các tài khoản có quá nhiều lượt không đến." });
        }
    }
}
